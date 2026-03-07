{
  flake.nixosModules.srv-jellyseerr = {...}: {
    my.endpoints.jellyseerr = {
      port = 5055;
      subdomain = "media";
    };
    services.jellyseerr.enable = true;
  };
}
