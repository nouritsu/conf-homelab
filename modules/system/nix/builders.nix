{
  nix.buildMachines = [
    {
      hostName = "aneesh-pc";
      systems = ["x86_64-linux" "aarch64-linux"];
      protocol = "ssh-ng";
      sshUser = "aneesh";
      maxJobs = 8;
      speedFactor = 2;
      supportedFeatures = ["nixos-test" "big-parallel" "kvm"];
    }
  ];

  nix.distributedBuilds = true;
}
