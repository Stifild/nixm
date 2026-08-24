{ pkgs, ... }:
{
  users.mutableUsers = true;

  users.users.stifild = {
    isNormalUser = true;
    description = "stifild";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.fish;
    # Временный пароль — смените сразу после первого входа: passwd
    # Для полностью декларативного варианта замените на hashedPassword
    # (сгенерировать: mkpasswd -m sha-512).
    initialPassword = "changeme";
  };

  users.users.user = {
    isNormalUser = true;
    description = "user";
    extraGroups = [ "networkmanager" ];
    shell = pkgs.fish;
    # Пароль намеренно не задан — вход без пароля через автологин ниже
  };

  # Автологин под user. Учётка stifild — через переключение пользователя
  # на экране дисплей-менеджера (там уже потребуется пароль).
  services.displayManager.autoLogin = {
    enable = true;
    user = "user";
  };
}
