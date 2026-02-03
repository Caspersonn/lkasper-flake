{ inputs, lib, ... }: {
  flake.modules.nixos.systemConstants = { lib, ... }: {
    options.systemConstants = {
      user = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "casper";
          description = "Primary username";
        };

        fullName = lib.mkOption {
          type = lib.types.str;
          default = "Luca Kasper";
          description = "User's full name";
        };

        email = lib.mkOption {
          type = lib.types.str;
          default = "lucakasper8@gmail.com";
          description = "User's email address";
        };
      };

      programs = {
        browser = lib.mkOption {
          type = lib.types.str;
          default = "firefox";
          description = "Default web browser";
        };

        terminal = lib.mkOption {
          type = lib.types.str;
          default = "ghostty";
          description = "Default terminal emulator";
        };

        fileManager = lib.mkOption {
          type = lib.types.str;
          default = "nautilus";
          description = "Default file manager";
        };
      };

      ui = {
        waybarChoice = lib.mkOption {
          type = lib.types.str;
          default = "bar1";
          description = "Waybar configuration choice";
        };
      };

      system = {
        adminEmail = lib.mkOption {
          type = lib.types.str;
          default = "lucakasper8@gmail.com";
          description = "System administrator email";
        };
      };
    };
  };
}
