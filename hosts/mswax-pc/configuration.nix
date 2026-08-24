{ ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "mswax-pc";

  system.stateVersion = "26.05"; #DONT CHANGE IT!
}
