{inputs, ...}: {
  den.aspects.games.minecraft.nixos = {
    pkgs,
    lib,
    ...
  }: {
    imports = [inputs.nix-minecraft.nixosModules.minecraft-servers];
    nixpkgs.overlays = [inputs.nix-minecraft.overlay];

    services.minecraft-servers = {
      enable = true;
      eula = true;
      openFirewall = true;

      dataDir = "/data/minecraft";
      servers.forge = {
        enable = true;
        package = pkgs.forgeServers.forge-1_12_2-14_23_5_2860;

        serverProperties.white-list = true;
        whitelist = {
          nouritsu = "8c94c39e-5b9f-46ed-b5a0-94584beab7ff";
          domowhatever = "c56d45b6-6ade-4105-9b8e-fae06f580422";
        };

        jvmOpts = lib.concatStringsSep " " [
          "-Xmx6G"
          "-Xms6G"
          "-XX:+UseG1GC"
          "-XX:+UnlockExperimentalVMOptions"
          "-XX:G1NewSizePercent=30"
          "-XX:G1MaxNewSizePercent=40"
          "-XX:G1ReservePercent=20"
          "-XX:InitiatingHeapOccupancyPercent=15"
          "-XX:+ParallelRefProcEnabled"
          "-XX:+DisableExplicitGC"
          "-XX:+PerfDisableSharedMem"
          "-XX:+AlwaysPreTouch"
        ];
      };
    };
  };
}
