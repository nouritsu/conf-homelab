{
  den.aspects.virt-podman.nixos = {pkgs, ...}: {
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
    };

    # podman itself comes from virtualisation.podman.enable
    environment.systemPackages = [pkgs.lazydocker pkgs.docker-compose];

    users.users.aneesh.extraGroups = ["podman"];

    virtualisation.oci-containers.backend = "podman";
  };
}
