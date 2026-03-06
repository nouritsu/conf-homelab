{lib, ...}: let
  email_regex = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$";
in {
  options.my.system = lib.mkOption {
    type = lib.types.str;
    default = "aarch64-linux";
    description = "System architecture";
  };

  options.my.user = lib.mkOption {
    type = lib.types.submodule {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "User Full Name";
        };

        email = lib.mkOption {
          type = lib.types.strMatching email_regex;
          description = "User Email";
        };

        alias = lib.mkOption {
          type = lib.types.str;
          description = "User Alias";
        };
      };
    };
    description = "User Configuration";
  };

  options.my.net = lib.mkOption {
    type = lib.types.submodule {
      options = {
        ip = lib.mkOption {
          type = lib.types.str;
          description = "IP on Home Network";
        };

        hostname = lib.mkOption {
          type = lib.types.str;
          description = "Hostname";
        };
      };
    };
    description = "Network Configuration";
  };
}
