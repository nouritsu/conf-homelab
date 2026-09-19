{inputs, ...}: let
  # nixos-raspberrypi's nixosSystem injects `nixos-raspberrypi` into specialArgs
  # itself, and every module here that wants `inputs` takes it at the flake
  # level, so this is the plain constructor.
  rpi = inputs.nixos-raspberrypi.lib.nixosSystem;
in {
  den.hosts.aarch64-linux.homelab = {
    instantiate = rpi;
    users.aneesh = {};
  };

  # the user has to be declared on this host too: check-all selects the homelab
  # aspect, not the homelab entity, so it does not inherit its users
  den.hosts.aarch64-linux.check-all = {
    instantiate = rpi;
    users.aneesh = {};
  };
}
