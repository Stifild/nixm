{ config, pkgs, ... }:
{
  services.openssh = {
    enable = true;
    openFirewall = false; # порт не открывается глобально — только через ListenAddress ниже
    extraConfig = ''
      Include /etc/ssh/sshd_config.d/*.conf
    '';
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false; # PAM тоже не должен пускать по паролю
    };
  };

  users.users.stifild.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP2yjs9nV/Jra8N2tUxQ2gXanVSjJSxoHf2WsdWDe2Yl"
  ];

  # Ждём, пока tailscaled выдаст IPv4-адрес, и кладём его как единственный ListenAddress.
  systemd.services.tailscale-sshd-listen = {
    description = "Generate sshd ListenAddress from current Tailscale IPv4";
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    before = [ "sshd.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -eu
      mkdir -p /etc/ssh/sshd_config.d
      ip=""
      for _ in $(seq 1 30); do
        ip=$(${pkgs.tailscale}/bin/tailscale ip -4 2>/dev/null || true)
        [ -n "$ip" ] && break
        sleep 1
      done
      if [ -z "$ip" ]; then
        echo "tailscale ip -4 не вернул адрес за 30с" >&2
        exit 1
      fi
      echo "ListenAddress $ip" > /etc/ssh/sshd_config.d/tailscale.conf
    '';
  };

  systemd.services.sshd = {
    after = [ "tailscale-sshd-listen.service" ];
    requires = [ "tailscale-sshd-listen.service" ];
  };
}