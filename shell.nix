{
  config,
  lib,
  ...
}: let
  with-deploy =
    lib.filterAttrs (_: h: h.deploy != null)
    (lib.concatMapAttrs (_: hosts: hosts) config.den.hosts);

  deployable = lib.filterAttrs (_: h: h.active) with-deploy;
  inactive = lib.filterAttrs (_: h: !h.active) with-deploy;

  built-here = h: h.deploy.build-host == null;

  deploy-flags = h:
    ["--target-host" h.deploy.target]
    ++ (
      if built-here h
      then ["--use-substitutes"]
      else ["--build-host" h.deploy.build-host "--option" "allow-import-from-derivation" "false"]
    );
in {
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    devShells.default = pkgs.mkShell {
      packages = let
        # Evaluation runs here, which can't build aarch64, so a host built
        # elsewhere refuses import-from-derivation. One built here may use it.
        #
        # --no-reexec stops nixos-rebuild building the target's own nixos-rebuild here.
        #
        # nixos-rebuild comes from PATH rather than pkgs: this only runs on a
        # NixOS machine, where it is always present and always matches the
        # system, and pinning it would add a download that can lag behind.
        deploy = pkgs.writeShellScriptBin "deploy" ''
          set -euo pipefail
          usage="usage: deploy <${lib.concatStringsSep "|" (lib.attrNames deployable)}> [action] [nixos-rebuild args]"
          host="''${1:?$usage}"
          shift
          action="''${1:-switch}"
          shift || true

          case "$host" in
          ${lib.concatStrings (lib.mapAttrsToList (name: h: ''
              ${name}) flags=(${lib.escapeShellArgs (deploy-flags h)}) ;;
            '')
            deployable)}
          ${lib.concatMapStrings (name: ''
              ${name}) echo "${name} is inactive: set active = true in modules/flake/entities.nix first" >&2; exit 1 ;;
            '')
            (lib.attrNames inactive)}
            *) echo "$usage" >&2; exit 1 ;;
          esac

          exec nixos-rebuild "$action" --flake ".#$host" --no-reexec "''${flags[@]}" "$@"
        '';

        # hosts running something other than this tree, e.g. the vps after a tunnel change on the homelab
        stale = pkgs.writeShellScriptBin "stale" ''
          set -uo pipefail
          check() {
            local host=$1 target=$2 ifd=$3 want have
            want=$(nix eval --raw ".#nixosConfigurations.$host.config.system.build.toplevel.outPath" \
              --option allow-import-from-derivation "$ifd" 2>/dev/null) || { echo "$host: does not evaluate"; return; }
            # as the user, as root would take a touch per host
            have=$(ssh -o BatchMode=yes -o ConnectTimeout=5 "''${target#root@}" readlink /run/current-system 2>/dev/null) \
              || { echo "$host: unreachable"; return; }
            if [ "$want" = "$have" ]; then echo "$host: up to date"; else echo "$host: stale, run deploy $host"; fi
          }
          ${lib.concatStrings (lib.mapAttrsToList (name: h: ''
              check ${name} ${lib.escapeShellArg h.deploy.target} ${lib.boolToString (built-here h)}
            '')
            deployable)}
        '';

        # a fresh install: disko wipes the target's disk, the age key lands where its sops looks
        provision = pkgs.writeShellScriptBin "provision" ''
          set -euo pipefail
          usage="usage: provision <host> <root@address> <age-key-file>"
          host="''${1:?$usage}"
          dest="''${2:?$usage}"
          key="''${3:?$usage}"

          keyfile=$(nix eval --raw ".#nixosConfigurations.$host.config.sops.age.keyFile")
          read -rp "this wipes every disk disko manages on $dest; type '$host' to go on: " answer
          [ "$answer" = "$host" ] || exit 1

          extra=$(mktemp -d)
          trap 'rm -rf "$extra"' EXIT
          install -D -m 400 "$key" "$extra$keyfile"

          ${lib.getExe pkgs.nixos-anywhere} --flake ".#$host" --target-host "$dest" --extra-files "$extra"
        '';
      in [
        deploy
        stale
        provision
        config.treefmt.build.wrapper
      ];

      shellHook = config.pre-commit.installationScript;
    };
  };
}
