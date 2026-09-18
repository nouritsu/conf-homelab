{den, ...}: {
  # consumes the `endpoint` quirk: one vhost per service that declared one
  den.aspects.caddy.nixos = {
    endpoint,
    lib,
    ...
  }: let
    inherit (den.lib.homelab) fqdn;
    sorted = lib.sort (a: b: a.subdomain < b.subdomain) endpoint;
  in {
    services.caddy.enable = true;
    networking.firewall.allowedTCPPorts = [80 443];

    security.pki.certificateFiles = [
      ../../../../assets/caddy.crt
    ];

    services.caddy.virtualHosts = lib.listToAttrs (map (e:
      lib.nameValuePair (fqdn e.subdomain) {
        extraConfig = ''
          ${lib.optionalString (!(e.tunnel or false)) "tls internal"}
          reverse_proxy localhost:${toString e.port}
        '';
      })
    sorted);

    # two endpoints on one subdomain would silently collapse into a single
    # vhost, so catch it on the pool rather than on the generated config
    assertions = let
      subdomains = map (e: e.subdomain) endpoint;
    in [
      {
        assertion = lib.length (lib.unique subdomains) == lib.length subdomains;
        message = "caddy: two endpoints claim the same subdomain (${lib.concatStringsSep ", " (lib.sort (a: b: a < b) subdomains)})";
      }
    ];
  };
}
