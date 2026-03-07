{
  flake.nixosModules.user-aneesh = {...}: {
    users.users.aneesh = {
      isNormalUser = true;
      extraGroups = ["wheel" "networkmanager" "data"];
      hashedPassword = "$y$j9T$odcs/fuEl8Uu64TARclW4/$Qpn25VL0k9ZbhnT20JohsIad2W3BQO8OdffUjc.NkX0";
    };
  };
}
