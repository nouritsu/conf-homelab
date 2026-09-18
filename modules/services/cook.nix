{self, ...}: {
  flake.nixosModules.srv-cook-cli = {...}: let
    inherit (self.lib) endpoint;
    port = 9080;
  in {
    imports = [
      (endpoint {
        subdomain = "cook";
        inherit port;
      })
    ];

    services.cook-cli = {
      enable = true;
      inherit port;
    };
  };
}
