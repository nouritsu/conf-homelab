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

      services.jellyseerr
      services.cook-cli
      services.uptime-kuma
      services.grocy
      services.roundcube
      services.vaultwarden
      services.aria2
      services.immich
      services.wg-easy
    ];

    # services.wg-easy and services.tailscale collide on this sysctl; the
    # homelab host brings tailscale in through `homelab` above, so pin it here
    # rather than dropping a service from the check
    nixos = {lib, ...}: {
      boot.kernel.sysctl."net.ipv4.ip_forward" = lib.mkForce 1;
    };
  };
}
