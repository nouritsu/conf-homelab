{
  den.aspects.ssh = {
    nixos = {
      services.openssh = {
        enable = true;
        openFirewall = true;
        allowSFTP = true;
        settings = {
          PasswordAuthentication = false;
          PubKeyAuthentication = true;
          PermitRootLogin = "prohibit-password";
        };
      };
    };

    # one key for both accounts, bound once so that stays true by construction:
    # root used to be reachable only by the pc-enc key, which meant two keys to
    # keep and the deploy account gated behind the one not used day to day
    from-pc.nixos = let
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAwVvRZ6cNb1mSXehYaqGtX5EkdSb9IqKzdsXPepddhY aneesh@pc";
    in {
      users.users.aneesh.openssh.authorizedKeys.keys = [key];
      users.users.root.openssh.authorizedKeys.keys = [key];
    };

    from-phone.nixos = {
      users.users.aneesh.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGqz5wN1kPxbkBLyr+g1ButtOA7pY6t1OKxu5e6681cg aneesh@phone"
      ];
    };
  };
}
