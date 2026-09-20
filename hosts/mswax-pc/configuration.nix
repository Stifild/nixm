{ ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "mswax-pc";
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;
  hardware.graphics.enable = true;

  system.stateVersion = "26.05"; #DONT CHANGE IT!
}
