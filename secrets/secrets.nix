let
  user1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOtpGyC5u8+T71Oo+QL9ym+hWaNSiisskL43ElmpWiEr";
  users = [ user1 ];

  system1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGsk6h6kDNUaLyDbImcxou/ZnIv65zSaaBqUXtP++poQ";
  system2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJW8Y4D8Q6pgoZxZ2CKGcz9K7+JWUxojouVWYKObzzHt";
  system3 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH18queSvalZ6ftHYr744tRut46OeMS9Z1SsDQvugCTD";
  system4 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJRNFsCGiDVk/isN+bAfndANYjmIG7hfDD2azki93h4V";
  system5 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIALR+WREWcS6d2lf8OH59yWSLGdv3PI5R6AOGobXB8a6";
  system6 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA81Jmm0LADyGRv5aURGvi8aoRCtQEjdD21AdQozqCqY";
  raspberrypi = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE+MBgCQO3KqMF20ljvce+pFhViExVD91iEiFvd4dq0h";
  system7 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGSkCdC46exqaT+lg99eDiav1d2i+mwPVaHcu1eUeKVZ";
  systems = [ system1 system2 system3 system4 system5 system6 system7 ];
in
{
  "toggl-lkasper.age".publicKeys = users ++ systems;
  "spotify.age".publicKeys = users ++ systems;
  "vaultwarden.age".publicKeys = users ++ systems;
  "steam-casper.age".publicKeys = users ++ systems;
  "aws_config.age".publicKeys = users ++ systems;
  "aws_credentials.age".publicKeys = users ++ systems;
  "avante-bedrock.age".publicKeys = users ++ systems;
#  "atticwto.age".publicKeys = users ++ systems;
#  "loboskey.age".publicKeys = users ;

}
