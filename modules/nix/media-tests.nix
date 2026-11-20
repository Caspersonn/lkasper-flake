{ inputs, ... }: {
  perSystem = { pkgs, ... }: {
    checks.remux-provision = import ../../tests/media/remux.nix {
      inherit pkgs;
      inherit (inputs) agenix;
      inherit (inputs.self.modules.nixos) media-storage remux;
    };
    checks.aurral-flows-provision = import ../../tests/media/aurral-flows.nix {
      inherit pkgs;
      inherit (inputs) agenix;
      inherit (inputs.self.modules.nixos) media-storage aurral-flows media-backup;
    };
    checks.media-connections = import ../../tests/media/connections.nix {
      inherit pkgs;
      inherit (inputs) agenix;
      inherit (inputs.self.modules.nixos) media-storage holyarrs jackett media-connections;
    };
    checks.media-acquisition = import ../../tests/media/connections.nix {
      inherit pkgs;
      inherit (inputs) agenix;
      inherit (inputs.self.modules.nixos) media-storage holyarrs jackett media-connections decypharr;
    };
    checks.holyarrs-provision = import ../../tests/media/holyarrs.nix {
      inherit pkgs;
      inherit (inputs.self.modules.nixos) media-storage holyarrs;
    };
    checks.jackett-provision = import ../../tests/media/jackett.nix {
      inherit pkgs;
      inherit (inputs.self.modules.nixos) jackett;
    };
    checks.jellyfin-provision = import ../../tests/media/jellyfin.nix {
      inherit pkgs;
      inherit (inputs.self.modules.nixos) media-storage jellyfin;
    };
    checks.soundspan-provision = import ../../tests/media/soundspan.nix {
      inherit pkgs;
      inherit (inputs.self.modules.nixos) media-storage holyarrs soundspan postgres;
    };
    checks.backup-coverage = import ../../tests/media/backup-coverage.nix {
      inherit pkgs;
      inherit (inputs) agenix;
      inherit (inputs.self.modules.nixos) media-storage holyarrs jackett decypharr jellyfin soundspan postgres media-connections media-backup;
    };
    checks.decypharr-provision = import ../../tests/media/decypharr.nix {
      inherit pkgs;
      inherit (inputs) agenix;
      inherit (inputs.self.modules.nixos) media-storage decypharr media-backup;
    };
  };
}
