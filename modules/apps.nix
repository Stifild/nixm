{ pkgs, ... }:
{
  services.flatpak = {
    enable = true;
    
    # Добавляем Orion Beta репозиторий
    remotes = [
          {
      name = "flathub";
      location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
    }
    {
      name = "orion-beta";
      location = "https://flatpak.orionbrowser.com/orion-beta.flatpakrepo";
    }
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
