{den, ...}: {
  den.aspects.srv-jellyseerr.nixos = {...}: let
    inherit (den.lib.homelab) endpoint;
  in {
    imports = [
      (endpoint {
        subdomain = "media";
        port = 5055;
      })
    ];

    services.jellyseerr.enable = true;
  };
}
