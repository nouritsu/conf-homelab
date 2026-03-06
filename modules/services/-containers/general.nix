{lib, ...}: let
  inherit (lib) mkOption mkEnableOption types;
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
  };
}
