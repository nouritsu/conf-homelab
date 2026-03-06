{config, ...}: let
  endpoint = config.my.endpoints.immich;
in {
  imports = [
    ./postgres.nix
    ./secrets.nix
  ];

  my.endpoints.immich = {
    port = 2283;
    subdomain = "photos";
  };

  my.containers.immich-server = {
    enable = true;
    image.url = "ghcr.io/immich-app/immich-server:release";

    ports = ["${toString endpoint.port}:2283"];

    envFile = [
      config.sops.templates."immich.env".path
    ];

    vols = [
      "/data/immich/upload:/data"
      "/etc/localtime:/etc/localtime:ro"
    ];

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

    vols = [
      "immich-ml-cache:/cache"
    ];

    envFile = [
      config.sops.templates."immich.env".path
    ];
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
}
