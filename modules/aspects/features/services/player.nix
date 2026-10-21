{
  den.aspects.services.jellyfin = let
    port = 8096;
  in {
    endpoint = {
      subdomain = "player";
      inherit port;
    };
    backup.exclude = [
      "/data/jellyfin/cache"
      "/data/jellyfin/log"
      "/data/jellyfin/data/temp"
      "/data/jellyfin/data/transcodes"
    ];

    nixos = {
      virtualisation.oci-containers.containers.jellyfin = {
        image = "lscr.io/linuxserver/jellyfin:latest@sha256:4ee07757abcaa0b74fbc74179392311dc2874c03b0bef04bc2d79e9e1a875793";
        ports = ["${toString port}:8096"];
        extraOptions = ["--device=/dev/dri:/dev/dri"];
        volumes = ["/data/jellyfin:/config" "/media/media:/media:ro"];
      };

      systemd.tmpfiles.rules = ["d /data/jellyfin 0775 1000 data -"];
    };
  };
}
