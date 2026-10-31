{
  den.aspects.motd.nixos = {
    config,
    lib,
    pkgs,
    ...
  }: let
    # listed when the host runs them
    daemons = {
      SSH = "sshd";
      Fail2ban = "fail2ban";
      Caddy = "caddy";
      Rathole = "rathole";
      Headscale = "headscale";
      Postfix = "postfix";
    };
  in {
    programs.rust-motd = {
      enable = true;
      # global is the module's own
      order = ["global" "banner" "uptime" "load_avg" "memory" "filesystems" "service_status" "fail_2_ban" "last_login"];
      settings = {
        # failed units too, the containers among them
        banner = {
          color = "magenta";
          command = ''
            ${lib.getExe pkgs.figlet} -f slant "$(cat /proc/sys/kernel/hostname)"
            failed=$(systemctl list-units --state=failed --plain --no-legend | cut -d' ' -f1)
            [ -z "$failed" ] || echo failed: $failed
          '';
        };
        uptime.prefix = "Up";
        load_avg.format = "Load (1, 5, 15 min.): {one:.02}, {five:.02}, {fifteen:.02}";
        memory.swap_pos = "beside";
        # btrfs subvolumes share the root's disk
        filesystems = lib.mapAttrs' (mount: _:
          lib.nameValuePair (
            if mount == "/"
            then "root"
            else baseNameOf mount
          )
          mount)
        (lib.filterAttrs (mount: fs: mount == "/" || lib.elem fs.fsType ["xfs" "ext4"]) config.fileSystems);
        service_status = lib.filterAttrs (_: unit: config.systemd.services ? ${unit}) daemons;
        fail_2_ban.jails = ["sshd"];
        last_login = {
          aneesh = 3;
          root = 3;
        };
      };
    };
  };
}
