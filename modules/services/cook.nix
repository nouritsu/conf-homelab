{
  flake.nixosModules.srv-cook-cli = {config, ...}: let
    endpoint = config.my.endpoints.cook-cli;
  in {
    my.endpoints.cook-cli = {
      enable = true;
      tlsInternal = true;
      port = 9080;
      subdomain = "cook";
    };
    services.cook-cli = {
      enable = true;
      port = endpoint.port;
    };
  };
}
