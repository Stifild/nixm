{ pkgs, ... }:

let
  ns       = "hermes-egress";
  vethHost = "veth-herm0";
  vethNs   = "veth-herm1";
  hostAddr = "10.250.77.1";
  nsAddr   = "10.250.77.2";
  tsSock   = "/run/tailscale-hermes/tailscaled.sock";
  tsState  = "/var/lib/tailscale-hermes";
  exitNode = "nl-server.chameleon-dace.ts.net"; # tailscale exit-node list
in
{
  # 1. namespace + veth — только для бутстрапа tailscaled до тейлнета
  systemd.services."netns-${ns}" = {
    description = "netns для egress hermes-agent";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
    path = [ pkgs.iproute2 ];
    script = ''
      ip netns add ${ns}
      ip link add ${vethHost} type veth peer name ${vethNs} netns ${ns}
      ip addr add ${hostAddr}/30 dev ${vethHost}
      ip link set ${vethHost} up
      ip netns exec ${ns} ip addr add ${nsAddr}/30 dev ${vethNs}
      ip netns exec ${ns} ip link set ${vethNs} up
      ip netns exec ${ns} ip link set lo up
      ip netns exec ${ns} ip route add default via ${hostAddr}
      mkdir -p /etc/netns/${ns}
      echo "nameserver 100.100.100.100" > /etc/netns/${ns}/resolv.conf
    '';
    preStop = ''
      ip netns del ${ns} || true
      ip link del ${vethHost} 2>/dev/null || true
    '';
  };

  networking.nat = {
    enable = true;
    internalInterfaces = [ vethHost ];
  };

  # 2. отдельный tailscaled внутри namespace
  systemd.services.tailscaled-hermes = {
    description = "Приватный tailscaled для hermes-agent (netns ${ns})";
    after = [ "netns-${ns}.service" ];
    bindsTo = [ "netns-${ns}.service" ]; # упадёт netns — упадёт и это
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      NetworkNamespacePath = "/var/run/netns/${ns}";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${tsState} /run/tailscale-hermes";
      ExecStart = "${pkgs.tailscale}/bin/tailscaled --state=${tsState}/tailscaled.state --socket=${tsSock} --tun=tshermes0 --port=0";
      Restart = "on-failure";
    };
  };

  # 3. join тейлнета + выбор exit node
  systemd.services.tailscale-hermes-up = {
    description = "tailscale up --exit-node для netns ${ns}";
    after = [ "tailscaled-hermes.service" ];
    bindsTo = [ "tailscaled-hermes.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      EnvironmentFile = "${tsState}/authkey.env"; # TS_AUTHKEY=tskey-auth-...
    };
    script = ''
      ${pkgs.tailscale}/bin/tailscale --socket=${tsSock} up \
        --authkey=$TS_AUTHKEY \
        --exit-node=${exitNode} \
        --exit-node-allow-lan-access=false \
        --accept-dns=true \
        --hostname=mswax-pc-hermes-egress
    '';
  };
}
