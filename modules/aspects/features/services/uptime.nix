{
  den.aspects.services.uptime-kuma = let
    port = 4000;
  in {
    endpoint = {
      subdomain = "uptime";
      inherit port;
    };
    backup.paths = ["/var/lib/private/uptime-kuma"];

    nixos.services.uptime-kuma = {
      enable = true;
      settings.PORT = toString port;
    };
  };
}
