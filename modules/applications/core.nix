{
  flake.nixosModules.app-core = {pkgs, ...}: {
    environment.systemPackages = [
      pkgs.git
      pkgs.helix
      pkgs.systemctl-tui
    ];
  };
}
