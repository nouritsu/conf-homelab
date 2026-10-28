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
    };
  };
}
