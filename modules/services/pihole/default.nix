{pkgs, ...}: {
  my.endpoints.pihole.port = 8081;

  imports = [
    ./blocklist.nix
    ./core.nix
    ./ip.nix
    ./resolved.nix
    ./web.nix
  ];

  environment.systemPackages = [pkgs.pihole-ftl];

  services.pihole-ftl = {
    enable = true;
    openFirewallDNS = true;
    openFirewallWebserver = true;
    useDnsmasqConfig = true;
  };
}
