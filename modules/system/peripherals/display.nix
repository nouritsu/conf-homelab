{inputs, ...}: let
  rpinm = inputs.nixos-raspberrypi.nixosModules;
in {
  imports = [
    rpinm.raspberry-pi-5.display-vc4
  ];
}
