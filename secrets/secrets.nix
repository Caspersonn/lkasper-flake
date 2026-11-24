let
  user1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOtpGyC5u8+T71Oo+QL9ym+hWaNSiisskL43ElmpWiEr";
  users = [ user1 ];

  system1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGsk6h6kDNUaLyDbImcxou/ZnIv65zSaaBqUXtP++poQ";
  gaming-casper = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJW8Y4D8Q6pgoZxZ2CKGcz9K7+JWUxojouVWYKObzzHt";
  system3 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH18queSvalZ6ftHYr744tRut46OeMS9Z1SsDQvugCTD";
  system4 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJRNFsCGiDVk/isN+bAfndANYjmIG7hfDD2azki93h4V";
  system5 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIALR+WREWcS6d2lf8OH59yWSLGdv3PI5R6AOGobXB8a6";
  personal-casper = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA81Jmm0LADyGRv5aURGvi8aoRCtQEjdD21AdQozqCqY";
  technative-casper = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGSkCdC46exqaT+lg99eDiav1d2i+mwPVaHcu1eUeKVZ";
  system8 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEIQfpx2MkVCOE3KPYw4kYn3DatjsoSWV99IhkeIRwTY";
  kaito   = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKFdoJda3zawJPBxuOAEWs4cTZkGc5HmHnyH6E1eL/7P";
  sakura  = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHg9YgrgN20UXWUxeCkGGTLPxzPMTsDTCtCTA6h5b2Y8";
  raspberrypi = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE+MBgCQO3KqMF20ljvce+pFhViExVD91iEiFvd4dq0h";
  systems = [ system1 gaming-casper system3 system4 system5 personal-casper technative-casper system8 raspberrypi kaito sakura ];
in
{
  "atuin-casper-session.age".publicKeys = [ user1 ];
  "atuin-casper-key.age".publicKeys = [ user1 ];
  "atuin-antonia-session.age".publicKeys = [ user1 sakura ];
  "atuin-antonia-key.age".publicKeys = [ user1 sakura ];
  "atuin-antonia-password.age".publicKeys = [ user1 ];

  "soltty-config.age".publicKeys = users ++ systems;
  "toggl-lkasper.age".publicKeys = users ++ systems;
  "spotify.age".publicKeys = users ++ systems;
  "vaultwarden.age".publicKeys = users ++ systems;
  "steam-casper.age".publicKeys = users ++ systems;
  "aws_config.age".publicKeys = users ++ systems;
  "aws_credentials.age".publicKeys = users ++ systems;
  "avante-bedrock.age".publicKeys = users ++ systems;
  "google-bedrock.age".publicKeys = users ++ systems;
  "google-engine-bedrock.age".publicKeys = users ++ systems;
  "avante-openai.age".publicKeys = users ++ systems;
  "pontifex.age".publicKeys = users ++ systems;
  "openvpn-improvement-it-login.age".publicKeys = users ++ systems;
  "wireguard-private.age".publicKeys = users ++ systems;
  "wireguard-private-sakura.age".publicKeys = users ++ systems;
  "wireguard-private-gaming-casper.age".publicKeys = users ++ systems;
  "wireguard-public.age".publicKeys = users ++ systems;
  "wireguard-server-private.age".publicKeys = users ++ systems;
  "twenty_server_environment.age".publicKeys = users ++ systems;
  "twenty_worker_environment.age".publicKeys = users ++ systems;
  "pokemon_tracker_nextauth.age".publicKeys = users ++ systems;
  "gaming-casper-signing-key.age".publicKeys = users ++ systems;
  "jiratui-config.age".publicKeys = users ++ systems;

  # HomeAssistant
  "mqtt-zigbee2mqtt-password.age".publicKeys = users ++ systems;
  "mqtt-homeassistant-password.age".publicKeys = users ++ systems;
  "zigbee2mqtt-env.age".publicKeys = users ++ systems;

  # Nextcloud
  "nextcloud-admin-passwd.age".publicKeys = users ++ systems;
  "nextcloud-casper-passwd.age".publicKeys = users ++ systems;
  "nextcloud-casper-netrc.age".publicKeys = users ++ systems;

  # Aiostreams
  "aiostreams-env.age".publicKeys = users ++ systems;

  "solidtime-env.age".publicKeys = users ++ [ kaito ];
  "solidtime-db-env.age".publicKeys = users ++ [ kaito ];

  # Linny MCP
  "linny-mcp-tokens.age".publicKeys = users ++ systems;

  # Jira MCP
  "jira-api-token.age".publicKeys = users ++ systems;
  "jira-api-token-postnl.age".publicKeys = users ++ systems;

  # OpenCode
  "opencode-go-api-key.age".publicKeys = users ++ systems;

  # Music
  "music-credentials.age".publicKeys = users ++ [ kaito ];
  "music-lastfm.age".publicKeys = users ++ [ kaito ];

  # Restic backups (add-restic-backups). Passwords: host + kaito (prunes);
  # env (REST + AWS key): host only. kaito-env = kaito-backup IAM key.
  "restic-htpasswd.age".publicKeys = users ++ [ kaito ];
  "restic-kaito-password.age".publicKeys = users ++ [ kaito ];
  "restic-kaito-env.age".publicKeys = users ++ [ kaito ];
  "restic-personal-casper-password.age".publicKeys = users ++ [ personal-casper kaito ];
  "restic-personal-casper-env.age".publicKeys = users ++ [ personal-casper ];
  "restic-gaming-casper-password.age".publicKeys = users ++ [ gaming-casper kaito ];
  "restic-gaming-casper-env.age".publicKeys = users ++ [ gaming-casper ];
  "restic-technative-casper-password.age".publicKeys = users ++ [ technative-casper kaito ];
  "restic-technative-casper-env.age".publicKeys = users ++ [ technative-casper ];
  "restic-sakura-password.age".publicKeys = users ++ [ sakura kaito ];
  "restic-sakura-env.age".publicKeys = users ++ [ sakura ];

  # Nebula
  "nebula-ca.crt.age".publicKeys = users ++ systems;
  "nebula-ca.key.age".publicKeys = users;
  "nebula-kaito.crt.age".publicKeys = users ++ systems;
  "nebula-kaito.key.age".publicKeys = users ++ systems;
  "nebula-neko.crt.age".publicKeys = users ++ systems;
  "nebula-neko.key.age".publicKeys = users ++ systems;
  "nebula-server-casper.crt.age".publicKeys = users ++ systems;
  "nebula-server-casper.key.age".publicKeys = users ++ systems;
  "nebula-gaming-casper.crt.age".publicKeys = users ++ systems;
  "nebula-gaming-casper.key.age".publicKeys = users ++ systems;
  "nebula-personal-casper.crt.age".publicKeys = users ++ systems;
  "nebula-personal-casper.key.age".publicKeys = users ++ systems;
  "nebula-technative-casper.crt.age".publicKeys = users ++ systems;
  "nebula-technative-casper.key.age".publicKeys = users ++ systems;
  "nebula-sakura.crt.age".publicKeys = users ++ systems;
  "nebula-sakura.key.age".publicKeys = users ++ systems;
  # Phone: no host needs these, only the owner to load them into Mobile Nebula
  "nebula-pixel-10a.crt.age".publicKeys = users;
  "nebula-pixel-10a.key.age".publicKeys = users;
}
