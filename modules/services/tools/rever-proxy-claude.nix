{ ... }:

{
  flake.modules.nixos.reverse-proxy-claude =
    { pkgs, ... }:

    let
      ollamaAnthropicProxy = pkgs.writers.writePython3Bin
        "ollama-anthropic-proxy"
        {
          libraries = with pkgs.python3Packages; [
            aiohttp
          ];
        }
        ''
          import json
          import logging
          import os

          from aiohttp import ClientSession, ClientTimeout, web


          logging.basicConfig(
              level=logging.INFO,
              format="%(asctime)s %(levelname)s %(message)s",
          )

          LISTEN_HOST = os.environ.get(
              "LISTEN_HOST",
              "127.0.0.1",
          )
          LISTEN_PORT = int(
              os.environ.get(
                  "LISTEN_PORT",
                  "11435",
              )
          )
          UPSTREAM = os.environ.get(
              "OLLAMA_UPSTREAM",
              "http://127.0.0.1:11434",
          ).rstrip("/")


          HOP_BY_HOP_HEADERS = {
              "connection",
              "keep-alive",
              "proxy-authenticate",
              "proxy-authorization",
              "te",
              "trailers",
              "transfer-encoding",
              "upgrade",
              "host",
              "content-length",
          }


          def filter_headers(headers):
              return {
                  key: value
                  for key, value in headers.items()
                  if key.lower() not in HOP_BY_HOP_HEADERS
              }


          def content_to_text(content):
              """
              Convert Anthropic string or text-block content
              into one plain string.
              """

              if isinstance(content, str):
                  return content

              if isinstance(content, list):
                  text_parts = []

                  for block in content:
                      if isinstance(block, str):
                          text_parts.append(block)
                          continue

                      if not isinstance(block, dict):
                          continue

                      if block.get("type") == "text":
                          text = block.get("text")

                          if isinstance(text, str):
                              text_parts.append(text)

                  return "\n\n".join(text_parts)

              return ""


          def normalize_anthropic_request(body):
              """
              Normalize Claude Code's Anthropic message format
              for Ollama's stricter Qwen renderer.

              In particular:
              - Flatten top-level system blocks into a string.
              - Move system-role messages out of messages.
              - Append those messages to the initial system prompt.
              """

              system_parts = []

              system = body.get("system")

              if isinstance(system, str):
                  if system:
                      system_parts.append(system)

              elif isinstance(system, list):
                  system_text = content_to_text(system)

                  if system_text:
                      system_parts.append(system_text)

                  logging.info(
                      "Normalized Anthropic system prompt: "
                      "%d blocks -> 1",
                      len(system),
                  )

              messages = body.get("messages", [])

              normalized_messages = []
              moved_system_messages = 0

              for message in messages:
                  if not isinstance(message, dict):
                      normalized_messages.append(message)
                      continue

                  if message.get("role") == "system":
                      text = content_to_text(
                          message.get("content")
                      )

                      if text:
                          system_parts.append(text)

                      moved_system_messages += 1
                      continue

                  normalized_messages.append(message)

              if moved_system_messages:
                  logging.warning(
                      "Moved %d system-role messages "
                      "to top-level system prompt",
                      moved_system_messages,
                  )

              body["messages"] = normalized_messages

              if system_parts:
                  body["system"] = "\n\n".join(system_parts)

              # Force thinking off for Ollama/Qwen.
              body["thinking"] = {
                  "type": "disabled",
              }

              return body


          async def proxy(request):
              upstream_url = (
                  UPSTREAM
                  + request.rel_url.path_qs
              )

              request_headers = filter_headers(
                  request.headers
              )

              data = await request.read()

              if (
                  request.method == "POST"
                  and request.path == "/v1/messages"
                  and data
              ):
                  try:
                      body = json.loads(data)

                      messages = body.get(
                          "messages",
                          [],
                      )

                      roles = [
                          message.get(
                              "role",
                              "<missing>",
                          )
                          for message in messages
                          if isinstance(message, dict)
                      ]

                      logging.info(
                          "Anthropic request model=%s "
                          "roles=%s",
                          body.get("model"),
                          roles,
                      )

                      system = body.get("system")

                      if isinstance(system, list):
                          logging.info(
                              "Received /v1/messages "
                              "model=%s "
                              "system_blocks=%d "
                              "messages=%d",
                              body.get("model"),
                              len(system),
                              len(messages),
                          )

                      body = (
                          normalize_anthropic_request(
                              body
                          )
                      )

                      normalized_roles = [
                          message.get(
                              "role",
                              "<missing>",
                          )
                          for message
                          in body.get(
                              "messages",
                              [],
                          )
                          if isinstance(message, dict)
                      ]

                      logging.info(
                          "Forwarding Anthropic "
                          "request roles=%s",
                          normalized_roles,
                      )

                      data = json.dumps(
                          body,
                          separators=(",", ":"),
                      ).encode("utf-8")

                      request_headers[
                          "Content-Type"
                      ] = "application/json"

                  except (
                      json.JSONDecodeError,
                      UnicodeDecodeError,
                  ) as exc:
                      logging.warning(
                          "Could not parse "
                          "/v1/messages body: %s",
                          exc,
                      )

              session = request.app["client"]

              try:
                  async with session.request(
                      request.method,
                      upstream_url,
                      headers=request_headers,
                      data=data if data else None,
                      allow_redirects=False,
                  ) as upstream_response:

                      response_headers = (
                          filter_headers(
                              upstream_response.headers
                          )
                      )

                      response = web.StreamResponse(
                          status=(
                              upstream_response.status
                          ),
                          reason=(
                              upstream_response.reason
                          ),
                          headers=response_headers,
                      )

                      await response.prepare(request)

                      async for chunk in (
                          upstream_response.content.iter_any()
                      ):
                          await response.write(chunk)

                      await response.write_eof()

                      return response

              except Exception:
                  logging.exception(
                      "Proxy request failed"
                  )

                  return web.json_response(
                      {
                          "error": {
                              "type": "proxy_error",
                              "message": (
                                  "Failed to contact "
                                  "Ollama upstream"
                              ),
                          }
                      },
                      status=502,
                  )


          async def create_app():
              app = web.Application(
                  client_max_size=(
                      256 * 1024 * 1024
                  ),
              )

              timeout = ClientTimeout(
                  total=None,
                  connect=30,
                  sock_connect=30,
                  sock_read=None,
              )

              app["client"] = ClientSession(
                  timeout=timeout
              )

              async def close_client(app):
                  await app["client"].close()

              app.on_cleanup.append(
                  close_client
              )

              app.router.add_route(
                  "*",
                  "/{path:.*}",
                  proxy,
              )

              return app


          web.run_app(
              create_app(),
              host=LISTEN_HOST,
              port=LISTEN_PORT,
              access_log=None,
          )
        '';
    in
    {
      systemd.services.ollama-anthropic-proxy = {
        description =
          "Ollama Anthropic API compatibility proxy";

        wantedBy = [
          "multi-user.target"
        ];

        after = [
          "network-online.target"
        ];

        wants = [
          "network-online.target"
        ];

        environment = {
          LISTEN_HOST = "127.0.0.1";
          LISTEN_PORT = "11435";

          OLLAMA_UPSTREAM =
            "https://ollama.ainative.eu";
        };

        serviceConfig = {
          Type = "simple";

          ExecStart =
            "${ollamaAnthropicProxy}/bin/"
            + "ollama-anthropic-proxy";

          Restart = "on-failure";
          RestartSec = "2s";

          DynamicUser = true;
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectHome = true;
          ProtectSystem = "strict";
        };
      };
    };
}
