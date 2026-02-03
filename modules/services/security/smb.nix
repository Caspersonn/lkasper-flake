{ inputs, ... }: {
  flake.modules.nixos.smb = { config, pkgs, ... }: {
    services.samba = {
      enable = true;
      openFirewall = true;
      smbd.enable = true;
      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "server string" = "smbnix";
          "netbios name" = "smbnix";
          "security" = "user";
          "hosts allow" = "192.168.178. 0.0.0.0 127.0.0.1 localhost";
          "guest account" = "nobody";
          "map to guest" = "bad user";
        };
        "public" = {
          "path" = "${config.users.users.casper.home}/smb";
          "browseable" = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
          "force user" = "casper";
          "force group" = "wheel";
        };
      };
    };

    services.samba-wsdd = {
      enable = true;
      openFirewall = true;
    };
  };
}
