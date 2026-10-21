{
  den.aspects.services.cook-cli = let
    port = 9080;
  in {
    endpoint = {
      subdomain = "cook";
      inherit port;
    };
    backup = {config, ...}: {
      paths = [config.services.cook-cli.basePath];
    };

    nixos.services.cook-cli = {
      enable = true;
      inherit port;
    };
  };
}
