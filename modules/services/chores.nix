{self, ...}: {
  flake.nixosModules.srv-grocy = {...}: let
    inherit (self.lib) endpoint;
    port = 9283;
  in {
    imports = [
      (endpoint {
        subdomain = "chores";
        inherit port;
      })
    ];

    virtualisation.oci-containers.containers.grocy = {
      image = "lscr.io/linuxserver/grocy:latest";
      ports = ["${toString port}:80"];
      volumes = ["/data/grocy:/config"];
    };

    systemd.tmpfiles.rules = ["d /data/grocy 0775 1000 data -"];
  };
}
