{
  flake.nixosModules.srv-uptime-kuma = {...}: {
    my.endpoints.uptime-kuma = {
      enable = true;
      tlsInternal = true;
      port = 4000;
      subdomain = "uptime";
    };
    services.uptime-kuma = {
      enable = true;
      settings.PORT = "4000";
    };
  };
}
