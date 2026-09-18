{self, ...}: {
  flake.nixosModules = {
    srv-aria2 = {config, ...}: let
      inherit (self.lib) endpoint via-gluetun;
      web-port = 6880;
      rpc-port = 6800;
    in {
      imports = [
        self.nixosModules.aria2-secrets
        (endpoint {
          subdomain = "download";
          port = web-port;
        })
        (endpoint {
          subdomain = "aria2";
          port = rpc-port;
        })
        (via-gluetun "aria2-pro" ["${toString rpc-port}:6800"])
      ];

      virtualisation.oci-containers.containers.aria2-pro = {
        image = "p3terx/aria2-pro:latest";
        environment = {
          PUID = "1000";
          PGID = "1000";
          UPDATE_TRACKERS = "false";
        };
        environmentFiles = [config.sops.templates."aria2.env".path];
        volumes = ["/data/ariang/config:/config" "/media/download/aria2:/downloads"];
        extraOptions = ["--log-driver=json-file" "--log-opt=max-size=1m"];
      };

      virtualisation.oci-containers.containers.ariang = {
        image = "p3terx/ariang:latest";
        ports = ["${toString web-port}:6880"];
        extraOptions = ["--log-driver=json-file" "--log-opt=max-size=1m"];
      };
      systemd.tmpfiles.rules = [
        "d /data/ariang 0775 1000 data -"
        "d /data/ariang/config 0775 1000 data -"
        "d /media/download/aria2 2775 1000 data -"
      ];
    };

    aria2-secrets = {config, ...}: {
      sops.secrets."aria2/rpc" = {};
      sops.templates."aria2.env" = {
        content = ''
          RPC_SECRET=${config.sops.placeholder."aria2/rpc"}
        '';
      };
    };
  };
}
