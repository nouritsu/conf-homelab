{config, ...}: {
  users.users.${config.my.user.alias}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAwVvRZ6cNb1mSXehYaqGtX5EkdSb9IqKzdsXPepddhY aneesh@pc"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGqz5wN1kPxbkBLyr+g1ButtOA7pY6t1OKxu5e6681cg aneesh@phone"
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICaUPFDTKQTSGFOTAzOtkGfLY93kUimERX1TcVi+WIiU aneesh@pc-enc"
  ];

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
}
