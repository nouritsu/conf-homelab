{
  flake.nixosModules.opts-endpoints = {
    config,
    lib,
    ...
  }: let
    endpointOpts = {
      name,
      config,
      ...
    }: {
      options = {
        enable = lib.mkEnableOption "endpoint ${name}" // {default = true;};

        subdomain = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "Subdomain for this endpoint";
        };

        port = lib.mkOption {
          type = lib.types.port;
          description = "Port to reverse proxy to";
        };

        domain = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          default = "${config.subdomain}.${config.baseDomain}";
          description = "Full domain (computed)";
        };

        baseDomain = lib.mkOption {
          type = lib.types.str;
          default = "nouritsu.com";
          description = "Base domain to append to subdomain";
        };

        extraCaddyConfig = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = "Additional Caddy configuration";
        };
      };
    };
  in {
    options.my.endpoints = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule endpointOpts);
      default = {};
      description = "Endpoint definitions for reverse proxy and DNS";
    };
  };
}
