{
  flake.nixosModules.opts-endpoints = {
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
        (name: ep: "${config.my.net.ip}   ${ep.domain}")
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
