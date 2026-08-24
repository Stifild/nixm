{ ... }:
{
  services.xserver.xkb = {
    layout = "us,ru";
    options = "grp:alt_shift_toggle";
  };

  security.rtkit.enable = true;
  networking.networkmanager.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  services.desktopManager.plasma6.enable = true;
  services.displayManager.ly.enable = true;
}
