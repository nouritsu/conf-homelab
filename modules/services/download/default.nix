{config, ...}: let
  endpoint = config.my.endpoints.download;
in {
  sops.secrets."aria2-rpc" = {};

  sops.templates."aria2.env" = {
    content = ''
      RPC_SECRET=${config.sops.placeholder."aria2-rpc"}
    '';
  };

  my.endpoints.download = {
    port = 6880;
    subdomain = "download";
  };

  my.endpoints.aria2 = {
    port = 6800;
    subdomain = "aria2";
  };

  my.containers.aria2-pro = {
    enable = true;
    vpn = true;

    image = {
      provider = "official";
      owner = "p3terx";
      name = "aria2-pro";
    };

    ports = ["6800:6800"];

    env = {
      PUID = "1000";
      PGID = "1000";
      UPDATE_TRACKERS = "false";
    };

    envFile = [
      config.sops.templates."aria2.env".path
    ];

    vols = [
      "/data/ariang/config:/config"
      "/media/download/aria2:/downloads"
    ];

    extra-options = [
      "--log-driver=json-file"
      "--log-opt=max-size=1m"
    ];
  };

  my.containers.ariang = {
    enable = true;

    image = {
      provider = "official";
      owner = "p3terx";
      name = "ariang";
    };

    ports = ["${toString endpoint.port}:6880"];

    extra-options = [
      "--log-driver=json-file"
      "--log-opt=max-size=1m"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /data/ariang 0775 1000 data -"
    "d /data/ariang/config 0775 1000 data -"
    "d /media/download/aria2 2775 1000 data -"
  ];
}
