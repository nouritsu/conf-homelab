{
  services.resolved = {
    enable = true;
    extraConfig = ''
      DNSStubListener=no
      MulticastDNS=off
    '';
  };
}
