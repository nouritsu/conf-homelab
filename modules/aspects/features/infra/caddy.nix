{den, ...}: {
  # consumes the `endpoint` quirk, and the `tunnel` quirk on a rathole server
  den.aspects.caddy = {host, ...}: {
    # its internal ca signs every lan vhost; a new one is trusted nowhere
    backup.paths = ["/var/lib/caddy"];

    nixos = {
      endpoint,
      tunnel,
      config,
      lib,
      ...
    }: let
      inherit (den.lib.homelab) fqdn;
      domain-of = e: e.domain or (fqdn e.subdomain);
      public = e: e.public or false;

      # a host behind a tunnel leaves its public endpoints to the tunnel's server
      tunnelled = host.tunnels-via != null;
      # a vhost-less endpoint is only a tunnel, for another vhost to proxy to
      vhosts = lib.filter (e: e.vhost or true) (lib.filter (e: !(tunnelled && public e)) endpoint ++ tunnel);

      known = ["subdomain" "domain" "port" "extraConfig" "public" "vhost"];
      problems = e:
        map (k: "unknown key ${k}") (lib.subtractLists known (lib.attrNames e))
        ++ lib.optional ((e ? subdomain) == (e ? domain)) "needs exactly one of subdomain or domain"
        ++ lib.optional (!(e.vhost or true) && !(public e)) "vhost = false only means something for a public endpoint";
      malformed = lib.filter (e: problems e != []) endpoint;
    in {
      services.caddy.enable = true;
      networking.firewall.allowedTCPPorts = [80 443];

      security.pki.certificateFiles = lib.mkIf (lib.any (e: !(public e)) vhosts) [
        ../../../../assets/caddy.crt
      ];

      services.caddy.virtualHosts = lib.listToAttrs (map (e:
        lib.nameValuePair (domain-of e) {
          extraConfig =
            ''
              ${lib.optionalString (!(public e)) "tls internal"}
              ${lib.optionalString (e ? port) "reverse_proxy localhost:${toString e.port}"}
            ''
            + e.extraConfig or "";
        })
      vhosts);

      # two endpoints on one domain would silently collapse into a single
      # vhost, so catch it on the pool rather than on the generated config
      assertions = let
        domains = map domain-of vhosts;
      in [
        {
          assertion = lib.length (lib.unique domains) == lib.length domains;
          message = "caddy: two endpoints claim the same domain (${lib.concatStringsSep ", " (lib.sort (a: b: a < b) domains)})";
        }
        {
          assertion = malformed == [];
          message = "caddy: malformed endpoints (${lib.concatMapStringsSep "; " (e: "${e.subdomain or e.domain or "?"}: ${lib.concatStringsSep ", " (problems e)}") malformed})";
        }
        {
          assertion = !(tunnelled && lib.any public endpoint) || config.services.rathole.enable;
          message = "caddy: ${host.name} leaves its public endpoints to ${toString host.tunnels-via}, but runs no rathole client";
        }
      ];
    };
  };
}
