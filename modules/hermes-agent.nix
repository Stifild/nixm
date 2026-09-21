{ config, pkgs, lib, ... }:

let
  # CUDA-сборка llama-cpp, ограниченная архитектурой Ampere (sm_86 = RTX 3060)
  llama-cpp-gpu = (pkgs.llama-cpp.override {
    cudaSupport = true;
  }).overrideAttrs (old: {
    cmakeFlags = (old.cmakeFlags or []) ++ [
      "-DCMAKE_CUDA_ARCHITECTURES=86"
    ];
    # Запасной механизм: переменная окружения, которую CMake использует
    # как значение по умолчанию, если проект не задаёт архитектуры сам
    CUDAARCHS = "86";
  });
in
{
  # ===== HERMES AGENT (основной сервис) =====
  services.hermes-agent = {
    enable = true;

    settings = {
      providers = {
        local = {
          base_url = "http://127.0.0.1:8080/v1";
          default_model = "ornith-9b";
          context_length = 64000;
          api_key = "not-needed";
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
      compression.enabled = false;
      dashboard.basic_auth = {
        username      = "stifild";
        password_hash = "scrypt$16384$8$1$ihEL6GADGa7HY35YsjKqsw==$3bKD6O1FLa8qOxo2mPFOJf3JuTFwAb9zOj+chkCNtpE=";
      };
    };

    environmentFiles = [ "/var/lib/hermes/env" ];
    addToSystemPackages = true;
    extraDependencyGroups = [ "messaging" ];
  };

  # ===== ПАПКА ДЛЯ МОДЕЛЕЙ =====
  systemd.tmpfiles.rules = [
    "d /var/lib/hermes/models 0755 hermes hermes -"
  ];

  # ===== LLAMA-SERVER С GPU =====
  systemd.services.llama-server-gpu = {
  description = "llama.cpp GPU server for Hermes";
  after = [ "network-online.target" "netns-hermes-egress.service" ];
  wants = [ "network-online.target" "netns-hermes-egress.service" ];
  wantedBy = [ "multi-user.target" ];

  serviceConfig = {
    User = "hermes";
    Group = "hermes";
    ReadWritePaths = [ "/var/lib/hermes" ];
    Restart = "always";
    RestartSec = 5;
    
    # Запускаем внутри того же netns
    NetworkNamespacePath = "/var/run/netns/hermes-egress";

    ExecStart = ''
      ${llama-cpp-gpu}/bin/llama-server \
        --host 127.0.0.1 \
        --port 8080 \
        --n-gpu-layers 99 \
        --ctx-size 64000 \
        --parallel 1 \
        --cache-type-k q4_0 \
        --cache-type-v q4_0 \
        --alias ornith-9b \
        --model /var/lib/hermes/models/model.gguf
    '';
  };
};
systemd.services.hermes-agent = {
  after   = [ "tailscale-hermes-up.service" ];
  bindsTo = [ "tailscale-hermes-up.service" ];
  serviceConfig.NetworkNamespacePath = "/var/run/netns/hermes-egress";
};
  # ===== HERMES DASHBOARD (веб-интерфейс) =====
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
}
