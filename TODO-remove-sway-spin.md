# Убрать Fedora Sway spin

Ничего из этого не сделано. Команды с sudo запускает пользователь.

## Что держит sway

- `fedora-release-sway` и `fedora-release-identity-sway` красят `os-release` ("44 (Sway)") и через
  `/etc/dnf/protected.d/fedora-sway.conf` защищают `sway` от удаления. Пока они стоят,
  `dnf5 remove sway` падает с "removing protected packages: sway".
- `sway-config-fedora` требует `waybar`, поэтому `waybar` не удалить отдельно.
- `grimshot` требует `sway`.
- Greeter у SDDM работает на sway: `/usr/lib/sddm/sddm.conf.d/wayland-sway.conf` из `sddm-wayland-sway`
  (`CompositorCommand=/usr/libexec/sddm-compositor-sway`, тема `03-sway-fedora`).
  Без замены экран логина не поднимется. Автологин в `hyprland` настроен в
  `/etc/sddm.conf.d/hyprland.conf` (`Relogin=true`), поэтому при обычной загрузке greeter не нужен,
  но после logout он понадобится.

## Порядок

```bash
# 1. Замена greeter'а (тянет weston)
sudo dnf5 install -y sddm-wayland-generic

# 2. Сменить вариант на нейтральный (os-release станет "Fedora Linux" без "(Sway)")
sudo dnf5 install -y --allowerasing fedora-release-identity-basic fedora-release-server

# 3. Убрать sway-стек вместе с waybar
sudo dnf5 remove -y sway sway-config-fedora sway-systemd swaybg swayidle swaylock-effects \
  sddm-wayland-sway grimshot waybar
```

## Проверено dry-run'ом

- Шаг 2: ставит 2 пакета, заменяет 2, удаляет `fedora-release-identity-sway`, откатывает
  `fedora-release-common` с 44-18 до 44-17 (подтянется следующим обновлением).
- Шаг 3 целиком не прогонялся: без шага 2 он упирается в защиту `sway`. Перед подтверждением смотреть
  список пакетов, который покажет `dnf5`.
- `fedora-release-server` взят как самый нейтральный вариант без десктопа. Пресеты уже
  стоящих сервисов он не меняет.

## После

- Перед перезагрузкой: `ls /usr/lib/sddm/sddm.conf.d/` должен показать конфиг generic и не показать
  `wayland-sway.conf`. Если sway-конфиг остался, greeter не стартует.
- Можно удалить `~/.config/{sway,swayidle,swaylock}`. Их я не трогал.
- Hyprland использует `hypridle` и `hyprlock`, а не `swayidle` и `swaylock`. В репозитории
  ссылок на пакеты sway нет.
