{
  flake.nixosModules.srv-uptime-kuma = {...}: {
    my.endpoints.uptime-kuma = {
      enable = true;
      port = 4000;
      subdomain = "monitor";
    };
    services.uptime-kuma = {
      enable = true;
      settings.PORT = "4000";
    };
  };
}
