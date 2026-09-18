{
  den.aspects.caddy.nixos = {
    config,
    lib,
    ...
  }: {
    services.caddy.enable = true;
    networking.firewall.allowedTCPPorts = [80 443];

    security.pki.certificateFiles = [
      ../../../../assets/caddy.crt
    ];

    # two endpoints claiming one domain merge into a single vhost rather than
    # conflicting, so catch it here
    assertions =
      lib.mapAttrsToList (domain: vhost: {
        assertion = lib.count (lib.hasInfix "reverse_proxy") (lib.splitString "\n" vhost.extraConfig) <= 1;
        message = "caddy: ${domain} has more than one reverse_proxy - two endpoints claim this domain";
      })
      config.services.caddy.virtualHosts;
  };
}
