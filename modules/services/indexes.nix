{self, ...}: {
  flake.nixosModules.srv-prowlarr = {...}: let
    inherit (self.lib) endpoint via-gluetun;
    port = 8084;
  in {
    imports = [
      (endpoint {
        subdomain = "indexes";
        inherit port;
      })
      (via-gluetun "prowlarr" ["${toString port}:9696"])
    ];

    virtualisation.oci-containers.containers.prowlarr = {
      image = "lscr.io/linuxserver/prowlarr:latest";
      volumes = ["/data/prowlarr:/config"];
    };

    systemd.tmpfiles.rules = ["d /data/prowlarr 0775 1000 data -"];
  };
}
