{
  lib,
  config,
  name,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.image;
in {
  options.image = {
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
          lscr = "lscr.io/linuxserver/${cfg.name}:${cfg.tag}";
          ghcr = "ghcr.io/${cfg.owner}/${cfg.name}:${cfg.tag}";
          official = "${cfg.owner}/${cfg.name}:${cfg.tag}";
          other = "";
        }
        .${
          cfg.provider
        };
      description = "Full image url, only manually set if provider not set.";
    };
  };
}
