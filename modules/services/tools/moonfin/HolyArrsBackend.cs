using System.Globalization;
using System.Text.Json.Nodes;
using System.Text.RegularExpressions;

namespace Moonfin.Server.Services;

public sealed class HolyArrsBackend
{
    private readonly Func<string, string, JsonNode?, Task<JsonNode>> _call;
    private readonly Func<string, int, Task<string?>> _playable;

    public HolyArrsBackend(Func<string, string, JsonNode?, Task<JsonNode>> call,
        Func<string, int, Task<string?>> playable)
    {
        _call = call;
        _playable = playable;
    }

    public async Task<JsonNode> Handle(string method, string path,
        IReadOnlyDictionary<string, string> query, JsonNode? body)
    {
        if (method == "GET" && path == "settings/discover") return new JsonArray();
        if (method == "GET" && path == "settings/public") return new JsonObject {
            ["movie4kEnabled"] = false, ["series4kEnabled"] = false
        };
        if (method == "GET" && Regex.IsMatch(path, @"^user/\d+/quota$", RegexOptions.CultureInvariant))
            return new JsonObject { ["movie"] = new JsonObject(), ["tv"] = new JsonObject() };

        if (method == "GET" && path == "search")
        {
            var term = query.GetValueOrDefault("query", "").Trim();
            if (term.Length is < 1 or > 200) throw new ArgumentException("Search needs 1–200 characters");
            if (Page(query) > 1) return PageOf([]);
            var escaped = Uri.EscapeDataString(term);
            var moviesTask = _call("GET", "metadata/search?q=" + escaped, null);
            var showsTask = _call("GET", "shows/lookup?source=tmdb&term=" + escaped, null);
            await Task.WhenAll(moviesTask, showsTask);
            var results = new List<JsonNode>();
            foreach (var (response, key, kind) in new[] {
                (moviesTask.Result, "movies", "movie"), (showsTask.Result, "shows", "show") })
                foreach (var item in Items(response[key]))
                    if (Id(item) > 0) results.Add(await Item(item, kind));
            return PageOf(results);
        }

        if (method == "GET" && path.StartsWith("discover/", StringComparison.Ordinal))
        {
            var (row, kind) = path switch
            {
                "discover/trending" => ("trending", ""),
                "discover/movies" => ("popular", "movie"),
                "discover/tv" => ("popular", "show"),
                "discover/movies/top" => ("best", "movie"),
                "discover/tv/top" => ("best", "show"),
                "discover/movies/upcoming" => ("upcoming", "movie"),
                "discover/tv/upcoming" => ("upcoming", "show"),
                _ => throw new NotSupportedException("This discovery operation is not supported by HolyArrs")
            };
            if (Page(query) > 1) return PageOf([]);
            var response = await _call("GET", $"discover?row={row}&kind={kind}", null);
            var results = new List<JsonNode>();
            foreach (var item in Items(response["items"]))
                if (Id(item) > 0) results.Add(await Item(item, Text(item, "kind", kind)));
            return PageOf(results);
        }

        var details = Regex.Match(path, @"^(movie|tv)/(\d+)$", RegexOptions.CultureInvariant);
        if (method == "GET" && details.Success)
        {
            var kind = details.Groups[1].Value == "tv" ? "show" : "movie";
            var id = PositiveId(details.Groups[2].Value);
            var response = await _call("GET", $"metadata/{kind}/{id}", null);
            var result = await Item(response, kind);
            result["runtime"] = Clone(response["runtime_minutes"]);
            result["status"] = Clone(response["status"]);
            result["tagline"] = Clone(response["tagline"]);
            result["contentRating"] = Clone(response["rating"]);
            result["voteAverage"] = Clone(response["score"]);
            result["voteCount"] = Clone(response["votes"]);
            result["genres"] = new JsonArray();
            result["seasons"] = new JsonArray(Items(response["seasons"]).Select(s =>
                (JsonNode)new JsonObject {
                    ["id"] = Clone(s["number"]), ["seasonNumber"] = Clone(s["number"]),
                    ["episodeCount"] = Clone(s["episode_count"]),
                    ["name"] = "Season " + Text(s, "number")
                }).ToArray());
            result["numberOfSeasons"] = Items(response["seasons"]).Count();
            return result;
        }

        if (method == "POST" && path == "request")
        {
            var kind = Text(body, "mediaType") switch {
                "movie" => "movie", "tv" => "show",
                _ => throw new ArgumentException("mediaType must be movie or tv")
            };
            var id = PositiveId(Text(body, "mediaId"));
            var seasons = new JsonArray();
            if (body?["seasons"] is JsonArray numbers)
            {
                if (kind != "show" || numbers.Count > 100) throw new ArgumentException("Invalid seasons");
                foreach (var number in numbers)
                {
                    if (number is null || !int.TryParse(number.ToString(), out var n) || n < 0)
                        throw new ArgumentException("Seasons must be nonnegative integers");
                    if (!seasons.Any(s => s!.GetValue<int>() == n)) seasons.Add(n);
                }
            }
            else if (body?["seasons"] is not null && Text(body, "seasons") != "all")
                throw new ArgumentException("Seasons must be all or an array");
            var request = new JsonObject {
                ["id"] = "tmdb:" + id, ["kind"] = kind, ["seasons"] = seasons,
                ["four_k"] = body?["is4k"]?.GetValue<bool>() ?? false
            };
            var response = await _call("POST", "asks", request);
            return await Request(response["ask"] ?? response);
        }

        if (method == "GET" && path == "request/count")
        {
            var response = await _call("GET", "asks", null);
            var requests = new List<JsonNode>();
            foreach (var ask in Items(response["asks"]))
                if (Text(ask, "kind") is "movie" or "show") requests.Add(await Request(ask));
            return new JsonObject {
                ["total"] = requests.Count,
                ["movie"] = requests.Count(r => Text(r, "type") == "movie"),
                ["tv"] = requests.Count(r => Text(r, "type") == "tv"),
                ["pending"] = requests.Count(r => Text(r, "status") == "1"),
                ["approved"] = requests.Count(r => Text(r, "status") == "2"),
                ["processing"] = requests.Count(r => Text(r, "status") == "2"),
                ["declined"] = requests.Count(r => Text(r, "status") == "3"),
                ["available"] = requests.Count(r => Text(r, "status") == "5"),
                ["completed"] = requests.Count(r => Text(r, "status") == "5")
            };
        }

        if (method == "GET" && path == "request")
        {
            var response = await _call("GET", "asks", null);
            var results = new List<JsonNode>();
            foreach (var ask in Items(response["asks"]))
                if (Text(ask, "kind") is "movie" or "show") results.Add(await Request(ask));
            var skip = Number(query.GetValueOrDefault("skip", "0"), 0, 100000);
            var take = Number(query.GetValueOrDefault("take", "20"), 1, 100);
            return new JsonObject {
                ["pageInfo"] = new JsonObject { ["pages"] = (results.Count + take - 1) / take,
                    ["pageSize"] = take, ["results"] = results.Count, ["page"] = skip / take + 1 },
                ["results"] = new JsonArray(results.Skip(skip).Take(take).ToArray())
            };
        }

        var singleRequest = Regex.Match(path, @"^request/(\d+)$", RegexOptions.CultureInvariant);
        if (method == "GET" && singleRequest.Success)
        {
            var response = await _call("GET", "asks/" + PositiveId(singleRequest.Groups[1].Value), null);
            if (Text(response, "kind") is not ("movie" or "show"))
                throw new NotSupportedException("Only video requests are exposed to Moonfin");
            return await Request(response);
        }

        throw new NotSupportedException("This operation is not supported by the HolyArrs backend");
    }

