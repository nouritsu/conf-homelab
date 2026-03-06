{
  perSystem = {pkgs, ...}: {
    devShells.default = pkgs.mkShell {
      packages = let
        sync = pkgs.writeShellScriptBin "sync" ''
          ${pkgs.rsync}/bin/rsync -avz --delete \
            --exclude '.git' \
            --exclude 'result' \
            ./ aneesh@homelab:/home/aneesh/.config/nixos/
          exec ssh aneesh@homelab
        '';
      in [
        sync
      ];
    };
  };
}
