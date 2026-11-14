{ ... }:

# Google Pixel 10a running the Mobile Nebula app. Not a NixOS host: it only
# needs a slot in the mesh registry so nebula-admin can sign it and the other
# hosts resolve pixel-10a.mesh.
{
  casper.nebula.nodes.pixel-10a = {
    address = "10.123.0.101";
    groups = [ "phones" ];
  };
}
