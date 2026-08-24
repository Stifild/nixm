{ pkgs, ... }:
{
  services.flatpak = {
    enable = true;
    
    # Добавляем Orion Beta репозиторий
    remotes = [
      {
        name = "orion-beta";
        location = "https://flatpak.orionbrowser.com/repo/beta/orion-beta.flatpakrepo";
      }
    ];
    
    # Можно также добавить пакеты декларативно
    packages = [
      { appId = "org.gnome.Platform/x86_64/50"; origin = "flathub"; }
      { appId = "com.kagi.Orion"; origin = "orion-beta"; }
    ];
  };

  xdg.portal.enable = true;

  environment.systemPackages = with pkgs; [
    onlyoffice-desktopeditors
    vim
    git
    wget
    curl
  ];
}
