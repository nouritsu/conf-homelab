{
  flake.nixosModules.srv-grocy = {...}: {
    my.endpoints.grocy = {
      enable = true;
      tlsInternal = true;
      subdomain = "chores";
      port = 9283;
    };

    my.containers.grocy = {
      enable = true;

      image.provider = "lscr";

      vols = [
        "/data/grocy:/config"
      ];

      ports = [
        "9283:80"
      ];
    };

    systemd.tmpfiles.rules = ["d /data/grocy 0775 1000 data -"];
  };
}
