{ ... }:
{
  services.xserver.xkb = {
    layout = "us,ru";
    options = "grp:alt_shift_toggle";
  };

  security.rtkit.enable = true;
  networking.networkmanager.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  # 1. Настройки энергосбережения KDE (только AC — работа от сети)
  environment.etc."xdg/powermanagementprofilesrc".text = ''
    [AC]
    icon=ac-adapter

    [AC][DimDisplay]
    idleTime=300
    value=30

    [AC][DPMSControl]
    idleTime=600
    lockBeforeTurnOff=60

    [AC][HandleButtonEvents]
    # Кнопка питания: 32 = выключение (стандартное поведение)
    powerDownAction=32
    powerUpAction=1

    [AC][SuspendSession]
    # ПК НЕ уходит в сон — только гаснет экран
    idleTime=0
    suspendType=0
    suspendThenHibernate=false
  '';

  # 2. Автоблокировка экрана
  environment.etc."xdg/kscreenlockerrc".text = ''
    [Daemon]
    Autolock=true
    LockGrace=30
    Timeout=600
  '';

  # 3. Запрещаем systemd уводить систему в сон на уровне ядра
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
  services.desktopManager.plasma6.enable = true;
  services.displayManager.ly.enable = true;
}
