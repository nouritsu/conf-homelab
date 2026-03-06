{
  lib,
  pkgs,
  ...
}: let
  openrgb = lib.getExe pkgs.openrgb;
in {
  environment.systemPackages = [pkgs.openrgb];
  services.udev.packages = [pkgs.openrgb];

  systemd.services.openrgb-server = {
    description = "OpenRGB SDK Server";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    serviceConfig = {
      ExecStart = "${openrgb} --server --server-port 6742";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  boot.kernelModules = ["i2c-dev"];

  networking.firewall.allowedTCPPorts = [6742];
}
