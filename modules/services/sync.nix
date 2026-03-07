{
  flake.nixosModules.srv-syncthing = {config, ...}: let
    endpoint = config.my.endpoints.syncthing;
  in {
    my.endpoints.syncthing = {
      enable = true;
      tlsInternal = true;
      port = 8384;
      subdomain = "sync";
    };
    services.syncthing = {
      enable = true;
      guiAddress = "127.0.0.1:${toString endpoint.port}";
      openDefaultPorts = true;
      settings = {
        gui = {
          user = "admin";
          password = "$2y$05$E2gP6TBFqPr9Q3KK7aCFyeXoBhPntwbGbw6GRO9et1zr2LnPqaqAy";
          insecureSkipHostCheck = true;
        };
        devices = {
          "pixel-9-pro-xl" = {
            id = "SOVMGB6-3POHJZL-XRFCGTU-VW4CCDZ-VJ6OVYV-Z4UTOIV-BYLLRYK-RQMFVQW";
            autoAcceptFolders = true;
          };
          "pc" = {
            id = "U5KKTMD-AXRIBAB-GVLY3JA-BHO42R7-HMBOBYF-SSWISQM-UQ2SCRC-3CPHXQI";
            autoAcceptFolders = true;
          };
          "iphone" = {
            id = "U7FERHJ-XOAXOGC-HQSAZCN-U443QJZ-KVSF2VU-7JJ2QAB-MOLC6F7-JHREAAC";
            autoAcceptFolders = true;
          };
        };
        folders = {
          "phone-scanned-docs" = {
            path = "/var/lib/paperless/consume";
            devices = ["pixel-9-pro-xl"];
            type = "receiveonly";
          };
          "pc-cook-cli-base" = {
            path = "/var/lib/cook-cli";
            devices = ["pc"];
            type = "receiveonly";
          };
          "homelab-cook-cli-base" = {
            path = "/var/lib/cook-cli";
            devices = ["iphone"];
            type = "sendreceive";
          };
        };
      };
    };
    systemd.services.syncthing.serviceConfig.SupplementaryGroups = ["paperless" "users" "data"];
  };
}
