{ config, pkgs, ... }:
{
  services.hermes-agent = {
    enable = true;
    settings.model.default = "llama.cpp"; # свой провайдер/модель
    settings.providers.nous.enabled = false;
    settings.providers.openrouter.enabled = false;
    environmentFiles = [ "/var/lib/hermes/env" ];
    addToSystemPackages = true;
    extraDependencyGroups = [ "messaging" ]; # адаптер телеграма
  };
systemd.services.hermes-dashboard = {
    description = "Hermes Agent Dashboard (Web UI)";
    after = [ "tailscale-hermes-up.service" "hermes-agent.service" ];
    bindsTo = [ "tailscale-hermes-up.service" ];
    wantedBy = [ "multi-user.target" ];
    
    # 1. Задаем переменные окружения ПРАВИЛЬНО (на уровне сервиса, а не внутри serviceConfig)
    environment = {
      HERMES_HOME = "/var/lib/hermes/.hermes";
      HERMES_MANAGED = "true";
      HOME = "/var/lib/hermes";
    };

    serviceConfig = {
      User = "hermes";
      Group = "hermes";
      NetworkNamespacePath = "/var/run/netns/hermes-egress";
      WorkingDirectory = "/var/lib/hermes/workspace";
      ReadWritePaths = [ "/var/lib/hermes" "/var/lib/hermes/workspace" ];
      ProtectSystem = "strict";
      PrivateTmp = true;
      NoNewPrivileges = true;
      Restart = "always";
      RestartSec = 5;
      UMask = "0007";
      
      # 2. Берем бинарник прямо из пакета, который использует основной сервис
      ExecStart = "${config.services.hermes-agent.package}/bin/hermes dashboard --host 0.0.0.0 --port 9119 --no-open";
    };
  };
  systemd.services.hermes-agent = {
    after = [ "tailscale-hermes-up.service" ];
    bindsTo = [ "tailscale-hermes-up.service" ]; # нет exit node — сервис не работает, а не утекает мимо
    serviceConfig.NetworkNamespacePath = "/var/run/netns/hermes-egress";
  };
}
