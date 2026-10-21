{
  den.aspects.ssh = {
    nixos = {
      services.openssh = {
        enable = true;
        openFirewall = true;
        allowSFTP = true;
        settings = {
          PasswordAuthentication = false;
          PubkeyAuthentication = true;
          PermitRootLogin = "prohibit-password";
        };
      };
    };

    from-pc = let
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAwVvRZ6cNb1mSXehYaqGtX5EkdSb9IqKzdsXPepddhY aneesh@pc";
    in {
      user.openssh.authorizedKeys.keys = [key];
      nixos.users.users.root.openssh.authorizedKeys.keys = [key];
    };

    # not root: only pc's key gets root
    from-laptop.user.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEaijmb2WJa4WkQNoKz05gibSe/4rIohMVJtY3KSM0va ab@nouritsu.com"
    ];

    from-pixel.user.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHadN10Y/fBJFvDrH62DIIy8/jZN1mf5Mk6XOBkxdzoj aneesh@pixel"
    ];
  };
}
