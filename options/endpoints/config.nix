{
  flake.nixosModules.opts-endpoints = {
    config,
    lib,
    ...
  }: let
    cfg = config.my.endpoints;
    enabled = lib.filterAttrs (_: v: v.enable) cfg;
    tunneled = lib.filterAttrs (_: v: v.tunnel) enabled;
    local = lib.filterAttrs (_: v: !v.tunnel) enabled;
  in {
    config = lib.mkMerge [
      (lib.mkIf (enabled != {})
        {
          assertions = let
            has-duplicates = list: (builtins.length list) != (builtins.length (lib.unique list));
            active_ports = lib.filter (p: p != null) (lib.mapAttrsToList (_: v: v.port) enabled);
            tunneled_incorrectly = lib.filterAttrs (_: v: v.port == null) tunneled;
          in [
            {
              assertion = !has-duplicates (lib.mapAttrsToList (_: v: v.domain) enabled);
              message = "my.endpoints: duplicate domains in endpoints";
            }
            {
              assertion = !has-duplicates active_ports;
              message = "my.endpoints: duplicate ports in endpoints";
            }
            {
              assertion = tunneled_incorrectly == {};
              message = "my.endpoints: tunneled endpoints must have a defined port";
            }
          ];
          services.pihole-ftl.settings.dns.hosts =
            lib.mapAttrsToList
            (_: ep: "192.168.178.128   ${ep.domain}")
            local;

          services.caddy.virtualHosts = let
            to_caddy_vhost = name: ep:
              lib.nameValuePair ep.domain {
                extraConfig =
                  if ep.port == null
                  then ''
                    ${if !ep.tunnel then "tls internal" else ""}
                    ${ep.extraConfig}
                  ''
                  else ''
                    ${if !ep.tunnel then "tls internal" else ""}
                    reverse_proxy localhost:${toString ep.port}
                    ${ep.extraConfig}
                  '';
              };
          in
            lib.mapAttrs' to_caddy_vhost enabled;
        })

      (lib.mkIf (tunneled != {})
        {
          services.rathole.settings.${config.services.rathole.role}.services = let
            srv_name = ep:
              if ep.subdomain != ""
              then ep.subdomain
              else "www";
            addr_key =
              if config.services.rathole.role == "client"
              then "local_addr"
              else "bind_addr";
            to_rathole_service = _: ep:
              lib.nameValuePair (srv_name ep) {
                ${addr_key} = "127.0.0.1:${toString ep.port}";
              };
          in
            lib.mapAttrs' to_rathole_service tunneled;

          sops.templates."rathole-credentials.toml".content = let
            srv_name = ep:
              if ep.subdomain != ""
              then ep.subdomain
              else "www";
            to_rathole_credential = _: ep:
              /*
              toml
              */
              ''
                [${config.services.rathole.role}.services.${srv_name ep}]
                token = "${config.sops.placeholder."rathole-token"}"
              '';
          in
            lib.concatStringsSep "\n" (lib.mapAttrsToList to_rathole_credential tunneled);
        })
    ];
  };
}
