using System.Text.Json.Nodes;
using Moonfin.Server.Services;

var assertions = 0;
void Check(bool condition)
{
    assertions++;
    if (!condition) throw new Exception($"Assertion {assertions} failed");
}
var calls = new List<(string Method, string Route, JsonNode? Body)>();
string? playable = null;
var native = JsonNode.Parse("""
{"id":7,"kind":"movie","tmdb_id":"550","name":"Fight Club","state":"approved","seasons":[]}
""")!;
var backend = new HolyArrsBackend((method, route, body) => {
    calls.Add((method, route, body?.DeepClone()));
    JsonNode response = route switch {
        "asks" when method == "POST" => new JsonObject { ["ask"] = native.DeepClone() },
        "asks" => new JsonObject { ["asks"] = new JsonArray(native.DeepClone()) },
        "asks/7" => native.DeepClone(),
        _ when route.StartsWith("metadata/search?") => new JsonObject {
            ["movies"] = new JsonArray(native.DeepClone()) },
        _ when route.StartsWith("shows/lookup?") => JsonNode.Parse("""
            {"shows":[{"ids":{"tmdb":"1399"},"name":"Game of Thrones","kind":"show"}]}
            """)!,
        _ when route.StartsWith("discover?") => new JsonObject {
            ["items"] = new JsonArray(native.DeepClone()) },
        _ => native.DeepClone()
    };
    return Task.FromResult(response);
}, (kind, id) => Task.FromResult(playable));
var query = new Dictionary<string, string>();
async Task<JsonNode> Get(string path) => await backend.Handle("GET", path, query, null);
var result = await Get("movie/550");
Check(result["id"]!.GetValue<int>() == 550);
Check(result["mediaInfo"]!["status"]!.GetValue<int>() == 3);
Check(result["mediaInfo"]!["ratingKey"] is null);
native["state"] = "available";
result = await Get("request/7");
Check(result["status"]!.GetValue<int>() == 2);
playable = "jellyfin-movie-id";
result = await Get("movie/550");
Check(result["mediaInfo"]!["status"]!.GetValue<int>() == 5);
Check(result["mediaInfo"]!["ratingKey"]!.ToString() == playable);
result = await Get("request/7");
Check(result["status"]!.GetValue<int>() == 5);
playable = null;
foreach (var (state, status) in new[] { ("asked", 1), ("turned_down", 3), ("approved", 2) })
{
    native["state"] = state;
    result = await Get("request/7");
    Check(result["status"]!.GetValue<int>() == status);
}
query["query"] = "A & B";
result = await Get("search");
Check(result["results"]!.AsArray().Count == 2);
Check(calls.Any(c => c.Route == "metadata/search?q=A%20%26%20B"));
Check(calls.Any(c => c.Route == "shows/lookup?source=tmdb&term=A%20%26%20B"));
Check(result["results"]![1]!["id"]!.GetValue<int>() == 1399);
query.Clear();
foreach (var route in new[] { "trending", "movies", "tv", "movies/top", "tv/top", "movies/upcoming", "tv/upcoming" })
{
    result = await Get("discover/" + route);
    Check(result["results"]!.AsArray().Count == 1);
}
query["page"] = "2";
var before = calls.Count;
Check((await Get("discover/movies"))["results"]!.AsArray().Count == 0);
Check(calls.Count == before);
query.Clear();
foreach (var seasons in new[] { "\"all\"", "[1,2,2]" })
{
    var body = JsonNode.Parse("{\"mediaId\":1399,\"mediaType\":\"tv\",\"seasons\":" + seasons + "}");
    await backend.Handle("POST", "request", query, body);
    var sent = calls.Last();
    Check(sent.Method == "POST" && sent.Route == "asks");
    Check(sent.Body!["id"]!.ToString() == "tmdb:1399");
    Check(sent.Body["kind"]!.ToString() == "show");
    Check(sent.Body["seasons"]!.AsArray().Count == (seasons == "\"all\"" ? 0 : 2));
}
foreach (var body in new[] {
    "{\"mediaId\":-1,\"mediaType\":\"movie\"}",
    "{\"mediaId\":1,\"mediaType\":\"artist\"}",
    "{\"mediaId\":1,\"mediaType\":\"tv\",\"seasons\":[-1]}",
    "{\"mediaId\":1,\"mediaType\":\"tv\",\"seasons\":\"invalid\"}" })
{
    before = calls.Count;
    try { await backend.Handle("POST", "request", query, JsonNode.Parse(body)); Check(false); }
    catch (ArgumentException) { Check(calls.Count == before); }
}
foreach (var path in new[] { "settings/radarr", "../asks", "discover/unknown", "request/7/approve" })
{
    before = calls.Count;
    try { await Get(path); Check(false); }
    catch (NotSupportedException) { Check(calls.Count == before); }
}
Check((await Get("settings/discover")).AsArray().Count == 0);
Check((await Get("settings/public"))["movie4kEnabled"]!.GetValue<bool>() == false);
Check((await Get("user/1/quota"))["movie"] is JsonObject);
result = await Get("request/count");
Check(result["total"]!.GetValue<int>() == 1);
Check(result["approved"]!.GetValue<int>() == 1);
Check(result["completed"]!.GetValue<int>() == 0);
Console.WriteLine($"Moonfin contracts: {assertions} assertions passed");
