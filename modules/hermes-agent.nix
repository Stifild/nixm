{ config, pkgs, ... }:
let
  # Кастомная сборка llama-cpp только под вашу RTX 3060
  llama-cpp-gpu = pkgs.llama-cpp.override {
    cudaSupport = true;
    # Только архитектура Ampere (RTX 30xx серия)
    cudaCapabilities = [ "8.6" ];
    cudaForwardCompat = false;  # не компилировать для будущих поколений
  };
in
{
  services.hermes-agent = {
    enable = true;
    settings = {
      # Настраиваем локальный провайдер (OpenAI-совместимый API)
      providers = {
        local = {
          type = "openai";
          base_url = "http://10.250.77.1:8080/v1";
          default_model = "ornith-9b";
          context_length = 64000;
        };
      };
      
      # Указываем, что по умолчанию использовать локальный провайдер
      model = {
        provider = "local";
        default = "ornith-9b";
        context_length = 64000;
      };
      
      # Отключаем внешние провайдеры
      providers.nous.enabled = false;
      providers.openrouter.enabled = false;
      
      # Отключаем auxiliary (вспомогательные задачи через внешние API)
      auxiliary.enabled = false;
    };
    environmentFiles = [ "/var/lib/hermes/env" ];
    addToSystemPackages = true;
    extraDependencyGroups = [ "messaging" ]; # адаптер телеграма
  };

systemd.tmpfiles.rules = [
    "d /var/lib/hermes/models 0755 hermes hermes -"
  ];

systemd.services.llama-server-gpu = {
    description = "llama.cpp GPU server for Hermes";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      User = "hermes";
      Group = "hermes";
      ReadWritePaths = [ "/var/lib/hermes" ];
      Restart = "always";
      RestartSec = 5;
      
      # ВАЖНО: слушаем на 10.250.77.1 (IP veth-интерфейса хоста)
      # Этот адрес виден из netns hermes-egress
      ExecStart = ''
        ${pkgs.llama-cpp.override { cudaSupport = true; }}/bin/llama-server \
          --host 10.250.77.1 \
          --port 8080 \
          --n-gpu-layers 99 \
          --ctx-size 16384 \
          --alias ornith-9b \
          --model /var/lib/hermes/models/model.gguf
      '';
    };
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
