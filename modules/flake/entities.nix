{inputs, ...}: let
  # nixos-raspberrypi's nixosSystem injects `nixos-raspberrypi` into specialArgs
  # itself, and every module here that wants `inputs` takes it at the flake
  # level, so this is the plain constructor.
  rpi = inputs.nixos-raspberrypi.lib.nixosSystem;
in {
  den.hosts.aarch64-linux.homelab = {
    instantiate = rpi;
    users.aneesh = {};
    tunnels-via = "vps";

    # the Pi builds its own system; root@ for both, as activation needs root
    deploy = {
      target = "root@homelab";
      build-host = "root@homelab";
    };
  };

  den.hosts.x86_64-linux.vps = {
    users.aneesh = {};
    deploy.target = "root@nouritsu.com";
  };

  # the game server's box is gone; kept so it is evaluated and can be provisioned again
  den.hosts.x86_64-linux.nenya = {
    active = false;
    users.aneesh = {};
    deploy.target = "root@82.26.94.225";
  };

  # the user has to be declared on this host too: check-all selects the homelab
  # aspect, not the homelab entity, so it does not inherit its users
  den.hosts.aarch64-linux.check-all = {
    instantiate = rpi;
    users.aneesh = {};
  };

  den.hosts.x86_64-linux.check-games = {
    users.aneesh = {};
  };
}
