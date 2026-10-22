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
        image = "lscr.io/linuxserver/grocy:latest@sha256:d63bffe9afb2ef1a23fa7ce0749cdaeba9c169fb644b16eed270884a1b2f4ac9";
        ports = ["${toString port}:80"];
        volumes = ["/data/grocy:/config"];
      };

      systemd.tmpfiles.rules = ["d /data/grocy 0775 1000 data -"];
    };
  };
}
