{self, ...}: {
  flake.nixosModules.srv-radarr = {...}: let
    inherit (self.lib) endpoint via-gluetun;
    port = 8085;
  in {
    imports = [
      (endpoint {
        subdomain = "movies";
        inherit port;
      })
      (via-gluetun "radarr" ["${toString port}:7878"])
    ];

    virtualisation.oci-containers.containers.radarr = {
      image = "lscr.io/linuxserver/radarr:latest";
      volumes = ["/data/radarr:/config" "/media/download:/data" "/media/media:/media"];
    };

    systemd.tmpfiles.rules = [
      "d /data/radarr 0775 1000 data -"
      "d /media/media/movies 2775 1000 data -"
    ];
  };
}
