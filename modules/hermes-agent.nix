{ ... }:
{
  services.hermes-agent = {
    enable = true;
    settings.model.default = "anthropic/claude-sonnet-4"; # свой провайдер/модель
    environmentFiles = [ "/var/lib/hermes/env" ];
    addToSystemPackages = true;
  };
}
