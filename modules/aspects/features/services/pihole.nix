{den, ...}: let
  port = 8081;
in {
  den.aspects.srv-pihole = {
    endpoint = {
      subdomain = "pihole";
      inherit port;
    };

    # also the consumer: every non-tunnelled endpoint gets a local A record
    nixos = {
      endpoint,
      pkgs,
      lib,
      ...
    }: let
      inherit (den.lib.homelab) fqdn host-ip;

      TWELVE_HOURS_SECONDS = 43200;

      local =
        lib.sort (a: b: a.subdomain < b.subdomain)
        (lib.filter (e: !(e.tunnel or false)) endpoint);
    in {
      environment.systemPackages = [pkgs.pihole-ftl];
      networking = {
        useDHCP = false;
        interfaces.end0.useDHCP = true;
        nameservers = ["127.0.0.1"];
      };
      services.resolved = {
        enable = true;
        extraConfig = ''
          DNSStubListener=no
          MulticastDNS=off
        '';
      };
      services.pihole-ftl = {
        enable = true;
        openFirewallDNS = true;
        openFirewallWebserver = true;
        useDnsmasqConfig = true;
        lists = [
          {
            url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/pro.plus.txt";
            type = "block";
            enabled = true;
            description = "Hagezi Pro Plus";
          }
        ];
        settings = {
          dns = {
            bind_hosts = [host-ip "127.0.0.1"];
            interface = "end0";
            upstreams = ["1.1.1.1" "1.0.0.1"];
            domainNeeded = true;
            expandHosts = true;
            hosts =
              [
                "192.168.178.1   gateway"
                "${host-ip}   pihole"
              ]
              ++ map (e: "${host-ip}   ${fqdn e.subdomain}") local;
          };
          dhcp.active = false;
          webserver = {
            api = {
              /*
              TODO: add passwords
              */
            };
            session.timeout = TWELVE_HOURS_SECONDS;
          };
          ntp = {
            ipv4.active = false;
            ipv6.active = false;
            sync.active = false;
          };
        };
      };
      services.pihole-web = {
        enable = true;
        ports = [port];
      };
    };
  };
}
