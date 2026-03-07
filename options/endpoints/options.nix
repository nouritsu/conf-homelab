{
  flake.nixosModules.opts-endpoints = {
    lib,
    config,
    ...
  }: let
    inherit (lib) mkOption mkEnableOption types;
    top-config = config;

    opts = {
      name,
      config,
      ...
    }: {
      options = {
        enable = mkEnableOption "endpoint ${name}";

        tunnel = mkEnableOption "${name} as rathole service";

        tlsInternal = mkEnableOption "internal TLS for caddy";

        domain = mkOption {
          type = types.str;
          readOnly = true;
          default =
            if config.subdomain != ""
            then "${config.subdomain}.${top-config.networking.domain}"
            else top-config.networking.domain;
          description = "Full domain (computed)";
        };

        subdomain = mkOption {
          type = types.str;
          default = "";
          description = "Subdomain for this endpoint";
        };

        port = mkOption {
          type = types.nullOr types.port;
          default = null;
          description = "Port to reverse proxy to";
        };

        extraConfig = mkOption {
          type = types.str;
          default = "";
          description = "Caddy extraConfig";
        };
      };
    };
  in {
    options.my.endpoints = mkOption {
      type = types.attrsOf (types.submodule opts);
      default = {};
      description = "Endpoint definitions for caddy";
    };
  };
}
