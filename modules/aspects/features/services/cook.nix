{
  den.aspects.services.cook-cli = let
    port = 9080;
  in {
    endpoint = {
      subdomain = "cook";
      inherit port;
    };

    nixos.services.cook-cli = {
      enable = true;
      inherit port;
    };
  };
}
