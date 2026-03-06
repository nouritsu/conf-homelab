{
  my = let
    alias = "aneesh";
  in {
    system = "aarch64-linux";
    user = {
      inherit alias;
      name = "Aneesh Bhave";
      email = "aneesh1701@gmail.com";
    };

    net = {
      hostname = "homelab";
      ip = "192.168.178.128";
    };

    # dirs = {
    #   media = "/home/${alias}/hdd/media";
    #   download = "/home/${alias}/hdd/downloads";
    # };
  };

  # ================================================================ #
  # =                         DO NOT TOUCH                         = #
  # ================================================================ #
  system.stateVersion = "25.11";
}
