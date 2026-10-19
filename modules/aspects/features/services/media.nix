{
  den.aspects.services.jellyseerr = {
    endpoint = {
      subdomain = "media";
      port = 5055;
    };

    nixos.services.seerr.enable = true;
  };
}
