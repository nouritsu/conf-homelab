{
  services.pihole-ftl.lists = [
    {
      url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/pro.plus.txt";
      type = "block";
      enabled = true;
      description = "Hagezi Pro Plus";
    }
  ];
}
