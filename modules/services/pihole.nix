{...}: {
  flake.nixosModules.srv-pihole = {
    pkgs,
    config,
    ...
  }: let
    TWELVE_HOURS_SECONDS = 43200;
  in {
    my.endpoints.pihole = {
      enable = true;
      port = 8081;
      subdomain = "pihole";
    };
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
          bind_hosts = ["192.168.178.128" "127.0.0.1"];
          interface = "end0";
          upstreams = ["1.1.1.1" "1.0.0.1"];
          domainNeeded = true;
          expandHosts = true;
          hosts = [
            "192.168.178.1   gateway"
            "192.168.178.128   pihole"
          ];
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
      ports = [config.my.endpoints.pihole.port];
    };
  };
}
