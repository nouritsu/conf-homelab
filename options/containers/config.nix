{
  flake.nixosModules.opts-containers = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.my.containers;

    enabled-containers = lib.filterAttrs (_: c: c.enable) cfg;
    vpn-containers = lib.filterAttrs (_: c: c.vpn) enabled-containers;
    direct-containers = lib.filterAttrs (_: c: !c.vpn) enabled-containers;
    restart-containers = lib.filterAttrs (_: c: c.restart.enable) enabled-containers;
    backend = config.virtualisation.oci-containers.backend;

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

    mk-container = name: container: {
      image = container.image.url;

      dependsOn = lib.optionals container.vpn ["gluetun"];

      extraOptions =
        container.extra-options
        ++ [
          "--group-add=${toString config.users.groups.data.gid}"
        ]
        ++ lib.optionals container.dri-passthrough [
          "--device=/dev/dri:/dev/dri"
        ]
        ++ lib.optionals container.vpn [
          "--network=container:gluetun"
        ];

      # vpn container port config at end
      ports = lib.optionals (!container.vpn) container.ports;

      environmentFiles = container.envFile;

      environment =
        {
          TZ = container.timezone;
        }
        // lib.optionalAttrs (container.image.provider == "lscr") {
          PUID = "1000";
          PGID = toString config.users.groups.data.gid;
        }
        // lib.optionalAttrs container.theme.enable (
          {
            DOCKER_MODS = container.theme.url;
            TP_THEME = container.theme.theme-name;
          }
          // lib.optionalAttrs container.theme.is-community-theme {
            TP_COMMUNITY_THEME = "true";
          }
        )
        // container.env;

      devices = container.devices;

      volumes = container.vols;
    };
  in {
    config = lib.mkIf (enabled-containers != {}) {
      assertions = [
        {
          assertion = !has-duplicates (lib.concatMap (c: map get-host-port c.ports) (lib.attrValues direct-containers));
          message = "my.containers: duplicate host ports among non-VPN containers";
        }
        {
          assertion = !has-duplicates (lib.concatMap (c: map get-host-port c.ports) (lib.attrValues vpn-containers));
          message = "my.containers: duplicate host ports among VPN containers (exposed via gluetun)";
        }
        {
          assertion = !has-duplicates (lib.concatMap (c: map get-container-port c.ports) (lib.attrValues vpn-containers));
          message = "my.containers: duplicate container ports among VPN containers (exposed via gluetun)";
        }
      ];

      systemd.services = lib.mapAttrs' (name: _:
        lib.nameValuePair "restart-container-${name}" {
          description = "Scheduled restart of ${name} container";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.systemd}/bin/systemctl restart ${backend}-${name}.service";
          };
        }
      ) restart-containers;

      systemd.timers = lib.mapAttrs' (name: container:
        lib.nameValuePair "restart-container-${name}" {
          wantedBy = ["timers.target"];
          description = "Daily restart timer for ${name} container";
          timerConfig = {
            OnCalendar = container.restart.schedule;
            Persistent = true;
          };
        }
      ) restart-containers;

      virtualisation.oci-containers.containers = lib.mkMerge [
        (lib.mapAttrs mk-container enabled-containers)
        (lib.mkIf (vpn-containers != {}) {
          gluetun.ports = lib.mkAfter (lib.concatMap (c: c.ports) (lib.attrValues vpn-containers));
        })
      ];
    };
  };
}
