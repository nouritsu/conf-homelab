{
  networking = {
    useDHCP = false;

    interfaces.end0 = {
      useDHCP = true;
    };

    nameservers = ["127.0.0.1"];
  };
}
