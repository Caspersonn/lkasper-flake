{ inputs, ... }: {
  # Torznab search source for HolyArrs. Indexers and the API key are set in its
  # web UI and kept in /var/lib/jackett. Reachable only over Nebula and Tailscale.
  flake.modules.nixos.jackett = { config, ... }:
    let
      port = config.services.jackett.port;
    in
    {
      services.jackett = {
        enable = true;
        openFirewall = false;
      };

      networking.firewall.interfaces = {
        "nebula.mesh".allowedTCPPorts = [ port ];
        ${config.services.tailscale.interfaceName}.allowedTCPPorts = [ port ];
      };
    };
}
