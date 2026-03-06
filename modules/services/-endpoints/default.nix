{
  imports = [
    ./options.nix
  ];

  services.caddy.enable = true;
  networking.firewall.allowedTCPPorts = [80 443];
}
