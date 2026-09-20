{ config, ... }:
{
  networking.networkmanager.enable = true;

  services.tailscale.enable = true;
  networking.firewall.trustedInterfaces = [ "tailscale0", "veth-herm0" ];
  networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];
  networking.firewall.allowedTCPPorts = [ 9119 ];
}
