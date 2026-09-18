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
