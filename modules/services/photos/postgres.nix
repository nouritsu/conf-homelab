{config, ...}: {
  sops.secrets."postgres-password" = {};
  sops.templates."immich-postgres.env" = {
    content = ''
      POSTGRES_PASSWORD=${config.sops.placeholder."postgres-password"}
    '';
  };

  my.containers.immich-db = {
    enable = true;
    image.url = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0";

    env = {
      POSTGRES_USER = "immich";
      POSTGRES_DB = "immich";
      POSTGRES_INITDB_ARGS = "--data-checksums";
      PGPORT = "5434";
    };

    envFile = [
      config.sops.templates."immich-postgres.env".path
    ];

    vols = [
      "immich-db:/var/lib/postgresql/data"
    ];

    ports = ["5434:5434"];

    extra-options = [
      "--shm-size=128m"
      "--health-cmd=pg_isready -U immich -p 5434"
      "--health-interval=10s"
      "--health-timeout=5s"
      "--health-retries=5"
    ];
  };
}
