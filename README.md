# NixOS flake — модульная структура

Флик с одной NixOS-конфигурацией (`mswax-pc`): повторяемые `modules/`,
собранные `flake.nix` через `mkHost`, и сервисы hermes-agent + приватного
тейлнета с GPU-llama-server, запускаемые на этом хосте.

```
flake.nix                          # оркестрация: общие модули + список хостов
modules/
  base.nix                        # загрузчик (systemd-boot), nix settings, локаль, время, раскладка клавиатуры
  shell-fish.nix                  # fish
  users.nix                       # stifild (admin) + user (без пароля, автологин)
  desktop-kde.nix                 # KDE Plasma 6, ly, PipeWire, раскладки us,ru
  networking.nix                  # NetworkManager, Tailscale, firewall (tailscale0)
  apps.nix                        # Firefox, systemPackages; Flatpak/Orion — закомментированы
  sshd.nix                        # sshd + динамический ListenAddress по Tailscale
  hermes-egress.nix               # netns + приватный tailscaled для egress hermes-agent
  hermes-agent.nix                # hermes-agent, llama-server-gpu, dashboard-сервисы
hosts/
  mswax-pc/configuration.nix      # hostname, nvidia, stateVersion
  mswax-pc/hardware-configuration.nix   # сгенерирован на месте, в репозиторий не входит
.github/workflows/checks.yml      # CI: lint .nix + сборка всех хостов
```

## Модули

`commonModules` (`base.nix`, `shell-fish.nix`, `users.nix`) накатываются на любой
хост. `desktopModules` (`desktop-kde.nix`, `networking.nix`, `apps.nix`,
`sshd.nix` и hermes-сервисы) — десктопный набор; будущий headless-хост можно
собирать из `commonModules` без него.

- `base.nix` — загрузка через systemd-boot, флаги nix, `time.timeZone = "Europe/Moscow"`,
  локали `en_US`/`ru_RU`, keymap `us`.
- `desktop-kde.nix` — KDE, дисплей-менеджер `ly`, PipeWire, автоблокировка,
  отключение сна на уровне systemd-таргетов.
- `networking.nix` — NetworkManager, Tailscale, firewall с `tailscale0` как
  доверенным интерфейсом.
- `apps.nix` — Firefox, `environment.systemPackages`; Flatpak и Orion закомментированы.
- `sshd.nix` — sshd с `PasswordAuthentication = false`; `ListenAddress` пишется
  сервисом после получения Tailscale-IPv4.
- `hermes-egress.nix` — netns + приватный `tailscaled` для egress;
  `hermes-agent` и `llama-server-gpu` запускаются внутри этого namespace.
- `hermes-agent.nix` — hermes-agent (`default_model = "ornith-9b"`,
  `context_length = 64000`), GPU-сборка llama-cpp (Ampere `sm_86`, RTX 3060),
  dashboard на `:9119`.

## Conventions

- Конфиги — на русском в комментариях, ключи и значения — на английском.
- Имена хостов и юнитов — snake_case (`mswax-pc`, `netns-hermes-egress`).
- `system.stateVersion` в `hosts/mswax-pc/configuration.nix` зафиксирована — не менять.
- CI (`checks.yml`) линтует каждый `.nix` (`nix-instantiate --parse` + `nix fmt --check`)
  и собирает все `nixosConfigurations` одной командой.
