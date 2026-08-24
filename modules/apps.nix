{ pkgs, ... }:
{
  # Flatpak нужен для Orion Browser — его нет ни в nixpkgs, ни на Flathub,
  # только собственный бета-репозиторий Kagi.
  services.flatpak.enable = true;
  services.flatpak.remotes.orion-beta = {
    url = "https://flatpak.orionbrowser.com/repo/beta/";
  };
  xdg.portal.enable = true;

  # Приложение не ставится декларативно (нет в nixpkgs) — ставится вручную
  # flatpak install orion-beta com.kagi.Orion

  environment.systemPackages = with pkgs; [
    onlyoffice-desktopeditors
    vim
    git
    wget
    curl
  ];
}
