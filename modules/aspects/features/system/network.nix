{
  # a rented vm keeps its provider's scripted dhcp
  den.aspects.network.manager.nixos.networking.networkmanager.enable = true;

  den.aspects.network.nixos = {
    networking.firewall.enable = true;

    boot.kernel.sysctl = {
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
      "net.ipv4.conf.all.log_martians" = 1;
    };
  };
}
