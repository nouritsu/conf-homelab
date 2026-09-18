{self, ...}: {
  flake.nixosModules.srv-jellyfin = {...}: let
    inherit (self.lib) endpoint;
    port = 8096;
  in {
    imports = [
      (endpoint {
        subdomain = "player";
        inherit port;
      })
    ];

    virtualisation.oci-containers.containers.jellyfin = {
      image = "lscr.io/linuxserver/jellyfin:latest";
      ports = ["${toString port}:8096"];
      extraOptions = ["--device=/dev/dri:/dev/dri"];
      volumes = ["/data/jellyfin:/config" "/media/media:/media:ro"];
    };

    systemd.tmpfiles.rules = ["d /data/jellyfin 0775 1000 data -"];
  };
}
