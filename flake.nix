{
  description = "My servers: the rpi5 homelab, the vps in front of it, and a game server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

    # what the vps last ran from nixos-vps; dropped once its port is deployed
    nixpkgs-vps.url = "github:NixOS/nixpkgs/6c9a78c09ff4d6c21d0319114873508a6ec01655";
    headplane = {
      url = "github:tale/headplane/dfda629b12e50a555886902d9e4bd94753e1993a";
      inputs.nixpkgs.follows = "nixpkgs-vps";
    };

    # upstream nix-minecraft has no forge servers
    nix-minecraft = {
      url = "github:hustlerone/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    den.url = "github:denful/den";

    # nixos-raspberrypi pins the nixpkgs that actually builds the system; disko
    # only exposes plain NixOS modules, which take pkgs from the host, so its
    # own nixpkgs was dead weight in the lock.
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # its own nixpkgs is what cache.thalheim.io built sops-install-secrets against
    sops-nix.url = "github:Mic92/sops-nix";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # shell tools carry their config, as on pc; wrapped with the host's pkgs
    wrappers = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Theming
    nix-colors.url = "github:misterio77/nix-colors";
    # parsed at eval time; no catppuccin/nix for three theme files
    catppuccin-btop = {
      url = "github:catppuccin/btop";
      flake = false;
    };
    catppuccin-starship = {
      url = "github:catppuccin/starship";
      flake = false;
    };
    catppuccin-television = {
      url = "github:catppuccin/television";
      flake = false;
    };
  };

  outputs = inputs @ {
    flake-parts,
    import-tree,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      # `systems` is set by den, from `den.systems` in modules/flake/den.nix
      imports = [
        (import-tree ./modules)
        ./shell.nix
      ];
    };
}
