{ ... }:
{
  services.hermes-agent = {
    enable = true;
    gateway.enable = true;
    settings.model.default = "llama.cpp"; # свой провайдер/модель
    settings.providers.nous.enabled = false;
    settings.providers.openrouter.enabled = false;
    environmentFiles = [ "/var/lib/hermes/env" ];
    addToSystemPackages = true;
    extraDependencyGroups = [ "messaging" ]; # адаптер телеграма

    backend = {
      mode = "dashboard";  # веб-панель + gateway в одном процессе
      port = 9119;
    };
  };
  systemd.services.hermes-agent = {
    after = [ "tailscale-hermes-up.service" ];
    bindsTo = [ "tailscale-hermes-up.service" ]; # нет exit node — сервис не работает, а не утекает мимо
    serviceConfig.NetworkNamespacePath = "/var/run/netns/hermes-egress";
  };
}
