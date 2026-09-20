{ config, pkgs, lib, ... }:

let
  # Собираем llama-cpp с CUDA явно через override
  llama-cpp-gpu = pkgs.llama-cpp.override {
    cudaSupport = true;
    cudaCapabilities = [ "8.6" ];   # RTX 3060 = Ampere
    cudaForwardCompat = false;
  };
in
{
  # ===== HERMES AGENT =====
  services.hermes-agent = {
    enable = true;
    
    settings = {
      providers = {
        local = {
          type = "openai";
          base_url = "http://10.250.77.1:8080/v1";
          default_model = "ornith-9b";
          context_length = 64000;
        };
        nous.enabled = false;
        openrouter.enabled = false;
      };
      
      model = {
        provider = "local";
        default = "ornith-9b";
        context_length = 64000;
      };
      
      auxiliary.enabled = false;
    };
    
    environmentFiles = [ "/var/lib/hermes/env" ];
    addToSystemPackages = true;
    extraDependencyGroups = [ "messaging" ];
  };

  # ===== LLAMA-SERVER С GPU =====
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
      
      Environment = [
        "LD_LIBRARY_PATH=${lib.makeLibraryPath [
          pkgs.cudaPackages.libcublas
          pkgs.cudaPackages.cuda_cudart
          config.hardware.nvidia.package
        ]}"
      ];
      
      ExecStart = ''
        ${llama-cpp-gpu}/bin/llama-server \
          --host 10.250.77.1 \
          --port 8080 \
          --n-gpu-layers 99 \
          --ctx-size 16384 \
          --alias ornith-9b \
          --model /var/lib/hermes/models/model.gguf
      '';
    };
  };

  # ===== HERMES DASHBOARD =====
  systemd.services.hermes-dashboard = {
    description = "Hermes Agent Dashboard (Web UI)";
    after = [ "tailscale-hermes-up.service" "hermes-agent.service" ];
    bindsTo = [ "tailscale-hermes-up.service" ];
    wantedBy = [ "multi-user.target" ];
    
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
      
      ExecStart = "${config.services.hermes-agent.package}/bin/hermes dashboard --host 0.0.0.0 --port 9119 --no-open";
    };
  };
}        "LD_LIBRARY_PATH=${pkgs.cudaPackages.libcublas}/lib:${pkgs.cudaPackages.cuda_cudart}/lib"
      ];
      ExecStart = ''
        ${llama-cpp-gpu}/bin/llama-server \
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
