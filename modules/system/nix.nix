{
  flake.nixosModules = {
    nixpkgs-unfree = {...}: {
      nixpkgs.config.allowUnfree = true;
    };

    nix-base = {...}: {
      programs.nix-ld.enable = true;
      nix.settings.trusted-users = ["root" "@wheel"];
      nix.settings.experimental-features = ["nix-command" "flakes"];
    };

    nix-cache = {...}: {
      nix.settings = {
        substituters = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
          "https://nixos-raspberrypi.cachix.org"
        ];

        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
        ];
      };
    };
  };
}
