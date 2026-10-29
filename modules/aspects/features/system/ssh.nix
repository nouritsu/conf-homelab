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

    # security keys: logins beside the plain keys, sudo on a touch through the forwarded agent
    from-yubikeys = let
      keys = [
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIMnLxjqSr4eW8FTR8/VqPheLwem+4Tyk/xvg7k/YwYxIAAAADXNzaDp5dWJpa2V5LWE= aneesh@yubikey-a"
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAILNf7NQHTL6oXtT5EfLaYSzUmr5ibxQnafPM4tKYxq/CAAAADXNzaDp5dWJpa2V5LWI= aneesh@yubikey-b"
      ];
    in {
      user.openssh.authorizedKeys.keys = keys;
      nixos = {
        pkgs,
        lib,
        ...
      }: {
        # only these, so a plain key in the agent can't sudo without a touch
        security.pam.rssh = {
          enable = true;
          settings.auth_key_file = "${pkgs.writeText "sudo-keys" (lib.concatLines keys)}";
        };
        security.pam.services.sudo.rssh = true;
      };
    };
  };
}
