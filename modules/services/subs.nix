{self, ...}: {
  flake.nixosModules.srv-bazarr = {...}: let
    inherit (self.lib) endpoint via-gluetun;
    port = 8088;
  in {
    imports = [
      (endpoint {
        subdomain = "subs";
        inherit port;
      })
      (via-gluetun "bazarr" ["${toString port}:6767"])
    ];

    virtualisation.oci-containers.containers.bazarr = {
      image = "lscr.io/linuxserver/bazarr:latest";
      volumes = ["/data/bazarr:/config" "/media/media:/media"];
    };

    systemd.tmpfiles.rules = ["d /data/bazarr 0775 1000 data -"];
  };
}
