{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  environment.systemPackages = [
    pkgs.sops
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";
  };

  sops.age.keyFile = "/home/${config.my.user.alias}/.config/sops/age/keys.txt";

  sops.secrets."documenso-cert" = {
    sopsFile = ./cert.p12.enc;
    format = "binary";
    mode = "0644";
  };
}
