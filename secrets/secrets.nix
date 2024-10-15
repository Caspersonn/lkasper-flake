let
  user1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOtpGyC5u8+T71Oo+QL9ym+hWaNSiisskL43ElmpWiEr";
  user2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOtpGyC5u8+T71Oo+QL9ym+hWaNSiisskL43ElmpWiEr";
  users = [ user1 ];

  system1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGsk6h6kDNUaLyDbImcxou/ZnIv65zSaaBqUXtP++poQ"; 
  system2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJW8Y4D8Q6pgoZxZ2CKGcz9K7+JWUxojouVWYKObzzHt";
  systems = [ system1 system2 ];
in
{
  "secret1.age".publicKeys = [ user1 system1 ];
  "secret2.age".publicKeys = users ++ systems;
  "toggl-lkasper.age".publicKeys = users ++ systems;
  "spotify-lkasper.age".publicKeys = users ++ systems;
#  "atticwto.age".publicKeys = users ++ systems;
#  "loboskey.age".publicKeys = users ;

}
