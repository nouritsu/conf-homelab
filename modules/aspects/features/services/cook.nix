{den, ...}: {
  den.aspects.srv-cook-cli.nixos = {...}: let
    inherit (den.lib.homelab) endpoint;
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
