using System.Net;
using System.Text;
using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Mvc;
using Moonfin.Server.Api;

namespace Moonfin.Server.Services;

public static class HolyArrsIntegration
{
    public static bool Enabled => !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("MOONFIN_HOLYARRS_KEY_FILE"));

    private static readonly HttpClient Http = new(new HttpClientHandler {
        UseProxy = false, AllowAutoRedirect = false
    }) { Timeout = TimeSpan.FromSeconds(30) };

    public static async Task<IActionResult> Handle(ControllerBase controller, string operation, string? path = null)
    {
        var cancellation = controller.HttpContext.RequestAborted;
        try
        {
            var userId = controller.GetUserIdFromClaims();
            if (userId == null) return Error(401, "Jellyfin authentication is required");
            var authorization = controller.Request.Headers.Authorization.ToString();
            var token = controller.Request.Headers["X-Emby-Token"].ToString();
            async Task<JsonNode> Jellyfin(string route)
            {
                using var request = new HttpRequestMessage(HttpMethod.Get, "http://127.0.0.1:8096/" + route);
                if (!string.IsNullOrEmpty(authorization)) request.Headers.TryAddWithoutValidation("Authorization", authorization);
                if (!string.IsNullOrEmpty(token)) request.Headers.TryAddWithoutValidation("X-Emby-Token", token);
                using var response = await Http.SendAsync(request, cancellation);
                if (!response.IsSuccessStatusCode) throw new UnauthorizedAccessException();
                return JsonNode.Parse(await response.Content.ReadAsStringAsync(cancellation))!;
            }

            var user = await Jellyfin("Users/Me");
            if (!Guid.TryParse(user["Id"]?.ToString(), out var actualUser) || actualUser != userId.Value)
                return Error(401, "Jellyfin session identity mismatch");
            var policy = user["Policy"];
            if (policy is null || policy["IsDisabled"]?.GetValue<bool>() != false
                || policy["MaxParentalRating"] != null
                || policy["EnableAllFolders"]?.GetValue<bool>() != true
                || Nonempty(policy["BlockedTags"]) || Nonempty(policy["AllowedTags"])
                || Nonempty(policy["BlockUnratedItems"]))
                return Error(403, "HolyArrs discovery is not enabled for restricted Jellyfin accounts");

            var userNumber = (int)(BitConverter.ToUInt32(actualUser.ToByteArray(), 0) & 0x7fffffff);
            if (userNumber == 0) userNumber = 1;
            const int permissions = 32 | 16384 | 262144 | 524288;
            var publicUser = new JsonObject {
                ["id"] = userNumber, ["displayName"] = user["Name"]?.ToString(), ["permissions"] = permissions
            };
            var now = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
            if (operation == "status") return Json(new JsonObject {
                ["enabled"] = true, ["authenticated"] = true, ["seerrUserId"] = userNumber,
                ["displayName"] = user["Name"]?.ToString(), ["permissions"] = permissions,
                ["sessionCreated"] = now, ["lastValidated"] = now,
                ["url"] = "/Moonfin/Seerr"
            });
            if (operation == "login") return Json(new JsonObject {
                ["success"] = true, ["seerrUserId"] = userNumber,
                ["displayName"] = user["Name"]?.ToString(), ["permissions"] = permissions
            });
            if (operation == "validate") return Json(new JsonObject { ["valid"] = true, ["lastValidated"] = now });
            if (operation == "logout") return Json(new JsonObject { ["success"] = true });
            if (operation != "api" || path is null) return Error(404, "Unknown operation");
            if (controller.Request.Method == "GET" && path == "auth/me") return Json(publicUser);

            async Task<JsonNode> Call(string method, string route, JsonNode? body)
            {
                var file = Environment.GetEnvironmentVariable("MOONFIN_HOLYARRS_KEY_FILE")!;
                var credential = JsonNode.Parse(await File.ReadAllTextAsync(file, cancellation));
                var key = credential?["key"]?.GetValue<string>();
                if (string.IsNullOrWhiteSpace(key)) throw new IOException("Missing HolyArrs credential");
                using var request = new HttpRequestMessage(new HttpMethod(method), "http://127.0.0.1:6263/api/v1/" + route);
                request.Headers.Add("X-Api-Key", key);
                if (body != null) request.Content = new StringContent(body.ToJsonString(), Encoding.UTF8, "application/json");
                using var response = await Http.SendAsync(request, cancellation);
                if (!response.IsSuccessStatusCode)
                    throw new HttpRequestException("HolyArrs request failed", null, response.StatusCode);
                return JsonNode.Parse(await response.Content.ReadAsStringAsync(cancellation))!;
            }

            var library = new Dictionary<string, List<JsonNode>>();
            async Task<string?> Playable(string kind, int id)
            {
                var type = kind == "show" ? "Series" : "Movie";
                if (!library.TryGetValue(kind, out var items))
                {
                    items = new List<JsonNode>();
                    for (var start = 0; ; start += 250)
                    {
                        var result = await Jellyfin($"Items?UserId={actualUser:N}&Recursive=true&IncludeItemTypes={type}&HasTmdbId=true&Fields=Path,ProviderIds&Limit=250&StartIndex={start}");
                        if (result["Items"] is not JsonArray page) break;
                        items.AddRange(page.Where(item => item != null).Select(item => item!));
                        if (page.Count < 250) break;
                    }
                    library[kind] = items;
                }
                foreach (var item in items)
                {
                    if (item?["ProviderIds"] is not JsonObject providers
                        || !providers.Any(provider => string.Equals(provider.Key, "Tmdb", StringComparison.OrdinalIgnoreCase)
                            && provider.Value?.ToString() == id.ToString())) continue;
                    var itemId = item?["Id"]?.ToString();
                    if (!Guid.TryParse(itemId, out var parsed)) continue;
                    if (kind == "show")
                    {
                        var episodes = await Jellyfin($"Items?UserId={actualUser:N}&Recursive=true&ParentId={parsed:N}&IncludeItemTypes=Episode&Fields=Path&Limit=1");
                        if (episodes["Items"] is JsonArray available && available.Count > 0
                            && Readable(available[0]?["Path"]?.ToString())) return itemId;
                    }
                    else if (Readable(item?["Path"]?.ToString())) return itemId;
                }
                return null;
            }

            if (controller.Request.ContentLength > 32768) return Error(413, "Request is too large");
            JsonNode? input = null;
            if (controller.Request.Method is "POST" or "PUT")
            {
                using var reader = new StreamReader(controller.Request.Body);
                var content = new char[32769];
                var length = await reader.ReadBlockAsync(content, cancellation);
                if (length > 32768) return Error(413, "Request is too large");
                if (length > 0) input = JsonNode.Parse(new string(content, 0, length));
            }
            var backend = new HolyArrsBackend(Call, Playable);
            var query = controller.Request.Query.ToDictionary(q => q.Key, q => q.Value.ToString());
            return Json(await backend.Handle(controller.Request.Method, path, query, input));
        }
        catch (UnauthorizedAccessException) { return Error(401, "Jellyfin session is not valid"); }
        catch (NotSupportedException) { return Error(501, "This operation is not supported by HolyArrs"); }
        catch (ArgumentException) { return Error(400, "Invalid request parameters"); }
        catch (System.Text.Json.JsonException) { return Error(400, "Invalid JSON request"); }
        catch (HttpRequestException error) {
            return Error(error.StatusCode == HttpStatusCode.Conflict ? 409 : 502, "HolyArrs could not complete this request");
        }
        catch (IOException) { return Error(503, "HolyArrs integration is not ready"); }
        catch (OperationCanceledException) { return Error(504, "Upstream request timed out"); }
    }

    private static bool Nonempty(JsonNode? node) => node is JsonArray items && items.Count > 0;
    private static bool Readable(string? path)
    {
        if (string.IsNullOrEmpty(path)) return false;
        try { using var file = File.OpenRead(path); return file.Length > 0; }
        catch (IOException) { return false; }
        catch (UnauthorizedAccessException) { return false; }
    }
    private static ContentResult Json(JsonNode value) => new() {
        StatusCode = 200, ContentType = "application/json", Content = value.ToJsonString()
    };
    private static ObjectResult Error(int status, string message) => new(new { message }) { StatusCode = status };
}
