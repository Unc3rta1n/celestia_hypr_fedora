# Hyprland (Lua) + caelestia-shell on Fedora 44

KoolDots hyprlang config migrated to Hyprland 0.56 Lua; waybar/rofi/wofi/swaync/wlogout/swww
replaced by a locally patched [caelestia-shell](https://github.com/caelestia-dots/shell).

## Fresh machine

```bash
./install-caelestia.sh   # deps (dnf + COPR), builds quickshell/m3shapes/libcava/caelestia + patches, swappy
./deploy-lua.sh          # Lua config -> ~/.config/hypr (verify-config first), caelestia json, KDE/VS Code theming
./setup-desktop.sh       # ghostty/zsh, cursor, Dolphin, menus, overview (idempotent)
```

Then log out/in. Rollback to the hyprlang config: `./deploy-lua.sh --rollback`.

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
| `hypr/` | untouched copy of the original KoolDots config (converter input, reference) |
| `patches/caelestia/` | shell patches, applied in order on every `install-caelestia.sh` run |
| `patches/swappy/` | Ctrl+Z & co. on non-latin layouts |
| `caelestia/` | `~/.config/caelestia/{shell,cli}.json` (copied only if missing) |
| `systemd/` | `caelestia-kde-colors.path`: KDE apps follow the caelestia scheme; `caelestia-pywalfox.path`: Firefox follows it via Pywalfox (see below); `10-lid-suspend.conf`: lid suspends even with external monitors (installed by `setup-desktop.sh`) |
| `vscode/` | caelestia's VS Code extension (theme "Caelestia") |
| `dnf/` | `snapper.actions`: snapper pre/post snapshots around dnf5 transactions (installed by `setup-desktop.sh`, needs `libdnf5-plugin-actions`) |
| `zsh/` | shell setup copies: `zshrc` -> `~/.zshrc`, `extras.zsh` + `cheatsheet.txt` -> `~/.config/zsh/`, `starship.toml` -> `~/.config/`, `atuin-config.toml` -> `~/.config/atuin/config.toml`, `fastfetch-config-mini.jsonc` -> `~/.config/fastfetch/config-mini.jsonc`, `ssh-askpass-keyring` -> `~/.local/bin/` (ssh passwords from GNOME Keyring, asks on the tty when a host is missing) (see below) |

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
36. bar `gpu` entry: NVIDIA dGPU load % and temperature while it is busy (>=5 % or >=8 W); polled only while the card is runtime-active, so it is never woken
37. now-playing toast shows the track cover instead of the music note (`ToastItem` renders the `icon` as an image when it is a file/http URL; `Players` passes `getArtUrl`)
38. dashboard lyrics fallback: when LRCLIB finds nothing, `LyricList` shows plain lyrics from the Yandex Music catalogue (`Players.getLyrics`: search, then `/tracks/{id}/supplement`, no auth); untimed, so no highlight or click-to-seek
39. now-playing toast lasts 1.75 s (`Players.nowPlayingToastTimeout`) instead of the default 5 s
40. now-playing toast is compact: one line `artist - title` with a small cover, no "Now playing" title (`ToastItem.compact` also true for `music_note`/cover icons)
41. notification bodies: `<b>/<i>/<a>` converted to markdown (KDE Connect forwards Telegram titles as HTML, shown verbatim before); KDE Connect copy of a Telegram notification dropped while Telegram Desktop is running (double popups)

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
