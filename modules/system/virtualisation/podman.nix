{pkgs, ...}: {
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  environment.systemPackages = [pkgs.podman pkgs.lazydocker pkgs.docker-compose];

  virtualisation.oci-containers.backend = "podman";
}
