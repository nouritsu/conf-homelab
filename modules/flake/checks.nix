# A second host that selects every service aspect, including the ones the real
# homelab does not run. Without it those aspects are never type-checked: den
# only evaluates what a host selects, so a broken deselected service would stay
# invisible until the day it is switched on.
#
#   nix eval .#nixosConfigurations.check-all.config.system.build.toplevel.drvPath
#
# srv-tailscale is left out on purpose - it and srv-wg-easy both define
# boot.kernel.sysctl."net.ipv4.ip_forward", so they cannot share a host. The
# real homelab host covers srv-tailscale.
{inputs, ...}: {
  den.hosts.aarch64-linux.check-all.instantiate = args:
    inputs.nixos-raspberrypi.lib.nixosSystem (args
      // {
        specialArgs = (args.specialArgs or {}) // {inherit inputs;};
      });
}
