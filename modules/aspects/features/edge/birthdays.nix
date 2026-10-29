{den, ...}: {
  # the homelab's birthday feed, through its rathole tunnel, at cal.nouritsu.com/<token>/birthdays.ics
  den.aspects.edge.birthdays.nixos = {
    tunnel,
    lib,
    ...
  }: let
    feed =
      lib.findSingle (e: e.subdomain == "birthdays")
      (throw "edge.birthdays: no host tunnels a birthdays endpoint here")
      (throw "edge.birthdays: more than one birthdays tunnel")
      tunnel;
  in {
    # cn-calsync's endpoint owns cal; a second endpoint would claim the same domain
    services.caddy.virtualHosts.${den.lib.homelab.fqdn "cal"}.extraConfig = ''
      handle /*/birthdays.ics {
        # deferred, so it replaces the homelab's and cn-calsync's rather than joining them
        header >Content-Type "text/calendar; charset=utf-8"
        reverse_proxy localhost:${toString feed.port}
      }
    '';
  };
}
