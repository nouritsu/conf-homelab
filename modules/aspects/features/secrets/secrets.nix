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

      sops = {
        defaultSopsFile = ./secrets.yaml;
        defaultSopsFormat = "yaml";
        age.keyFile = "${config.users.users.${owner}.home}/.config/sops/age/keys.txt";
      };

      sops.secrets."documenso-cert" = {
        sopsFile = ./cert.p12.enc;
        format = "binary";
        mode = "0644";
      };
    };
  };
}
