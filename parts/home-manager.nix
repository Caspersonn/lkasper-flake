{ inputs, ... }: {
  # Centralized home-manager configurations for all hosts
  flake.homeConfigurations = {
    "casper@technative-casper" = inputs.self.lib.makeHomeConf {
      hostname = "technative-casper";
      imports = [ inputs.self.modules.homeManager.casper ];
    };

    "casper@gaming-casper" = inputs.self.lib.makeHomeConf {
      hostname = "gaming-casper";
      imports = [ inputs.self.modules.homeManager.casper ];
    };

    "casper@personal-casper" = inputs.self.lib.makeHomeConf {
      hostname = "personal-casper";
      imports = [ inputs.self.modules.homeManager.casper ];
    };

    "casper@server-casper" = inputs.self.lib.makeHomeConf {
      hostname = "server-casper";
      system = "aarch64-linux";
      imports = [ inputs.self.modules.homeManager.casper ];
    };
  };
}
