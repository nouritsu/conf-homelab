{den, ...}: {
  den.aspects.edge.www = {
    endpoint = {
      domain = den.lib.homelab.base-domain;
      public = true;
      extraConfig = ''
        root * /srv/www/public_html
        file_server
      '';
    };

    nixos = {
      # nouritsu/nouritsu's github actions rsync the built site in as this user
      users.users.website-deployer = {
        isNormalUser = true;
        description = "GitHub Actions Website Deployer";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGSVsYy43rdXqW5r9nris53VGBuGKkhmdooO4/IuqCnw website-deployer"
        ];
      };

      systemd.tmpfiles.rules = [
        "d /srv/www/public_html 0775 website-deployer caddy - -"
      ];
    };
  };
}
