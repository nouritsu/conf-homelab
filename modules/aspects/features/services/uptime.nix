{den, ...}: {
  den.aspects.srv-uptime-kuma.nixos = {...}: let
    inherit (den.lib.homelab) endpoint;
    port = 4000;
  in {
    imports = [
      (endpoint {
        subdomain = "uptime";
        inherit port;
      })
    ];

    services.uptime-kuma = {
      enable = true;
      settings.PORT = toString port;
    };
  };
}
