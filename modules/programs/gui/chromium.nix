{ inputs, ... }: {
  flake.modules.nixos.chromium = { pkgs, ... }: {
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    programs.chromium = {
      enable = true;
      homepageLocation = "https://www.startpage.com/";
      extensions = [
        "nngceckbapebfimnlniiiahkandclblb;https://clients2.google.com/service/update2/crx"
        "ddkjiahejlhfcafbddmgiahcphecmpfh;https://clients2.google.com/service/update2/crx"
        "gebbhagfogifgggkldgodflihgfeippi;https://clients2.google.com/service/update2/crx"
        "cjjieeldgoohbkifkogalkmfpddeafcm;https://clients2.google.com/service/update2/crx"
        "jpmkfafbacpgapdghgdpembnojdlgkdl;https://clients2.google.com/service/update2/crx"
      ];
      extraOpts = {
        "WebAppInstallForceList" = [{
          "custom_name" = "Youtube";
          "create_desktop_shortcut" = false;
          "default_launch_container" = "window";
          "url" = "https://youtube.com";
        }];
      };
    };
  };
}
