{
  perSystem = {pkgs, ...}: {
    devShells.default = pkgs.mkShell {
      packages = let
        # Both hosts are the Pi, and both are spelled root@ on purpose.
        #
        # nixos-rebuild multiplexes ssh over ControlPath=<tmp>/ssh-%n, and %n is
        # the hostname alone - it carries no user. Two phases aimed at one
        # hostname therefore share one socket, and the second silently rides the
        # first one's session: a root@ target behind an aneesh build phase runs
        # as aneesh and dies on `nix-env -p /nix/var/nix/profiles/system --set`
        # with "Permission denied". Agreeing on the user is what avoids that.
        #
        # Building happens on the Pi. Evaluation is local and platform-agnostic,
        # so the aarch64 system needs no emulation here.
        #
        # nixos-rebuild comes from PATH rather than pkgs: this only runs on a
        # NixOS machine, where it is always present and always matches the
        # system, and pinning it would add a download that can lag behind.
        deploy = pkgs.writeShellScriptBin "deploy" ''
          set -euo pipefail
          action="''${1:-switch}"
          shift || true
          exec nixos-rebuild "$action" \
            --flake .#homelab \
            --build-host root@homelab \
            --target-host root@homelab \
            "$@"
        '';
      in [
        deploy
      ];
    };
  };
}
