{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.homelab = inputs.nixos-raspberrypi.lib.nixosSystem {
    specialArgs = {
      inherit inputs;
      inherit (inputs) nixos-raspberrypi;
    };

    modules = with self.nixosModules;
      [
        homelab-system
        homelab-disko
        opts
      ]
      ++ [../../modules];
  };

  flake.nixosModules = {
    homelab-system = {...}: {
      my = {
        system = "aarch64-linux";
        user = {
          alias = "aneesh";
          name = "Aneesh Bhave";
          email = "aneesh1701@gmail.com";
        };

        net = {
          hostname = "homelab";
          ip = "192.168.178.128";
        };
      };

      # ================================================================ #
      # =                         DO NOT TOUCH                         = #
      # ================================================================ #
      system.stateVersion = "25.11";
    };
  };
}
