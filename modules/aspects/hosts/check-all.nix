# A second host that selects every service aspect, including the ones the real
# homelab does not run. Without it those aspects are never type-checked: den
# only evaluates what a host selects, so a broken deselected service would stay
# invisible until the day it is switched on. Every aspect in the tree is
# reachable from here.
#
#   nix eval .#nixosConfigurations.check-all.config.system.build.toplevel.drvPath
{den, ...}: {
  den.aspects.check-all = {
    includes = with den.aspects; [
      homelab

      srv-jellyseerr
      srv-cook-cli
      srv-uptime-kuma
      srv-grocy
      srv-roundcube
      srv-vaultwarden
      srv-aria2
      srv-immich
      srv-wg-easy
    ];

    # srv-wg-easy and srv-tailscale collide on this sysctl; the homelab host
    # brings tailscale in through `homelab` above, so pin it here rather than
    # dropping a service from the check
    nixos = {lib, ...}: {
      boot.kernel.sysctl."net.ipv4.ip_forward" = lib.mkForce 1;
    };
  };
}
