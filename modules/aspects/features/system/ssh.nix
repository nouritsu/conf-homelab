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
        # root only with a security key and a touch, whatever its authorized_keys holds
        extraConfig = ''
          Match User root
            PubkeyAcceptedAlgorithms sk-ssh-ed25519@openssh.com,sk-ecdsa-sha2-nistp256@openssh.com
            PubkeyAuthOptions touch-required
          Match All
        '';
      };
    };

    from-pc.user.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAwVvRZ6cNb1mSXehYaqGtX5EkdSb9IqKzdsXPepddhY ab@nouritsu.com"
    ];

    from-laptop.user.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEaijmb2WJa4WkQNoKz05gibSe/4rIohMVJtY3KSM0va ab@nouritsu.com"
    ];

    # security keys: logins beside the plain keys, the phone's over nfc, root, and sudo on a touch through the forwarded agent
    from-yubikeys = let
      keys = [
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIMnLxjqSr4eW8FTR8/VqPheLwem+4Tyk/xvg7k/YwYxIAAAADXNzaDp5dWJpa2V5LWE= ab@nouritsu.com"
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAILNf7NQHTL6oXtT5EfLaYSzUmr5ibxQnafPM4tKYxq/CAAAADXNzaDp5dWJpa2V5LWI= ab@nouritsu.com"
      ];
    in {
      user.openssh.authorizedKeys.keys = keys;
      nixos = {
        pkgs,
        lib,
        ...
      }: {
        users.users.root.openssh.authorizedKeys.keys = keys;

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
