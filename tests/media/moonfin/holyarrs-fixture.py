import json
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def do_GET(self):
        self.respond()

    def do_POST(self):
        self.respond()

    def respond(self):
        if self.headers.get("X-Api-Key") != "moonfin-fixture-secret":
            self.send_error(401)
            return
        path = self.path.split("?", 1)[0]
        item = {"tmdb_id": "550", "kind": "movie", "name": "Fixture Movie", "year": 1999}
        if path == "/api/v1/discover":
            response = {"items": [item]}
        elif path in {"/api/v1/metadata/movie/550", "/api/v1/metadata/movie/551"}:
            response = {**item, "tmdb_id": path.rsplit("/", 1)[1], "in_library": True, "ask": {"id": 1, "state": "available"}}
        elif path == "/api/v1/asks" and self.command == "POST":
            body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
            Path("/run/moonfin-request.json").write_text(json.dumps(body))
            response = {"ask": {"id": 1, "kind": body["kind"], "tmdb_id": "550", "name": "Fixture Movie", "state": "approved"}}
        else:
            self.send_error(404)
            return
        encoded = json.dumps(response).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(encoded)))
        self.end_headers()
        self.wfile.write(encoded)


HTTPServer(("127.0.0.1", 6263), Handler).serve_forever()
