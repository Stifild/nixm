{ ... }:
{
  # Предполагается UEFI. Для BIOS/legacy — замените на boot.loader.grub.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  time.timeZone = "Europe/Amsterdam"; # при необходимости переопределите в hosts/<host>/configuration.nix

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings.LC_ALL = "ru_RU.UTF-8";
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" "ru_RU.UTF-8/UTF-8" ];

  console.keyMap = "us";
}
