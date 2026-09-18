{
  # a class body is a full NixOS module, so the submodule-extending option
  # declaration ports unchanged. It must stay free of entity args (host/user)
  # or den would emit the option declaration once per entity.
  den.aspects.containers.nixos = {
    config,
    lib,
    pkgs,
    ...
  }: let
    top = config;

    data-gid = toString top.users.groups.data.gid;
    backend = top.virtualisation.oci-containers.backend;
    containers = top.virtualisation.oci-containers.containers;

    get-host-port = mapping: let
      parts = lib.splitString ":" mapping;
      host-port =
        if builtins.length parts == 3
        then builtins.elemAt parts 1
        else builtins.head parts;
      container-port = lib.last parts;
      protocol = let
        p = lib.splitString "/" container-port;
      in
        if builtins.length p > 1
        then lib.last p
        else "tcp";
    in "${host-port}/${protocol}";

    get-container-port = mapping: lib.last (lib.splitString ":" mapping);
    has-duplicates = list: (builtins.length list) != (builtins.length (lib.unique list));

    restart-unit = name: lib.nameValuePair "restart-container-${name}";
  in {
    # defaults every container gets, applied through the upstream submodule
    options.virtualisation.oci-containers.containers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({config, ...}: {
        config = lib.mkMerge [
          {
            environment.TZ = lib.mkDefault "Europe/Berlin";

            # 1400 sits between a service's own flags (1000) and
            # --network=container:gluetun (mkAfter, 1500)
            extraOptions = lib.mkOrder 1400 ["--group-add=${data-gid}"];
          }

          # linuxserver.io images take the uid/gid to run as from the environment
          (lib.mkIf (lib.hasPrefix "lscr.io/linuxserver/" config.image) {
            environment = {
              PUID = lib.mkDefault "1000";
              PGID = lib.mkDefault data-gid;
            };
          })
        ];
      }));
    };

    config = {
      # some container workloads (search indexers, databases) need far more
      # mmap regions than the default 65530
      boot.kernel.sysctl."vm.max_map_count" = 262144;

      # every container is restarted nightly; a service opts out with
      #   systemd.timers.restart-container-<name>.enable = false;
      systemd.services = lib.mapAttrs' (name: _:
        restart-unit name {
          description = "Scheduled restart of ${name} container";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.systemd}/bin/systemctl restart ${backend}-${name}.service";
          };
        })
      containers;

      systemd.timers = lib.mapAttrs' (name: _:
        restart-unit name {
          wantedBy = ["timers.target"];
          description = "Daily restart timer for ${name} container";
          timerConfig = {
            OnCalendar = "*-*-* 05:30:00";
            Persistent = true;
          };
        })
      containers;

      assertions = [
        {
          assertion = !has-duplicates (lib.concatMap (c: map get-host-port c.ports) (lib.attrValues containers));
          message = "oci-containers: duplicate host ports";
        }
        {
          assertion = !has-duplicates (map get-container-port (containers.gluetun.ports or []));
          message = "oci-containers: duplicate container ports behind gluetun";
        }
      ];
    };
  };
}
