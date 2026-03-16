{
  perSystem = {pkgs, ...}: {
    devShells.default = pkgs.mkShell {
      packages = let
        s = pkgs.writeShellScriptBin "s" ''
          ${pkgs.rsync}/bin/rsync -avz --delete \
            --exclude '.git' \
            --exclude 'result' \
            ./ aneesh@homelab:/home/aneesh/.config/nixos/
          exec ssh aneesh@homelab
        '';
      in [
        s
      ];
    };
  };
}
