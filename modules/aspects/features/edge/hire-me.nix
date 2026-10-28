{
  den.aspects.edge.hire-me = {
    endpoint = {
      subdomain = "hire-me";
      public = true;
      extraConfig = ''
        root * /srv/hire-me/public_html
        file_server
      '';
    };

    nixos.systemd.tmpfiles.rules = [
      "d /srv/hire-me/public_html 0775 root caddy - -"
    ];
  };
}
