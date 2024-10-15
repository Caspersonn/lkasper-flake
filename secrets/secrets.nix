let
  user1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOtpGyC5u8+T71Oo+QL9ym+hWaNSiisskL43ElmpWiEr";
  users = [ user1 ];

  system1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGsk6h6kDNUaLyDbImcxou/ZnIv65zSaaBqUXtP++poQ"; 
  systems = [ system1 ];
in
{
  "secret1.age".publicKeys = [ user1 system1 ];
  "secret2.age".publicKeys = users ++ systems;
  "toggl-lkasper.age".publicKeys = users ++ systems;
  "spotify-lkasper.age".publicKeys = users ++ systems;
#  "atticwto.age".publicKeys = users ++ systems;
#  "loboskey.age".publicKeys = users ;

}
