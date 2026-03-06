{self, ...}: {
  flake.nixosModules.opts = {lib, ...}: let
    inherit (lib) mkOption types;
  in {
    imports = with self.nixosModules; [
      opts-endpoints
      opts-containers
    ];

    options.my.system = mkOption {
      type = types.str;
      default = "aarch64-linux";
      description = "System architecture";
    };

    options.my.user = mkOption {
      type = types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "User Full Name";
          };

          email = let
            email_regex = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$";
          in
            mkOption {
              type = types.strMatching email_regex;
              description = "User Email";
            };

          alias = mkOption {
            type = types.str;
            description = "User Alias";
          };
        };
      };
      description = "User Configuration";
    };

    options.my.net = mkOption {
      type = types.submodule {
        options = {
          ip = mkOption {
            type = types.str;
            description = "IP on Home Network";
          };

          hostname = mkOption {
            type = types.str;
            description = "Hostname";
          };
        };
      };
      description = "Network Configuration";
    };
  };
}
