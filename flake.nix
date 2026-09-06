{
  description = "NixOS-конфигурации: общие модули + несколько хостов";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
  };

  outputs = { self, nixpkgs, nix-flatpak, ... }:
    let
      system = "x86_64-linux";

      # Базовые модули — накатываются на любой хост
      commonModules = [
        ./modules/base.nix
        ./modules/shell-fish.nix
        ./modules/users.nix
      ];

      # Профиль десктопа с KDE. Отдельный список, чтобы будущий сервер/headless-хост
      # мог собираться из commonModules без него.
      desktopModules = [
        ./modules/desktop-kde.nix
        ./modules/networking.nix
        ./modules/apps.nix
        ./modules/sshd.nix
        nix-flatpak.nixosModules.nix-flatpak
      ];

      mkHost = { hostName, extraModules ? [ ] }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = commonModules ++ extraModules ++ [
            ./hosts/${hostName}/configuration.nix
          ];
        };
    in
    {
      nixosConfigurations = {
        mswax-pc = mkHost {
          hostName = "mswax-pc";
          extraModules = desktopModules;
        };

        # Следующий хост добавляется так:
        # laptop = mkHost {
        #   hostName = "laptop";
        #   extraModules = desktopModules; # или свой набор
        # };
      };
    };
}
