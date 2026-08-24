# NixOS flake — модульная структура

```
flake.nix                          # оркестрация: общие модули + список хостов
modules/
  base.nix                         # загрузчик, nix settings, локаль, время
  shell-fish.nix                   # fish
  users.nix                        # stifild (admin) + user (без пароля, автологин)
  desktop-kde.nix                  # KDE Plasma 6, ly, PipeWire, раскладки
  networking.nix                   # NetworkManager, Tailscale, firewall
  apps.nix                         # Flatpak + Orion remote, OnlyOffice
hosts/
  nixos-pc/
    configuration.nix              # специфика хоста: hostname, stateVersion
    hardware-configuration.nix     # сгенерировать на месте (см. ниже), в комплект не входит
```

`modules/base.nix`, `shell-fish.nix`, `users.nix` подключаются ко всем хостам
(`commonModules` в `flake.nix`). `desktop-kde.nix`, `networking.nix`, `apps.nix`
объединены в `desktopModules` — набор для десктопа с KDE; для будущего
headless/серверного хоста можно собрать список модулей без них.

## Установка (хост nixos-pc)
1. Скопируйте всё содержимое репозитория (flake.nix, modules/, hosts/) в `/etc/nixos/`.
2. Сгенерируйте хардварный конфиг:
   ```
   sudo nixos-generate-config --show-hardware-config > /etc/nixos/hosts/nixos-pc/hardware-configuration.nix
   ```
3. Проверьте `time.timeZone` в `modules/base.nix` и `networking.hostName` в
   `hosts/nixos-pc/configuration.nix`.
4. Соберите систему:
   ```
   sudo nixos-rebuild switch --flake /etc/nixos#nixos-pc
   ```

## Добавление нового хоста
1. Создайте `hosts/<имя>/configuration.nix` (по образцу nixos-pc) и
   `hosts/<имя>/hardware-configuration.nix`.
2. В `flake.nix` добавьте вызов `mkHost { hostName = "<имя>"; extraModules = desktopModules; }`
   в `nixosConfigurations` (пример уже закомментирован в файле).
3. `sudo nixos-rebuild switch --flake /etc/nixos#<имя>`.

## Orion Browser
Бета для Linux распространяется только через собственный flatpak-репозиторий
Kagi (не Flathub, не nixpkgs). `modules/apps.nix` включает Flatpak и сам
добавляет remote `orion-beta` при активации системы. Установка самого
приложения — разовая команда:
```
flatpak install orion-beta com.kagi.Orion
```
Обновляется через `flatpak update`, а не через nix.

## Пользователи
- `stifild` — админ (`wheel`), временный пароль `changeme`, смените: `passwd`.
  Для декларативного пароля замените `initialPassword` на `hashedPassword`
  (`mkpasswd -m sha-512`) в `modules/users.nix`.
- `user` — без пароля, автологин через ly. `stifild` — через переключение
  пользователя на экране ly.

## Tailscale
Сервис включён, подключение к тейлнету — руками: `sudo tailscale up`.
