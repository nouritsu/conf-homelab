{
  den.aspects.virtualization.podman.nixos = {pkgs, ...}: {
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;

      # safe only because every image is pinned by digest
      autoPrune = {
        enable = true;
        flags = ["--all"];
      };
    };

    # podman itself comes from virtualisation.podman.enable
    environment.systemPackages = [pkgs.lazydocker pkgs.docker-compose];

    users.users.aneesh.extraGroups = ["podman"];

    virtualisation.oci-containers.backend = "podman";
  };
}
