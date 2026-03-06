{lib, ...}: let
  local_pkg = pkg: ../../../pkgs/${pkg}/package.nix;
in {
  nixpkgs.overlays = [
    # libcec
    (final: prev: {
      libcec = prev.libcec.override {
        withLibraspberrypi = true;
      };
    })

    # youtube-dl
    (
      final: prev: {
        youtube-dl = prev.yt-dlp;
      }
    )

    # Local pkgs/pkg/package.nix
    (
      final: _:
        lib.genAttrs [
          # jellycon # i am stupid
        ] (pkg: final.callPackage (local_pkg pkg) {})
    )
  ];
}
