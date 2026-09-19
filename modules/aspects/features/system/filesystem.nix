# xfsprogs and btrfs-progs arrive on their own: the nixpkgs filesystem modules
# put them in system.fsPackages, which is environment.systemPackages. Only the
# extras belong here.
{
  den.aspects.filesystem = {
    xfs.nixos = {pkgs, ...}: {
      # supportedFilesystems only reaches the initrd; this is what loads the
      # module on the running system
      boot.kernelModules = ["xfs"];
      boot.supportedFilesystems = [
        "xfs"
      ];
      environment.systemPackages = [pkgs.xfsdump];
    };

    btrfs.nixos = {pkgs, ...}: {
      boot.supportedFilesystems = [
        "btrfs"
      ];

      environment.systemPackages = [pkgs.compsize pkgs.snapper];
    };
  };
}
