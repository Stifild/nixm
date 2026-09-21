{
  description = "NixOS-конфигурации: общие модули + несколько хостов";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    hermes-agent.url = "github:NousResearch/hermes-agent";
    hermes-agent.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-flatpak, hermes-agent, ... }:
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
        hermes-agent.nixosModules.default
        ./modules/hermes-agent.nix
        ./modules/hermes-egress.nix
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
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;

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
