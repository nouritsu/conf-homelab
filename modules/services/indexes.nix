{
  flake.nixosModules.srv-prowlarr = {config, ...}: let
    endpoint = config.my.endpoints.prowlarr;
  in {
    my.endpoints.prowlarr = {
      enable = true;
      tlsInternal = true;
      port = 8084;
      subdomain = "indexes";
    };
    my.containers.prowlarr = {
      enable = true;
      vpn = true;
      image.provider = "lscr";
      ports = ["${toString endpoint.port}:9696"];
      vols = ["/data/prowlarr:/config"];
    };
    systemd.tmpfiles.rules = ["d /data/prowlarr 0775 1000 data -"];
  };
}
