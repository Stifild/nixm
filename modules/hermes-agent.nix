{ ... }:
{
  services.hermes-agent = {
    enable = true;
    settings.model.default = "anthropic/claude-sonnet-4"; # свой провайдер/модель
    environmentFiles = [ "/var/lib/hermes/env" ];
    addToSystemPackages = true;
    extraDependencyGroups = [ "messaging" ]; # адаптер телеграма

    backend = {
      mode = "dashboard";  # веб-панель + gateway в одном процессе
      host = "100.74.132.126";  # tailscale IP хоста (tailscale ip -4)
      port = 9119;
    };
  };
  systemd.services.hermes-agent = {
    after = [ "tailscale-hermes-up.service" ];
    bindsTo = [ "tailscale-hermes-up.service" ]; # нет exit node — сервис не работает, а не утекает мимо
    serviceConfig.NetworkNamespacePath = "/var/run/netns/hermes-egress";
  };
}
