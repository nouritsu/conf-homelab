let
  uid = 9001;
in {
  den.aspects.games.valheim.nixos = {config, ...}: let
    owner = {
      owner = config.users.users.valheim.name;
      group = config.users.users.valheim.group;
    };
  in {
    sops.secrets."valheim/server-password" = owner;

    sops.templates."valheim-env" =
      owner
      // {
        content = ''
          SERVER_PASS=${config.sops.placeholder."valheim/server-password"}
        '';
      };

    users.users.valheim = {
      isSystemUser = true;
      group = "valheim";
      home = "/data/valheim";
      inherit uid;
    };
    users.groups.valheim.gid = uid;

    virtualisation.oci-containers.containers.valheim = {
      image = "lloesche/valheim-server:latest@sha256:fde7829b12d39203e155b6209689b70234f8a27d12c4d48baf890cc2ae2c2df3";

      ports = [
        "2456:2456/udp"
        "2457:2457/udp"
      ];

      environment = {
        SERVER_NAME = "Nouritsu's Server";
        SERVER_ARGS = "-devcommands";
        WORLD_NAME = "main";
        SERVER_PUBLIC = "false";
        BACKUPS = "true";
        BACKUPS_MAX_AGE = "7";
        BEPINEX = "true";
        PUID = toString uid;
        PGID = toString uid;
      };

      environmentFiles = [config.sops.templates."valheim-env".path];

      volumes = [
        "/data/valheim/config:/config"
        "/data/valheim/data:/opt/valheim"
      ];

      extraOptions = [
        "--cap-add=sys_nice"
        "--stop-timeout=120"
      ];
    };

    systemd.tmpfiles.rules = [
      "d /data/valheim 0755 valheim valheim - -"
      "d /data/valheim/config 0755 valheim valheim - -"
      "d /data/valheim/data 0755 valheim valheim - -"
    ];

    networking.firewall.allowedUDPPorts = [2456 2457];
  };
}
