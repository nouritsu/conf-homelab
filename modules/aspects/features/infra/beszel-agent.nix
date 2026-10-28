{den, ...}: {
  # a beszel agent alone, reporting to the homelab's hub
  den.aspects.beszel-agent.nixos = {config, ...}: {
    sops.secrets."beszel/token" = {};
    sops.secrets."beszel/key".sopsFile = den.lib.homelab.shared-secrets;

    sops.templates."beszel.env".content = ''
      HUB_URL="https://${den.lib.homelab.fqdn "monitor"}"
      KEY="${config.sops.placeholder."beszel/key"}"
      TOKEN="${config.sops.placeholder."beszel/token"}"
    '';

    services.beszel.agent = {
      enable = true;
      environmentFile = config.sops.templates."beszel.env".path;
      openFirewall = true;
    };
  };
}
