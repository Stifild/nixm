{ ... }:
{
  # Предполагается UEFI. Для BIOS/legacy — замените на boot.loader.grub.
  boot = {
    plymouth = {
      enable = true;
      theme = "fade-in";
    };

    # Enable "Silent boot"
    # consoleLogLevel = 3;
    # initrd.verbose = false;
    # kernelParams = [
    #   "quiet"
    #   "rd.udev.log_level=3"
    #   "rd.systemd.show_status=auto"
    # ];

    # Hide the OS choice for bootloaders.
    # It's still possible to open the bootloader list by pressing any key
    # It will just not appear on screen unless a key is pressed
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    loader.timeout = 0;
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  time.timeZone = "Europe/Moscow"; # при необходимости переопределите в hosts/<host>/configuration.nix

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings.LC_ALL = "ru_RU.UTF-8";
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" "ru_RU.UTF-8/UTF-8" ];

  console.keyMap = "us";
}
