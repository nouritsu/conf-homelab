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
