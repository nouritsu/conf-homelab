# A second host that selects every service aspect, including the ones the real
# homelab does not run. Without it those aspects are never type-checked: den
# only evaluates what a host selects, so a broken deselected service would stay
# invisible until the day it is switched on.
#
# services._ is den's own aggregate over the namespace - it expands to every
# immediate child of den.aspects.services - so a service is covered here from
# the moment it is defined, with no list to remember to update.
#
#   nix eval .#nixosConfigurations.check-all.config.system.build.toplevel.drvPath
{den, ...}: {
  den.aspects.check-all = {
    includes = with den.aspects; [
      homelab
      services._
    ];

    # services.wg-easy and services.tailscale collide on this sysctl; the
    # homelab host brings tailscale in through `homelab` above, so pin it here
    # rather than dropping a service from the check
    nixos = {lib, ...}: {
      boot.kernel.sysctl."net.ipv4.ip_forward" = lib.mkForce 1;
    };
  };
}
