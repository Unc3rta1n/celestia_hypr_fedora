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

## Layout

| Path | What |
|---|---|
| `hypr-lua/` | source of `~/.config/hypr/{hyprland.lua,lua,scripts,UserScripts,animations}` |
| `hypr/` | untouched copy of the original KoolDots config (converter input, reference) |
| `patches/caelestia/` | shell patches, applied in order on every `install-caelestia.sh` run |
| `patches/swappy/` | Ctrl+Z & co. on non-latin layouts |
| `caelestia/` | `~/.config/caelestia/{shell,cli}.json` (copied only if missing) |
| `systemd/` | `caelestia-kde-colors.path`: KDE apps follow the caelestia scheme |
| `vscode/` | caelestia's VS Code extension (theme "Caelestia") |

## Patches

1. session menu: separate suspend button (hibernate kept)
2. launcher: `drawers openLauncher <text>` IPC (prefilled `>scheme`, `>calc`, `>wallpaper`)
3. area screenshot: copy + save, notification click opens swappy
4. bar: weather entry
5. lockscreen: always shows keyboard layout
6. notification click: default action + focus the sender's window
7. area picker OCR mode (`caelestia:ocr`, tesseract rus+eng -> clipboard)
8. bar: recording indicator (REC, timer, pause, stop) + `recorder toggle|pause` IPC
9. `lyrics refresh` IPC (scripts/lyrics-fetch drops Musixmatch .lrc files, shell reloads)

## Keys

Super+H shows every bind, grouped. New ones: Super+` Telegram scratchpad, Super+U special workspace,
Super+Shift+T OCR, Super+Shift+R / Super+Ctrl+R record area / monitor+sound (again = stop),
Super+Ctrl+Shift+R pause.
