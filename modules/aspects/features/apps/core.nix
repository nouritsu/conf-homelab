{
  den.aspects.app-core.nixos = {pkgs, ...}: {
    environment.systemPackages = [
      pkgs.git
      pkgs.helix
      pkgs.systemctl-tui
    ];
  };
}
