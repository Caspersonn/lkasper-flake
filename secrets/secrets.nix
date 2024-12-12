let
  user1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOtpGyC5u8+T71Oo+QL9ym+hWaNSiisskL43ElmpWiEr";
  users = [ user1 ];

  system1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGsk6h6kDNUaLyDbImcxou/ZnIv65zSaaBqUXtP++poQ"; 
  system2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJW8Y4D8Q6pgoZxZ2CKGcz9K7+JWUxojouVWYKObzzHt";
  system3 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH18queSvalZ6ftHYr744tRut46OeMS9Z1SsDQvugCTD";
  system4 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJRNFsCGiDVk/isN+bAfndANYjmIG7hfDD2azki93h4V";
  systems = [ system1 system2 system3 system4 ];
in
{
  "toggl-lkasper.age".publicKeys = users ++ systems;
  "spotify-lkasper.age".publicKeys = users ++ systems;
  "vaultwarden.age".publicKeys = users ++ systems;
  "steam-casper.age".publicKeys = users ++ systems;
#  "atticwto.age".publicKeys = users ++ systems;
#  "loboskey.age".publicKeys = users ;

}
