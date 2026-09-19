{inputs, ...}: let
  # nixos-raspberrypi's nixosSystem injects `nixos-raspberrypi` into specialArgs
  # itself; `inputs` has to be added here because den passes none, and modules
  # that take it in their function header need it before `config` exists.
  rpi = args:
    inputs.nixos-raspberrypi.lib.nixosSystem (args
      // {
        specialArgs = (args.specialArgs or {}) // {inherit inputs;};
      });
in {
  den.hosts.aarch64-linux.homelab.instantiate = rpi;
  den.hosts.aarch64-linux.check-all.instantiate = rpi;
}
