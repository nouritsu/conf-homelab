{
  den.aspects.ssh = let
    # a machine's key opens both accounts. Bound once per machine so the two
    # lists cannot drift apart, and so adding a machine is one line.
    both = key: {
      users.users.aneesh.openssh.authorizedKeys.keys = [key];
      users.users.root.openssh.authorizedKeys.keys = [key];
    };
  in {
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

    from-pc.nixos = both "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAwVvRZ6cNb1mSXehYaqGtX5EkdSb9IqKzdsXPepddhY aneesh@pc";

    # the lenovo laptop
    from-laptop.nixos = both "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEaijmb2WJa4WkQNoKz05gibSe/4rIohMVJtY3KSM0va ab@nouritsu.com";
  };
}
