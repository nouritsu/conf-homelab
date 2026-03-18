{self, ...}: {
  flake.nixosModules = {
    srv-immich = {config, ...}: let
      endpoint = config.my.endpoints.immich;
    in {
      imports = [
        self.nixosModules.immich-secrets
        self.nixosModules.immich-db
      ];
      my.endpoints.immich = {
        enable = true;
        tlsInternal = true;
        port = 2283;
        subdomain = "photos";
      };
      my.containers.immich-server = {
        enable = true;
        image.url = "ghcr.io/immich-app/immich-server:release";
        ports = ["${toString endpoint.port}:2283"];
        envFile = [config.sops.templates."immich.env".path];
        vols = ["/data/immich/upload:/data" "/etc/localtime:/etc/localtime:ro"];
        dri-passthrough = true;
        extra-options = [
          "--add-host=immich-db:host-gateway"
          "--add-host=immich-redis:host-gateway"
          "--add-host=immich-ml:host-gateway"
        ];
      };
      my.containers.immich-ml = {
        enable = true;
        image.url = "ghcr.io/immich-app/immich-machine-learning:release";
        ports = ["3003:3003"];
        vols = ["immich-ml-cache:/cache"];
        envFile = [config.sops.templates."immich.env".path];
      };
      my.containers.immich-redis = {
        enable = true;
        image.url = "docker.io/valkey/valkey:9";
        ports = ["6379:6379"];
        extra-options = [
          "--health-cmd=redis-cli ping || exit 1"
          "--health-interval=10s"
          "--health-timeout=5s"
          "--health-retries=5"
        ];
      };
      virtualisation.oci-containers.containers.immich-server.dependsOn = ["immich-redis" "immich-db"];
      virtualisation.oci-containers.containers.immich-server.environment = {
        IMMICH_MACHINE_LEARNING_URL = "http://immich-ml:3003";
      };
      systemd.tmpfiles.rules = [
        "d /data/immich 0775 1000 data -"
        "d /data/immich/upload 0775 1000 data -"
      ];
    };

    immich-secrets = {config, ...}: {
      sops.templates."immich.env" = {
        content = ''
          DB_PASSWORD=${config.sops.placeholder."photos/postgres-password"}
          DB_HOSTNAME=immich-db
          DB_PORT=5434
          DB_USERNAME=immich
          DB_DATABASE_NAME=immich
          REDIS_HOSTNAME=immich-redis
          REDIS_PORT=6379
        '';
      };
    };

    immich-db = {config, ...}: {
      imports = [self.nixosModules.immich-db-secrets];
      my.containers.immich-db = {
        enable = true;
        restart.enable = false; # database
        image.url = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0";
        env = {
          POSTGRES_USER = "immich";
          POSTGRES_DB = "immich";
          POSTGRES_INITDB_ARGS = "--data-checksums";
          PGPORT = "5434";
        };
        envFile = [config.sops.templates."immich-postgres.env".path];
        vols = ["immich-db:/var/lib/postgresql/data"];
        ports = ["5434:5434"];
        extra-options = [
          "--shm-size=128m"
          "--health-cmd=pg_isready -U immich -p 5434"
          "--health-interval=10s"
          "--health-timeout=5s"
          "--health-retries=5"
        ];
      };
    };

    immich-db-secrets = {config, ...}: {
      sops.secrets."photos/postgres-password" = {};
      sops.templates."immich-postgres.env" = {
        content = ''
          POSTGRES_PASSWORD=${config.sops.placeholder."photos/postgres-password"}
        '';
      };
    };
  };
}
