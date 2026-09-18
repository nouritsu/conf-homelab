{
  den.aspects.virt-podman.nixos = {pkgs, ...}: {
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
    };

    environment.systemPackages = [pkgs.podman pkgs.lazydocker pkgs.docker-compose];

    systemd.sockets.podman.enable = true;
    users.users.aneesh.extraGroups = ["podman"];

    virtualisation.oci-containers.backend = "podman";
  };
}
