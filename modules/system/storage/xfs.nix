{pkgs, ...}: {
  boot.kernelModules = ["xfs"];
  boot.supportedFilesystems = ["xfs"];

  environment.systemPackages = with pkgs; [
    libxfs
    xfsprogs
  ];

  boot.kernel.sysctl = {
    "vm.max_map_count" = 262144;
  };
}
