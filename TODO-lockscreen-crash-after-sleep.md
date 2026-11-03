# Красный crash screen после выхода из сна (2026-10-27)

Дубли watcher'ов исправлены, гонка при засыпании ещё нет (см. «Что сделать»). Файл описывает, что случилось, что выяснено и что надо поправить в `hypr-lua/`.

## Что видел пользователь
Заснул ноутбук в офисе (3 монитора: eDP-1, DP-1, HDMI-A-1), проснулся дома (только eDP-1).
После пробуждения на экране красный crash screen Hyprland с подсказкой
`hyprctl --instance 0 eval 'hl.clear_crashed_lockscreen()'` и `killall -9 hyprlock`. Ни то, ни другое не помогло.

## Что выяснено
- **hyprlock в системе не используется.** `hypridle` не запущен, idle и lock делает caelestia
  (`general.idle` в `~/.config/caelestia/shell.json`, см. комментарий в `lua/autostart.lua`).
  Crash screen называет hyprlock по умолчанию, а на деле упал lockscreen caelestia (`qs -c caelestia`).
- `clear_crashed_lockscreen()` отказывал: `session is locked with a client, refusing to unlock`.
  Блокировку держал процесс `qs -c caelestia` (прожил ~9 часов, сам не падал). `killall hyprlock` убивать было нечего.
- Что помогло: `kill -9` на `qs -c caelestia`, затем `hyprctl eval 'hl.clear_crashed_lockscreen()'` (вернул `ok`).
- Параллельно пользователь ушёл на tty2 «спасаться». Из-за этого logind-сессия Hyprland (tty1) стала неактивной,
  в логе пошли `drm: Session inactive` и `Permission denied`. Это следствие, а не причина.
  Вернул экран `loginctl activate <id сессии Hyprland>` (у неё `Type=wayland`, id смотреть в `loginctl list-sessions`).
- После этого caelestia надо запустить заново: `qs -c caelestia -n -d` (или Super+Alt+R).

## Причина: caelestia завис в момент засыпания, а не после пробуждения
Лог убитого caelestia сохранился: `/run/user/1000/quickshell/by-id/9wp9or6knt/log.qslog`
(читать `qs log --log-times <файл>`, каталог пропадёт после перезагрузки).
- Последняя запись в 18:00:20.474, то есть в момент засыпания. Дальше нет ни строки, даже debug,
  хотя процесс прожил до ~23:04. `qs -c overview` после пробуждения в 22:57:29 логировал нормально,
  а caelestia на те же события мониторов промолчал. Значит, основной поток caelestia висел с 18:00:20.
- В 18:00:20 на `PrepareForSleep (true)` одновременно сработали два обработчика:
  caelestia `lockBeforeSleep` (`daemons/IdleMonitors.qml`, `onAboutToSleep` → `lock.locked = true`)
  создавал `LockSurface` на каждый экран, а `sleep-watch` в ту же миллисекунду отключал HDMI-A-1 (NVIDIA).
  В логе это видно как пачка `Tokens.sizes accessed without a screen set on LockSurface`
  и `Cannot read property ... of null` (экран исчез из-под поверхностей).
- После пробуждения клиент блокировки жив, но кадров не шлёт, поэтому Hyprland показывает crash screen,
  а `clear_crashed_lockscreen()` отказывает (`session is locked with a client`).
- Ранние засыпания в 10:10 и 11:41 прошли нормально. Вероятно, тогда экран уже был заблокирован
  по idle и новые поверхности не создавались. Это догадка, не проверено.
- Смена мониторов офис → дом (DP-1 пропал) тут ни при чём: зависание случилось раньше.
- `hyprlock` SIGABRT в 23:00:47 (coredump) получился от ручного запуска при уже заблокированной сессии. Это не причина.

## Найденная отдельная проблема: дубли sleep-watch
Запущено два `scripts/sleep-watch`:
- PID 311482, старт 10:18, PPID 1, `HYPRLAND_INSTANCE_SIGNATURE=…_689502592` (мёртвый инстанс);
- PID 368061, старт 11:47, принадлежит текущему Hyprland.

Причина: в 11:47:48 Hyprland упал (`Process 1776 (Hyprland) … signal 11/SEGV`, coredump есть), `start-hyprland` поднял его снова.
`sleep-watch` стартует из `hl.on("hyprland.start", …)` в `lua/autostart.lua` и крутится вечным циклом на `gdbus monitor`,
так что старый экземпляр не умирает с Hyprland. Новый Hyprland запускает второй.
Следы: каждая строка в `/tmp/sleep-watch.log` задвоена, `hyprctl` старого экземпляра возвращает `rc=4`.
Заодно висят два `systemd-inhibit … sleep infinity`.

## Что сделать
1. ~~Защита от дублей~~ сделано: `scripts/single-instance.sh` подключают `sleep-watch`, `power-watch`,
   `kdeconnect-watch`; у `nightlight-schedule` своя `kill_old_copies()`. При старте убивается старая копия
   вместе с потомками. Без этого остаются `gdbus monitor`, которые жили вечно, потому что GLib игнорирует SIGPIPE:
   их набралось пять штук.
2. ~~Убить старый `sleep-watch`~~ сделано (вместе с его inhibitor, сиротами `gdbus`/`udevadm` и `sleep infinity`).
3. ~~Убрать гонку при засыпании~~ сделано, ждёт проверки настоящим сном: `lockBeforeSleep: false`
   в `shell.json` (repo и live). Теперь `sleep-watch` (`lock_screen` в `before_sleep`) сначала выключает
   NVIDIA-выходы, ждёт 0.3 с, вызывает `qs -c caelestia ipc call lock lock`, ждёт 0.5 с и только потом
   отпускает inhibitor. Минус: если `sleep-watch` не запущен, блокировки перед сном не будет.
   Воспроизвести гонку на фейковом мониторе не вышло. Пробовал `hyprctl output create headless FAKE-1`
   и одновременно блокировку с `output remove` либо `hl.monitor({disabled=true})`, со сдвигами 0–100 мс:
   18 из 18 прогонов прошли без зависания. Значит, для зависания, видимо, нужны NVIDIA-выход и/или сам уход в сон.
   Проверять только настоящим засыпанием с HDMI в офисе, смотреть `lock_screen: rc=` в `~/convert_hypr_caelestia/sleep-watch.log`.
   С 2026-11-03 лог хранится там между перезагрузками; записи включают дату и часовой пояс, stderr watcher'а также сохраняется.
4. Стабилизация мониторов перед `hyprctl reload` в `after_resume` теперь под вопросом: в 22:57 набор мониторов
   был уже правильный (дома только eDP-1).
5. Отдельно разобрать падение Hyprland в 11:47 (`coredumpctl info 1776`): ему предшествовало пробуждение из сна в 11:41.

## Если повторится
1. `loginctl list-sessions` → `loginctl activate <id с Type=wayland>`, если Hyprland сидит на неактивной сессии.
2. Взять `HYPRLAND_INSTANCE_SIGNATURE` из `ls -t /run/user/1000/hypr`, затем `kill -9 $(pgrep -f 'qs -c caelestia')`
   и `hyprctl eval 'hl.clear_crashed_lockscreen()'`.
3. Запустить шелл: `qs -c caelestia -n -d`.
