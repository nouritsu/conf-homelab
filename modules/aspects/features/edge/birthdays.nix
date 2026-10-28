{den, ...}: let
  inherit (den.lib.homelab) fqdn;

  state-dir = "/var/lib/birthdays";
  # the private half is birthdays/ssh-key on the homelab
  key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGzwli18BVo5yxCb64f0N7PjMcWuMM/Qjbx46eXJDAg4 birthdays@homelab";
in {
  # the homelab's contacts' birthdays, pushed over ssh and served next to cn-calsync's feeds
  den.aspects.edge.birthdays.nixos = {
    config,
    lib,
    pkgs,
    ...
  }: let
    receive = pkgs.writeShellApplication {
      name = "birthdays-receive";
      runtimeInputs = with pkgs; [coreutils findutils gnugrep];
      text = ''
        token=$(< ${config.sops.secrets."birthdays/feed-token".path})
        if [[ ! $token =~ ^[A-Za-z0-9_-]{16,}$ ]]; then
          echo "birthdays/feed-token must be at least 16 characters of [A-Za-z0-9_-]" >&2
          exit 1
        fi

        feeds=${state-dir}/feeds
        install -d -m 0711 "$feeds/$token"
        tmp=$(mktemp -p "$feeds/$token" .birthdays.ics.XXXXXX)
        trap 'rm -f "$tmp"' EXIT

        # a few kilobytes in practice; caps what a stolen key can write
        head -c 1048576 > "$tmp"
        if ! head -n 1 "$tmp" | grep -q '^BEGIN:VCALENDAR' || ! tail -n 1 "$tmp" | grep -q '^END:VCALENDAR'; then
          echo "not a whole calendar; keeping the last one" >&2
          exit 1
        fi

        chmod 0644 "$tmp"
        mv -f "$tmp" "$feeds/$token/birthdays.ics"
        find "$feeds" -mindepth 1 -maxdepth 1 -type d ! -name "$token" -exec rm -rf {} +
      '';
    };
  in {
    sops.secrets."birthdays/feed-token".owner = "birthdays";

    users.users.birthdays = {
      isSystemUser = true;
      group = "birthdays";
      # sshd runs the forced command through the login shell
      shell = pkgs.bash;
      openssh.authorizedKeys.keys = [''restrict,command="${lib.getExe receive}" ${key}''];
    };
    users.groups.birthdays = {};

    # 0711: caddy can open the token's path, nobody can list it
    systemd.tmpfiles.rules = [
      "d ${state-dir} 0711 birthdays birthdays -"
      "d ${state-dir}/feeds 0711 birthdays birthdays -"
    ];

    # cn-calsync's endpoint owns cal; a second endpoint would claim the same domain
    services.caddy.virtualHosts.${fqdn "cal"}.extraConfig = ''
      handle /*/birthdays.ics {
        root * ${state-dir}/feeds
        header Content-Type "text/calendar; charset=utf-8"
        file_server
      }
    '';
  };
}
