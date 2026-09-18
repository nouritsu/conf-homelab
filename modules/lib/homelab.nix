# Single owner of the `den.lib.homelab` key.
#
# den.lib is declared freeform multi-writer, unlike flake-parts' flake.lib which
# is `unique raw` and can only ever be written by one module - so helpers may be
# split across files here if this one grows.
{lib, ...}: {
  den.lib.homelab = rec {
    base-domain = "nouritsu.com";
    host-ip = "192.168.178.128";

    fqdn = subdomain:
      if subdomain == ""
      then base-domain
      else "${subdomain}.${base-domain}";

    # a caddy vhost, plus either a local dns record or a rathole tunnel
    endpoint = {
      subdomain,
      port,
      tunnel ? false,
      extraConfig ? "",
    }: {config, ...}: let
      domain = fqdn subdomain;

      name =
        if subdomain == ""
        then "www"
        else subdomain;

      role = config.services.rathole.role;

      addr-key =
        if role == "client"
        then "local_addr"
        else "bind_addr";
    in
      lib.mkMerge [
        {
          services.caddy.virtualHosts.${domain}.extraConfig = ''
            ${lib.optionalString (!tunnel) "tls internal"}
            reverse_proxy localhost:${toString port}
            ${extraConfig}
          '';
        }

        (lib.mkIf (!tunnel) {
          services.pihole-ftl.settings.dns.hosts = ["${host-ip}   ${domain}"];
        })

        (lib.mkIf tunnel {
          services.rathole.settings.${role}.services.${name}.${addr-key} = "127.0.0.1:${toString port}";

          sops.templates."rathole-credentials.toml".content = lib.mkAfter ''
            [${role}.services.${name}]
            token = "${config.sops.placeholder."rathole/token"}"
          '';
        })
      ];

    # route a container through the gluetun vpn container - it publishes no
    # ports of its own, gluetun publishes them on its behalf
    via-gluetun = name: ports: {
      virtualisation.oci-containers.containers.${name} = {
        dependsOn = ["gluetun"];
        extraOptions = lib.mkAfter ["--network=container:gluetun"];
      };

      virtualisation.oci-containers.containers.gluetun.ports = lib.mkAfter ports;
    };
  };
}
