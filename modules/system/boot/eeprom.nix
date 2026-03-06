{pkgs, ...}: {
  environment.systemPackages = [pkgs.raspberrypi-eeprom];
}
