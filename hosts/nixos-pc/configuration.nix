{ ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "nixos-pc";

  system.stateVersion = "25.11"; # НЕ меняйте после первой установки
}
