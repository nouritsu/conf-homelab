{self, ...}: {
  flake.nixosModules = {
    srv-donetick = {config, ...}: let
      endpoint = config.my.endpoints.donetick;
    in {
      imports = [
        self.nixosModules.donetick-secrets
      ];

      my.endpoints.donetick = {
        enable = true;
        tlsInternal = true;
        subdomain = "chores";
        port = 2021;
      };

      my.containers.donetick = {
        enable = true;
        image.provider = "official";
        vols = [
          "/data/donetick:/donetick-data"
          "${config.sops.templates."donetick-config.yaml".path}:/config/homelab.yaml:ro"
        ];
        env = {
          DT_ENV = "homelab";
          DT_SQLITE_PATH = "/donetick-data/donetick.db";
        };
        ports = [
          "${toString endpoint.port}:2021"
        ];
      };

      systemd.tmpfiles.rules = ["d /data/donetick 0775 1000 data -"];
    };

    donetick-secrets = {config, ...}: let
      endpoint = config.my.endpoints.donetick;
    in {
      sops.secrets."donetick/jwt-secret" = {};

      sops.templates."donetick-config.yaml" = {
        owner = "root";
        content = builtins.toJSON {
          name = "homelab";

          jwt.secret = config.sops.placeholder."donetick/jwt-secret";

          database = {
            type = "sqlite";
            migration = true;
          };

          server = {
            serve_frontend = true;
            public_host = "https://${endpoint.domain}";
            cors_allow_origins = [
              "https://${endpoint.domain}"
              # needed for the android app
              "https://localhost"
              "http://localhost"
              "capacitor://localhost"
            ];
          };
        };
      };
    };
  };
}
