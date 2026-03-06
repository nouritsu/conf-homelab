{config, ...}: let
  port = "8788";
in {
  imports = [
    ./secrets.nix
  ];

  my.containers.enclosed = {
    enable = true;

    image = {
      provider = "official";
      owner = "corentinth";
    };

    ports = ["${port}:8787"];

    env = {
      PUBLIC_IS_AUTHENTICATION_REQUIRED = "true";
    };

    envFile = [
      config.sops.templates."enclosed.env".path
    ];

    vols = [
      "/data/enclosed:/app/.data"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /data/enclosed 0775 1000 data -"
  ];
}
