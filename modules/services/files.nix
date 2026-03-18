{self, ...}: {
  flake.nixosModules = {
    srv-copyparty = {config, ...}: let
      endpoint = config.my.endpoints.copyparty;
    in {
      imports = [self.nixosModules.copyparty-secrets];

      my.endpoints.copyparty = {
        enable = true;
        tlsInternal = true;
        port = 3923;
        subdomain = "files";
      };

      my.containers.copyparty = {
        enable = true;
        image = {
          name = "dj";
          provider = "official";
        };

        ports = ["${toString endpoint.port}:3923"];

        vols = [
          "/data/copyparty:/cfg"
          "${config.sops.templates."copyparty.conf".path}:/cfg/copyparty.conf:ro"
          "/data:/data:ro"
          "/media/download:/download:ro"
          "/media/media:/media"
          "/media/shared:/shared"
        ];
      };

      systemd.tmpfiles.rules = [
        "d /data/copyparty 0755 root root -"
        "d /data/copyparty/hists 0755 root root -"
        "d /media/shared 0755 root root -"
      ];
    };

    copyparty-secrets = {config, ...}: {
      sops.secrets."copyparty/aneesh-password" = {};

      sops.templates."copyparty.conf" = {
        content = ''
          [global]
          p: 3923
          hist: /cfg/hists/
          e2dsa
          e2ts
          rproxy: 1
          xff-src: lan
          usernames
          ah-alg: argon2

          [accounts]
          aneesh: ${config.sops.placeholder."copyparty/aneesh-password"}

          [/data]
          /data
          accs:
            rwda: aneesh

          [/download]
          /download
          accs:
            rwda: aneesh

          [/media]
          /media
          accs:
            rwda: aneesh
            r: *

          [/shared]
          /shared
          accs:
            rwda: aneesh
            rw: *
        '';
      };
    };
  };
}
