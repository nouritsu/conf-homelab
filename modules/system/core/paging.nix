{inputs, ...}: let
  rpinm = inputs.nixos-raspberrypi.nixosModules;
in {
  imports = [
    rpinm.raspberry-pi-5.page-size-16k
  ];
}
