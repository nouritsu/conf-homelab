{self, ...}: {
  flake.nixosModules.srv-uptime-kuma = {...}: let
    inherit (self.lib) endpoint;
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