    private async Task<JsonObject> Item(JsonNode item, string kind)
    {
        var id = Id(item);
        return new JsonObject {
            ["id"] = id, ["mediaType"] = kind == "show" ? "tv" : "movie",
            ["title"] = Text(item, "name"), ["name"] = Text(item, "name"),
            ["overview"] = Clone(item["overview"]), ["posterPath"] = Clone(item["poster"]),
            ["backdropPath"] = Clone(item["backdrop"]), ["originalLanguage"] = Clone(item["original_language"]),
            ["releaseDate"] = Clone(item["dates"]?["theaters"] ?? item["cinema_date"]),
            ["firstAirDate"] = Clone(item["dates"]?["first_air"]),
            ["mediaInfo"] = await Media(item, kind, id)
        };
    }

    private async Task<JsonObject> Media(JsonNode item, string kind, int id)
    {
        var playable = await _playable(kind, id);
        var state = Text(item["ask"] ?? item, "state");
        var status = playable != null ? (kind == "show" ? 4 : 5)
            : state == "asked" ? 2 : state is "approved" or "available" ? 3 : 1;
        return new JsonObject {
            ["id"] = id, ["tmdbId"] = id, ["mediaType"] = kind == "show" ? "tv" : "movie",
            ["status"] = status, ["status4k"] = 1, ["ratingKey"] = playable,
            ["title"] = Clone(item["name"]), ["name"] = Clone(item["name"]),
            ["posterPath"] = Clone(item["poster"])
        };
    }

    private async Task<JsonObject> Request(JsonNode ask)
    {
        var media = await Media(ask, Text(ask, "kind"), Id(ask));
        var status = Text(ask, "state") switch {
            "asked" => 1, "turned_down" => 3,
            "available" when media["ratingKey"] != null => 5,
            _ => 2
        };
        return new JsonObject {
            ["id"] = Clone(ask["id"]), ["status"] = status,
            ["type"] = Text(ask, "kind") == "show" ? "tv" : "movie",
            ["is4k"] = Clone(ask["four_k"]) ?? JsonValue.Create(false),
            ["createdAt"] = Clone(ask["asked_at"]), ["media"] = media,
            ["seasons"] = new JsonArray(Items(ask["seasons"]).Select(s =>
                (JsonNode)new JsonObject { ["id"] = Clone(s), ["seasonNumber"] = Clone(s), ["status"] = status }).ToArray())
        };
    }

    private static JsonObject PageOf(IEnumerable<JsonNode> items)
    {
        var results = items.ToArray();
        return new JsonObject { ["page"] = 1, ["totalPages"] = results.Length == 0 ? 0 : 1,
            ["totalResults"] = results.Length, ["results"] = new JsonArray(results) };
    }

    private static int Page(IReadOnlyDictionary<string, string> query) =>
        Number(query.GetValueOrDefault("page", "1"), 1, 100000);
    private static int Number(string value, int min, int max) =>
        int.TryParse(value, NumberStyles.None, CultureInfo.InvariantCulture, out var n) && n >= min && n <= max
            ? n : throw new ArgumentException("Invalid numeric parameter");
    private static int PositiveId(string value) => Number(value, 1, int.MaxValue);
    private static int Id(JsonNode item) =>
        int.TryParse(Text(item, "tmdb_id", Text(item["ids"], "tmdb")), out var id) ? id : 0;
    private static string Text(JsonNode? node, string key, string fallback = "") => node?[key]?.ToString() ?? fallback;
    private static JsonNode? Clone(JsonNode? node) => node?.DeepClone();
    private static IEnumerable<JsonNode> Items(JsonNode? node) => node is JsonArray array
        ? array.Where(n => n != null).Select(n => n!) : Enumerable.Empty<JsonNode>();
}
