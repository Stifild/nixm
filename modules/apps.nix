{ pkgs, ... }:
{
  # Flatpak нужен для Orion Browser — его нет ни в nixpkgs, ни на Flathub,
  # только собственный бета-репозиторий Kagi.
  services.flatpak.enable = true;
  xdg.portal.enable = true;

  # Подключаем remote при активации системы. Само приложение это не ставит —
  # см. README: flatpak install orion-beta com.kagi.Orion
  system.activationScripts.orion-flatpak-remote = ''
    ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists orion-beta \
      https://flatpak.orionbrowser.com/orion-beta.flatpakrepo || true
  '';

  environment.systemPackages = with pkgs; [
    onlyoffice-desktopeditors
    vim
  ];
}
