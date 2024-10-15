{config, lib, pkgs, agenix, ... }: {


 age = {
    identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {         
      spotify-test = {
        file = ../../secrets/spotify-lkasper.age;
        path = "/home/casper/.config/spotify/prefs";
        owner = "casper";
        group = "users";
        mode = "600";
      };
    };
  };
}

