{
  den.aspects.services.grocy = let
    port = 9283;
  in {
    endpoint = {
      subdomain = "chores";
      inherit port;
    };

    nixos = {
      virtualisation.oci-containers.containers.grocy = {
        image = "lscr.io/linuxserver/grocy:latest@sha256:72cadb310c024d20e2a88694eb00301af369fb3d2812cd798331708cd6a78505";
        ports = ["${toString port}:80"];
        volumes = ["/data/grocy:/config"];
      };

      systemd.tmpfiles.rules = ["d /data/grocy 0775 1000 data -"];
    };
  };
}
