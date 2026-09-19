{den, ...}: {
  den.aspects.aneesh = {
    includes = [
      den.batteries.primary-user
      (den.batteries.user-shell "fish")
    ];

    # the `user` class is routed into users.users.aneesh; wheel and
    # networkmanager come from primary-user, data is ours
    user = {
      extraGroups = ["data"];
      hashedPassword = "$y$j9T$odcs/fuEl8Uu64TARclW4/$Qpn25VL0k9ZbhnT20JohsIad2W3BQO8OdffUjc.NkX0";
    };
  };
}
