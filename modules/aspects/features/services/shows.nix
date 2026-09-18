{den, ...}: {
  den.aspects.srv-sonarr.nixos = {...}: let
    inherit (den.lib.homelab) endpoint via-gluetun;
    port = 8086;
  in {
    imports = [
      (endpoint {
        subdomain = "shows";
        inherit port;
      })
      (via-gluetun "sonarr" ["${toString port}:8989"])
    ];

    virtualisation.oci-containers.containers.sonarr = {
      image = "lscr.io/linuxserver/sonarr:latest";
      volumes = ["/data/sonarr:/config" "/media/download:/data" "/media/media:/media"];
    };

    systemd.tmpfiles.rules = [
      "d /data/sonarr 0775 1000 data -"
      "d /media/media/shows 2775 1000 data -"
    ];
  };
}
