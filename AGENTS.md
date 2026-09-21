# AGENTS.md

NixOS flake (`nixm/`) — a single desktop host (`mswax-pc`) defined by reusable
`modules/`, plus the hermes-agent + private-tailscale-egress + GPU llama-server
services that run on it. Not a package application: there is no build/test/lint
in the app sense, only Nix syntax/format lint and per-host `nix build`.

## Layout

```
flake.nix                          # orchestrates modules + hosts via mkHost{}
modules/
  base.nix                        # systemd-boot, nix settings, TZ, locales, keymap
  shell-fish.nix                  # fish shell
  users.nix                       # stifild (admin) + user (passwordless, auto-login)
  desktop-kde.nix                 # KDE Plasma 6, ly, PipeWire, us,ru layout
  networking.nix                  # NetworkManager, Tailscale, firewall (tailscale0)
  apps.nix                        # firefox, systemPackages; Flatpak/Orion are commented out
  sshd.nix                        # sshd + dynamic Tailscale ListenAddress
  hermes-egress.nix               # netns + private tailscaled for hermes-agent egress
  hermes-agent.nix                # hermes-agent, llama-server-gpu, dashboard services
hosts/
  mswax-pc/configuration.nix      # hostname, nvidia, stateVersion
  mswax-pc/hardware-configuration.nix   # GENERATED on-box, never committed
.github/workflows/checks.yml      # CI: lint + build
```

`commonModules` (base, shell-fish, users) apply to every host; `desktopModules`
(kde, networking, apps, sshd, hermes…) are desktop-only and can be dropped for a
future headless host.

## Dev environment

- Repo root is the flake (`nixm/`); work there.
- Nix: `nix-instantiate --parse <file>` checks syntax of a single file.
  `nix fmt` is a *built-in subcommand (Nix >= 2.35)*; this box has 2.34.8, so it errors locally.
  For format-checking locally use the standalone `nixfmt` binary instead.
- Edit `.nix` via `patch`/`read_file`, not `sed`/`cat` heredocs.
- Commit over SSH only: `git@github.com:Stifild/nixm.git` (HTTPS to api.github.com is blocked here).

## Build & test (lint)

Run on CI (runner installs its own Nix); locally you can mirror each step:

```sh
# lint every .nix: syntax + format (nix fmt needs Nix >= 2.35)
while read -r f; do nix-instantiate --parse "$f" >/dev/null; done \
  < <(find . -type f -name '*.nix' -not -path './.git/*')
nix fmt --check .

# build every host configuration at once (slow first run: pulls nixpkgs + hermes-agent)
nix build --print-build-logs
```

`hardware-configuration.nix` is generated on the box and must not be hand-edited or committed.

## Adding a host

1. Create `hosts/<name>/configuration.nix` (+ generated `hardware-configuration.nix`).
2. In `flake.nix` add `mkHost { hostName = "<name>"; extraModules = desktopModules; }`
   to `nixosConfigurations` (a commented template already exists there).
3. Build: `nix build ".#<name>"` (or `nixos-rebuild switch --flake .#<name>` on-box).

## Conventions

- Module signature: prefer `{ config, pkgs, lib, ... }:`; some files use `{ ... }:` or `{ pkgs, ... }:`.
- Comments are in Russian; config keys/values stay English.
- Host dir names and service unit names are snake_case (`mswax-pc`, `netns-hermes-egress`).
- `system.stateVersion = "26.05"` is pinned in `hosts/mswax-pc/configuration.nix` — do not change it.
- Commit messages are imperative, often "Verb object: subtitle" (English or Russian).

## Pitfalls

- README is **stale**: it references a `nixos-pc/` host dir (actual name is `mswax-pc`),
  shows Flatpak/Orion as active (they're commented out in `apps.nix`), and other outdated steps.
  Ignore it — rely on `flake.nix` and the modules.
- `nix fmt` needs Nix >= 2.35; this box has 2.34.8. Use `nix-instantiate --parse` locally.
- First `nix build` is slow (5–10+ min, pulls inputs); rely on the cache afterward.
- hermes-egress bootstraps via a `netns` service; `hermes-agent` and `llama-server-gpu`
  run inside that namespace. GPU build is pinned to Ampere (`sm_86`, RTX 3060).
- SSH: password auth disabled; `sshd` listens only on the Tailscale IPv4 (written by
  `tailscale-sshd-listen` on boot), not a global port. Reach the box over Tailscale.
- `users.users.stifild.initialPassword = "changeme"` — change via `passwd` after first login.
- Model/provider live in `hermes-agent.nix` (`default_model = "ornith-9b"`, `context_length = 64000`,
  `base_url = http://127.0.0.1:8080/v1`); the dashboard listens on `:9119`.
