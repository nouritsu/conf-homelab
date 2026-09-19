{
  den.aspects.apps.core.nixos = {pkgs, ...}: {
    environment.systemPackages = [
      pkgs.git
      pkgs.helix
      pkgs.systemctl-tui
    ];
  };
}
