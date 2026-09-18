{
  den.aspects.srv-jellyfin = let
    port = 8096;
  in {
    endpoint = {
      subdomain = "player";
      inherit port;
    };

    nixos = {
      virtualisation.oci-containers.containers.jellyfin = {
        image = "lscr.io/linuxserver/jellyfin:latest";
        ports = ["${toString port}:8096"];
        extraOptions = ["--device=/dev/dri:/dev/dri"];
        volumes = ["/data/jellyfin:/config" "/media/media:/media:ro"];
      };

      systemd.tmpfiles.rules = ["d /data/jellyfin 0775 1000 data -"];
    };
  };
}
