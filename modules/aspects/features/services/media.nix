{
  den.aspects.services.jellyseerr = {
    endpoint = {
      subdomain = "media";
      port = 5055;
    };
    # DynamicUser: /var/lib/<name> is only a symlink into /var/lib/private
    backup = {config, ...}: {
      paths = [(builtins.replaceStrings ["/var/lib/"] ["/var/lib/private/"] config.services.seerr.configDir)];
    };

    nixos.services.seerr.enable = true;
  };
}
