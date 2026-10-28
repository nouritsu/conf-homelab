{
  inputs,
  lib,
  ...
}: {
  den.aspects.secrets = {host, ...}: let
    owner = lib.head (lib.attrNames host.users);
  in {
    nixos = {
      pkgs,
      config,
      ...
    }: {
      imports = [inputs.sops-nix.nixosModules.sops];

      environment.systemPackages = [pkgs.sops];

      # each host aspect sets sops.defaultSopsFile to its own secrets.yaml
      sops = {
        defaultSopsFormat = "yaml";
        age.keyFile = lib.mkDefault "${config.users.users.${owner}.home}/.config/sops/age/keys.txt";

        # cached for aarch64, where the host-pkgs default compiles go on the pi
        package = inputs.sops-nix.packages.${pkgs.stdenv.hostPlatform.system}.sops-install-secrets;
      };
    };
  };
}
