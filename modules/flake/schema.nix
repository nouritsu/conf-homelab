{
  den.schema.host = {lib, ...}: let
    inherit (lib) mkOption types;
  in {
    options = {
      tunnels-via = mkOption {
        description = "The host whose rathole server publishes this host's public endpoints.";
        type = types.nullOr types.str;
        default = null;
      };

      active = mkOption {
        description = "Whether the host has a machine; `deploy` and `stale` skip an inactive one, which is still evaluated.";
        type = types.bool;
        default = true;
      };

      deploy = mkOption {
        description = "Where `deploy <host>` builds and activates; null for hosts that are never deployed.";
        default = null;
        type = types.nullOr (types.submodule {
          options = {
            target = mkOption {type = types.str;};
            # null builds on this machine and lets the target substitute
            build-host = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
          };
        });
      };
    };
  };
}
