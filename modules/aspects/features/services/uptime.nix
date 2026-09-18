{
  den.aspects.srv-uptime-kuma = let
    port = 4000;
  in {
    endpoint = {
      subdomain = "uptime";
      inherit port;
    };

    nixos.services.uptime-kuma = {
      enable = true;
      settings.PORT = toString port;
    };
  };
}
