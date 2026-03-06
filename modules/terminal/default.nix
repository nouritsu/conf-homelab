{pkgs, ...}: {
  imports = [
    ./fish.nix
    ./nh.nix
  ];

  environment.systemPackages = [
    pkgs.systemctl-tui
    pkgs.git
    pkgs.helix
  ];
}
