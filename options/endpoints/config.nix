{
  flake.nixosModules.opts = {
    config,
    lib,
    ...
  }: let
    cfg = config.my.endpoints;
    enabledEndpoints = lib.filterAttrs (n: v: v.enable) cfg;
  in {
    config = lib.mkIf (enabledEndpoints != {}) {
      services.pihole-ftl.settings.dns.hosts =
        lib.mapAttrsToList
        (name: ep: "192.168.178.128   ${ep.domain}")
        enabledEndpoints;

      services.caddy.virtualHosts =
        lib.mapAttrs'
        (name: ep:
          lib.nameValuePair ep.domain {
            extraConfig = ''
              tls internal
              reverse_proxy localhost:${toString ep.port}
              ${ep.extraCaddyConfig}
            '';
          })
        enabledEndpoints;
    };
  };
}
