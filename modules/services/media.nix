{self, ...}: {
  flake.nixosModules.srv-jellyseerr = {...}: let
    inherit (self.lib) endpoint;
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
