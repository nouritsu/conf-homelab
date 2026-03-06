{config, ...}: {
  sops.secrets."postgres-password" = {};
  sops.templates."postgres.env" = {
    content = ''
      POSTGRES_PASSWORD=${config.sops.placeholder."postgres-password"}
    '';
  };
  my.containers.documenso-db = {
    enable = true;
    image.url = "postgres:15";

    env = {
      POSTGRES_USER = "documenso";
      POSTGRES_DB = "documenso";
    };

    envFile = [
      config.sops.templates."postgres.env".path
    ];

    vols = [
      "documenso-db:/var/lib/postgresql/data"
    ];

    ports = ["5433:5432"];

    extra-options = [
      "--health-cmd=pg_isready -U documenso"
      "--health-interval=10s"
      "--health-timeout=5s"
      "--health-retries=5"
    ];
  };
}
