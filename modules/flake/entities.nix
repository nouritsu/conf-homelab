{inputs, ...}: {
  den.hosts.aarch64-linux.homelab = {
    # nixos-raspberrypi's nixosSystem injects `nixos-raspberrypi` into specialArgs
    # itself; `inputs` has to be added here because den passes none, and modules
    # that take it in their function header need it before `config` exists.
    instantiate = args:
      inputs.nixos-raspberrypi.lib.nixosSystem (args
        // {
          specialArgs = (args.specialArgs or {}) // {inherit inputs;};
        });
  };
}
