{
  flake.nixosModules.opts-containers = {lib, ...}: let
    inherit (lib) mkOption mkEnableOption types;

    containerOpts = {
      name,
      config,
      ...
    }: let
      imageCfg = config.image;
      themeCfg = config.theme;
    in {
      options = {
        enable = mkEnableOption "container";

        timezone = mkOption {
          type = types.str;
          default = "Europe/Berlin";
          description = "Timezone";
        };

        ports = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Port mappings in host:container format.";
        };

        env = mkOption {
          type = types.attrsOf types.str;
          default = {};
          description = "Additional environment variables.";
        };

        envFile = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Paths to environment files.";
        };

        devices = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Devices";
        };

        dri-passthrough = mkEnableOption "dri passthrough";
        vpn = mkEnableOption "gluetun vpn";

        vols = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Volume mount strings in host:container[:options] format.";
        };

        extra-options = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Extra options";
        };

        image = {
          provider = mkOption {
            type = types.enum ["lscr" "ghcr" "official" "other"];
            default = "other";
            description = "Image provider.";
          };

          owner = mkOption {
            type = types.str;
            default = name;
            description = "Image owner (for ghcr provider)";
          };

          name = mkOption {
            type = types.str;
            default = name;
            description = "Image name (used if provider supplied).";
          };

          tag = mkOption {
            type = types.str;
            default = "latest";
            description = "Version tag.";
          };

          url = mkOption {
            type = types.str;
            default =
              {
                lscr = "lscr.io/linuxserver/${imageCfg.name}:${imageCfg.tag}";
                ghcr = "ghcr.io/${imageCfg.owner}/${imageCfg.name}:${imageCfg.tag}";
                official = "${imageCfg.owner}/${imageCfg.name}:${imageCfg.tag}";
                other = "";
              }
              .${
                imageCfg.provider
              };
            description = "Full image url, only manually set if provider not set.";
          };
        };

        theme = {
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
                ghcr = "ghcr.io/themepark-dev/theme.park:${themeCfg.name}";
                other = "";
              }
              .${
                themeCfg.provider
              };
            description = "Full theme url, only manually set if provider not set";
          };

          theme-name = mkOption {
            type = types.str;
            default = "";
            description = "Name of theme within theme package";
          };
        };
      };
    };
  in {
    options.my.containers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule containerOpts);
      default = {};
    };
  };
}
