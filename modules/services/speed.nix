{
  flake.nixosModules.srv-myspeed = {config, ...}: let
    endpoint = config.my.endpoints.myspeed;
  in {
    my.endpoints.myspeed = {
      port = 5216;
      subdomain = "speed";
    };
    my.containers.myspeed = {
      enable = true;
      image = {
        owner = "germannewsmaker";
        provider = "official";
      };
      ports = ["${toString endpoint.port}:5216"];
      vols = ["/data/myspeed:/myspeed/data"];
    };
    systemd.tmpfiles.rules = ["d /data/myspeed 0775 1000 data -"];
  };
}
