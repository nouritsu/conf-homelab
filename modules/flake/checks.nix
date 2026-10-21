{inputs, ...}: {
  imports = [
    inputs.treefmt-nix.flakeModule
    inputs.git-hooks.flakeModule
  ];

  perSystem = {config, ...}: {
    # same formatters and lints as conf-nixos' templates/base/treefmt.nix
    treefmt = {
      projectRootFile = "flake.nix";

      programs.alejandra.enable = true;
      programs.deadnix.enable = true;
      programs.nixf-diagnose.enable = true;
      programs.statix = {
        enable = true;
        # house style: inner {...}: modules, split programs.fish.* keys
        disabled-lints = ["empty_pattern" "repeated_keys"];
      };
    };

    # format at commit; the treefmt flake check already covers nix flake check
    pre-commit = {
      check.enable = false;
      settings.hooks.treefmt = {
        enable = true;
        package = config.treefmt.build.wrapper;
      };
    };
  };
}
