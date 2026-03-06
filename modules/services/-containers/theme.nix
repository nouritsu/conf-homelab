{
  lib,
  config,
  name,
  ...
}: let
  inherit (lib) mkOption mkEnableOption types;
  cfg = config.theme;
in {
  options.theme = {
    enable = mkEnableOption "themeing";

    provider = mkOption {
      type = types.enum ["ghcr" "other"];
      default = "other";
      description = "Theme provider";
    };

    is-community-theme = mkEnableOption "theme community status";

    name = mkOption {
      type = types.str;
      default = name;
      description = "Theme package name (used if provider supplied)";
    };

    url = mkOption {
      type = types.str;
      default =
        {
          ghcr = "ghcr.io/themepark-dev/theme.park:${cfg.name}";
          other = "";
        }
        .${cfg.provider};
      description = "Full theme url, only manually set if provider not set";
    };

    theme-name = mkOption {
      type = types.str;
      default = "";
      description = "Name of theme within theme package";
    };
  };
}
