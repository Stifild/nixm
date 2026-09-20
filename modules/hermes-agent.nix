{ config, pkgs, lib, ... }:

let
  llama-cpp-gpu = pkgs.llama-cpp.override {
    cudaSupport = true;
  };
in
{
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
