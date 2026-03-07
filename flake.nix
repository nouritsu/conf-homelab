{
  description = "My rpi5 homelab configuration";

  inputs = {
    # Nix
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    # Other
    disko.url = "github:nix-community/disko";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = inputs @ {
    flake-parts,
    import-tree,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux"];

      imports = [
        (import-tree ./options)
        (import-tree ./hosts)
        (import-tree ./modules)
        ./shell.nix
      ];
    };
}
