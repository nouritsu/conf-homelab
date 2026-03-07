{
  flake.nixosModules.srv-jellyseerr = {...}: {
    my.endpoints.jellyseerr = {
      enable = true;
      port = 5055;
      subdomain = "media";
    };
    services.jellyseerr.enable = true;
  };
}
