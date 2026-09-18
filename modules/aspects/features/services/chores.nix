{
  den.aspects.srv-grocy = let
    port = 9283;
  in {
    endpoint = {
      subdomain = "chores";
      inherit port;
    };

    nixos = {
      virtualisation.oci-containers.containers.grocy = {
        image = "lscr.io/linuxserver/grocy:latest";
        ports = ["${toString port}:80"];
        volumes = ["/data/grocy:/config"];
      };

      systemd.tmpfiles.rules = ["d /data/grocy 0775 1000 data -"];
    };
  };
}
