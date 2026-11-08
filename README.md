# Hyprland (Lua) + caelestia-shell on Fedora 44

KoolDots hyprlang config migrated to Hyprland 0.56 Lua; waybar/rofi/wofi/swaync/wlogout/swww
replaced by a locally patched [caelestia-shell](https://github.com/caelestia-dots/shell).

## Fresh machine

```bash
./install-caelestia.sh   # deps (dnf + COPR), builds quickshell/m3shapes/libcava/caelestia + patches, swappy
./deploy-lua.sh          # Lua config -> ~/.config/hypr (verify-config first), caelestia json, KDE/VS Code theming
./setup-desktop.sh       # ghostty/zsh, cursor, Dolphin, menus, overview (idempotent)
```

Then log out/in.

Dolphin uses the `plasma-integration` Qt platform theme and Fusion style so its
colours follow Caelestia without changing the global qt6ct/Kvantum settings.
Install it with `sudo dnf install --setopt=install_weak_deps=False plasma-integration`.

### Hyprland crash logs

`scripts/hyprland-log` copies each session's runtime log into the persistent system
journal, which rotates logs within journald's disk limits. The follower runs outside
Hyprland and exits after its compositor process dies; each restart gets a new follower.
After a crash or reboot: `journalctl -b -1 -t hyprland-log` (omit `-b -1` for this boot).
This requires persistent journald storage, enabled on this machine. Safe Mode skips
the user config, so its own log follower starts only after the config is loaded.
Integration check (inside a user systemd session): `bash tests/hyprland-log.sh`.

### Firefox

`caelestia-pywalfox.path` renders the scheme into `~/.cache/wal/colors.json` and runs `pywalfox update`.
One-time setup:

```bash
uv tool install pywalfox
sudo ~/.local/bin/pywalfox install --global
# Fedora's Firefox reads system manifests only from lib64; user hosts only from ~/.mozilla (not ~/.config/mozilla)
sudo mv /usr/lib/mozilla/native-messaging-hosts/pywalfox.json /usr/lib64/mozilla/native-messaging-hosts/
```

Then install the [Pywalfox](https://addons.mozilla.org/firefox/addon/pywalfox/) extension and press "Fetch Pywal colors".
Dark/light mode in the extension is switched together with the caelestia mode.

## Updating caelestia

Everything is pinned (`SHELL_REF`, `QS_REV`, `M3_REV`, `CLI_REV` in `install-caelestia.sh`), so a rebuild
always gives the same shell. To move to a newer caelestia:

```bash
./update-caelestia.sh --check   # latest main: patches apply? deps changed? QML loads?
./update-caelestia.sh           # same, then bumps the pins and runs install-caelestia.sh
./update-caelestia.sh <rev>     # a specific commit/tag
```

A patch that no longer applies stops it before anything is installed. Rollback:
`git checkout <old> -- install-caelestia.sh && ./install-caelestia.sh`.

## Layout

| Path | What |
|---|---|
| `hypr-lua/` | source of `~/.config/hypr/{hyprland.lua,lua,scripts,UserScripts,animations}` |
| `hypr/` | original KoolDots config (converter input, reference; obsolete scripts removed) |
| `patches/caelestia/` | shell patches, applied in order on every `install-caelestia.sh` run |
| `patches/swappy/` | Ctrl+Z & co. on non-latin layouts |
| `caelestia/` | `~/.config/caelestia/{shell,cli}.json` (copied only if missing) |
| `systemd/` | `caelestia-kde-colors.path`: KDE apps follow the caelestia scheme; `caelestia-pywalfox.path`: Firefox follows it via Pywalfox (see below); `10-lid-suspend.conf`: lid suspends even with external monitors; `cpu-power-limit.service`: CPU PL1 45 W / PL2 65 W at boot and after resume (shared cooler, the CPU throttled at 97-100 °C in games) (both installed by `setup-desktop.sh`) |
| `vscode/` | caelestia's VS Code extension (theme "Caelestia") |
| `dnf/` | `snapper.actions`: snapper pre/post snapshots around dnf5 transactions (installed by `setup-desktop.sh`, needs `libdnf5-plugin-actions`) |
| `zsh/` | shell setup copies: `zshrc` -> `~/.zshrc`, `extras.zsh` + `cheatsheet.txt` -> `~/.config/zsh/`, `starship.toml` -> `~/.config/`, `atuin-config.toml` -> `~/.config/atuin/config.toml`, `fastfetch-config-mini.jsonc` -> `~/.config/fastfetch/config-mini.jsonc`, `ssh-askpass-keyring` and `ssh-add-server` -> `~/.local/bin/` (ssh passwords from GNOME Keyring, asks on the tty when a host is missing) (see below) |

## Patches

1. session menu: separate suspend button (hibernate kept)
2. launcher: `drawers openLauncher <text>` IPC (prefilled `>scheme`, `>calc`, `>wallpaper`)
3. area screenshot: copy + save, notification click opens swappy
4. bar: weather entry
5. lockscreen: always shows keyboard layout
6. notification click: default action + focus the sender's window
7. area picker OCR mode (`caelestia:ocr` -> clipboard): `scripts/screen-ocr` (RapidOCR, rus+eng; venv set up by install-caelestia.sh), tesseract as a fallback
8. bar: recording indicator (REC, timer, pause, stop) + `recorder toggle|pause` IPC
9. nerd-font glyphs in `bar.workspaces.windowIcons` (window icons migrated from waybar window-rewrite)
10. tray menus show checkbox / radio state
11. bar: media entry (play/pause, wheel = next/prev) + hover popout with cover, title, progress, controls
12. cover art sticks per track (web players that resend metadata without it)
13. toasts (layout switch, battery, ...) only on the monitor focused when they appear
14. lockscreen on portrait monitors: box sized from the width, centre on top, side columns below
15. keyboard layout toast: compact, one line with the layout name
16. Firefox covers (40x40 from Yandex Music) replaced by the 600x600 cover from the Yandex Music catalogue
17. wallpaper picker (Super+W) opens on a random wallpaper instead of the current one
18. notification popups (screenshots, Telegram, sites, ...) only on the monitor focused when they appear
19. bar popouts: macOS-style safe triangle, moving diagonally to the open menu doesn't switch it to the icons on the way
20. bar popouts: input mask follows where the popout is going, so moving onto it while it slides/grows doesn't close it (upstream PR #1747)
21. lockscreen: Ctrl+U clears the password (upstream PR #2159)
22. notification popups: close button (hides the popup, keeps it in the sidebar) and a bar showing the time left
23. monitor unplug/replug: null guards for dangling screens, so the drawers layer no longer swallows every click (upstream issue #1809)
24. keyboard layout toast hides after 3 s (was 5 s, hardcoded in the plugin)
25. lockscreen: a shell restarted while the session is locked takes the lock back, no "lockscreen app died" (upstream PR #2053)
26. notifications: "clear all" rebuilds the list once, no freeze with a long history (upstream PR #2021)
27. notifications: raw HTML stripped in elided previews (popup, sidebar, lockscreen) (upstream PR #1851)
28. screen recorder: the bar timer starts once the area is picked, not while slurp is waiting
29. battery popout: no "Performance degraded / too hot" banner (tuned-ppd raises it whenever power-saver is on)
30. area picker QR mode (`caelestia:qr`, zbarimg -> clipboard; clicking the notification opens a link)
31. bar `privacy` entry: mic / camera icons while an app uses them (PipeWire capture streams, `fuser /dev/video*`)
32. notifications: null-safe `modelData` in popups, no `Cannot read property ... of null` spam (upstream PR #2009)
33. lockscreen: `pam.d/other` deny fallback, no `no default config other` in the journal (upstream PR #2111)
34. Yandex Music: "Now playing" toast once per track (waits for the metadata to settle, no repeat within the track length), cover remembered even when no cover widget is open, catalogue cover looked up when Firefox sends none
35. bar `activeWindow`: title shown only when at least 120 px are free, otherwise icon only (full title stays in the hover popout)

Outside the shell: `lua/workspace_home.lua` moves workspaces back to their monitor (rules from
`workspaces.lua`) when it is plugged in again; `lua/screenshare_dnd.lua` turns on do-not-disturb while the
screen is shared (after 2 s, so screenshots don't trigger it) and back off afterwards; `caelestia-upstream-check.timer` checks weekly whether
upstream moved and the patches still apply (`update-caelestia.sh --check --no-qml`) and notifies.

## Keys

Super+H shows every bind, grouped. New ones: Super+` Telegram scratchpad, Super+U special workspace,
Super+Shift+T OCR, Super+Alt+Q QR code, Super+Shift+R / Super+Ctrl+R record area / monitor+sound (again = stop),
Super+Ctrl+Shift+R pause.

The Caelestia menus use Super+S for web search, Super+Alt+E for emoji (select to copy),
Super+Shift+O for the zsh theme and Super+Shift+A for animations. Super+Space uses an
application picker above fullscreen windows. The Ghostty theme picker is available through
`qs -c caelestia ipc call quickmenu open ghostty`; it has no default binding. Emoji data comes
from the installed Caelestia CLI (`caelestia emoji`). Super+C, Super+V and Super+H retain
fuzzel fallbacks when their Caelestia IPC handlers are unavailable.
36. bar `gpu` entry: NVIDIA dGPU load % and temperature while it is busy (>=5 % or >=8 W); polled only while the card is runtime-active, so it is never woken
37. now-playing toast shows the track cover instead of the music note (`ToastItem` renders the `icon` as an image when it is a file/http URL; `Players` passes `getArtUrl`)
38. dashboard lyrics fallback: when LRCLIB finds nothing, `LyricList` shows plain lyrics from the Yandex Music catalogue (`Players.getLyrics`: search, then `/tracks/{id}/supplement`, no auth); untimed, so no highlight or click-to-seek
39. now-playing toast lasts 1.75 s (`Players.nowPlayingToastTimeout`) instead of the default 5 s
40. now-playing toast is compact: one line `artist - title` with a small cover, no "Now playing" title (`ToastItem.compact` also true for `music_note`/cover icons)
41. notification bodies: `<b>/<i>/<a>` converted to markdown (KDE Connect forwards Telegram titles as HTML, shown verbatim before); KDE Connect copy of a Telegram notification dropped while Telegram Desktop is running (double popups)
42. active media player: a playing one wins, then `defaultPlayer`, then local players; a phone's KDE Connect player (often paused, listed first) no longer hides the browser
43. safe triangle (19) only for tray menus and only when moving more horizontally than vertically; status-icon popouts switch instantly (moving down the bar left the old popout stuck for 300 ms)
44. area picker: only the focused monitor preselects a window, the others start fully dimmed until hovered; the selection is dropped on the monitor the cursor leaves; Escape fades the picker out on all monitors at once
45. right sidebar opens on hover over the whole right border (10px), not only its last 2px, so the cursor no longer has to slip onto the next monitor first; leaving the screen closes it even when it was opened from the outer border strip
46. quick toggles: `nightLight` (runs `Hyprsunset.sh toggle`, lit from `~/.cache/.hyprsunset_state`, so it follows Super+N and `nightlight-schedule`), replaces `wallpaperPlaying` in `shell.json`
47. bar workspaces: an occupied, unfocused workspace drops its indicator shape (window icons already mark it) and keeps only a small gap, so 8 workspaces with icons fit a 1080px vertical bar; the focused one keeps its shape
48. area picker: latch the selected crop before asynchronous capture, ignore duplicate saves, and allow retry after save failure
49. area picker: use the system drag threshold so small pointer movement during a window click does not turn it into a tiny crop or leave the selector open
50. lockscreen: unlock the GNOME login keyring with the verified password; Hyprland finishes keyring initialization before starting the shell and login lockscreen
51. network popout: open the built-in network settings beside the wireless rescan button, matching the Bluetooth popout
52. "Now playing": skip YouTube Shorts identified by the MPRIS `xesam:url` (`youtube.com/shorts/`, including `www` and `m`); music and ordinary videos keep their toasts. Missing or rewritten URLs cannot identify Shorts.
53. "Now playing": check the high-resolution cover every 100 ms (8 retries, up to 800 ms instead of 3.2 s); retain the 800 ms metadata settle delay and existing duplicate suppression.
54. "Now playing": supersede the cover wait with immediate display after metadata settles; upgrade the same toast to the catalogue cover when available, keeping its original track identity and fallback. The media popout already updates its cover through `Players.getArtUrl`.
55. "Now playing": reduce metadata debounce from 800 to 200 ms; replay of eight recorded Firefox/Yandex Music transitions produced one correct toast per track, approximately 422–493 ms after a skip. Keep duplicate suppression and progressive artwork updates.
56. area picker: hide the pointer while obtaining the frozen frame and during live captures, then show the selection crosshair; explicitly disable cursor painting as Hyprland software cursors can already be baked into screen frames.
57. "Now playing": suppress Telegram media toasts by raw player identity, including voice messages with opaque filenames; ordinary Telegram notifications remain unchanged.
58. Bluetooth popout: CMF Buds Pro 2 show separate left/right/case battery levels using a read-only RFCOMM query every 30 seconds while the popout is open. Missing levels show “—”; no battery or audio settings are written. Requires `hypr-lua/scripts/cmf-battery.py` deployed to `~/.config/hypr/scripts/`, system `python3-dbus` and `python3-gobject`. The case/right bud may omit their readings while unavailable. Protocol reference: [CMF Control](https://github.com/JScoder4005/cmf-control).

59. CMF battery popout: keep RFCOMM open while the Bluetooth menu is active; consume both replies (`0x4007`) and battery notifications (`0xE001`), including case readings sent when a bud enters/leaves the case. Poll every 30 seconds on the same connection; missing readings remain “—”. Uses the helper’s `--watch` mode.

60. CMF battery popout: show `L100% R100% C10%` in a single row instead of the connected device name and a second battery line. Hide the duplicate aggregate battery icon; retain the device name for accessibility. Other devices and disconnected CMF keep their names.

61. Utilities: single-row Keep awake and recorder cards, smaller padding and icons; recording history opens from a library button instead of always occupying space. Preserve recording modes, active timer/pause/stop controls, history actions and idle inhibition. Aquarium remains deferred.

62. SSH centered overlay: search, browse and connect to hosts from `~/.ssh/config`, or add a host with its password stored in GNOME Keyring. Requires `zsh/ssh-add-server` installed in `~/.local/bin/` and `secret-tool`.

63. Clipboard bottom overlay: search and paste cliphist entries with image previews, delete individual entries or clear history. Super+V opens the panel; Ctrl+Del deletes the selected item and Alt+Del asks to clear history.

64. Keyboard shortcuts overlay: Super+H opens a searchable, grouped list of the current Hyprland bindings, including layout-independent keycodes.

65. Caelestia quick menus: Super+S web search, Super+Alt+E emoji, Super+Shift+O zsh theme, Super+Shift+A animations, and Super+Space application search over fullscreen windows. The `quickmenu open ghostty` IPC also opens the Ghostty theme selector.

Cursor themes can be managed by the standalone [Cursor Theme Manager fork](https://github.com/Unc3rta1n/cursor-theme-manager)
checked out at `~/cursor-theme-manager`. Hyprland starts its hidden host at login to
restore the saved theme and size; open its registered application to change them.
`setup-desktop.sh` preserves a manager selection when its state file exists.

## zsh

oh-my-zsh with starship, atuin, fzf-tab, eza, bat and friends; `zh` (or F1) prints the cheatsheet of all binds and aliases.
Install the tools and plugins first:

```bash
sudo dnf install -y starship eza atuin git-delta dust duf tealdeer direnv
C=~/.oh-my-zsh/custom/plugins
git clone --depth 1 https://github.com/Aloxaf/fzf-tab $C/fzf-tab
git clone --depth 1 https://github.com/zsh-users/zsh-completions $C/zsh-completions
git clone --depth 1 https://github.com/MichaelAquilina/zsh-you-should-use $C/you-should-use
```

Then copy the files as listed in the Layout table. `.zshrc` also sources `~/.config/zsh/win.zsh` (win10 VM helpers,
not in the repo): drop that line on a machine without it.

Use Super+C to open the centered Caelestia SSH panel and add or connect to a server. Alternatively, add an SSH server with `ssh-add-server`. The command prompts for the menu name, address, user, port and password, saves the password in GNOME Keyring using `secret-tool` (libsecret), and backs up an existing SSH config before changing it. Existing entries and passwords require confirmation. Select the new host with Super+C.

## TODO

- [Аквариум в правой панели](TODO-sidebar-aquarium.md)
- [Управление CMF Buds Pro 2](TODO-cmf-controls.md)
