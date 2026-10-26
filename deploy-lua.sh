#!/usr/bin/env bash
# Install the Lua Hyprland config + caelestia configs into ~/.config.
# Rollback: ./deploy-lua.sh --rollback  (removes hyprland.lua -> Hyprland uses hyprland.conf again)
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
H=$HOME/.config/hypr
BK=$HOME/.config/hypr/.pre-lua-backup

if [[ ${1:-} == --rollback ]]; then
    rm -f "$H/hyprland.lua"
    if [[ -d $BK ]]; then cp -a "$BK/scripts/." "$H/scripts/"; cp -a "$BK/UserScripts/." "$H/UserScripts/"; fi
    echo "Rolled back. Log out/in (or: hyprctl reload full-reset), then start waybar/swaync as before."
    exit 0
fi

# keep originals of every script we overwrite
mkdir -p "$BK/scripts" "$BK/UserScripts"
for f in "$HERE"/hypr-lua/scripts/*; do
    b=$(basename "$f"); [[ -e $H/scripts/$b && ! -e $BK/scripts/$b ]] && cp -a "$H/scripts/$b" "$BK/scripts/$b"
done
for f in "$HERE"/hypr-lua/UserScripts/*; do
    b=$(basename "$f"); [[ -e $H/UserScripts/$b && ! -e $BK/UserScripts/$b ]] && cp -a "$H/UserScripts/$b" "$BK/UserScripts/$b"
done

mkdir -p "$H/lua" "$H/scheme"
cp -a "$HERE"/hypr-lua/lua/. "$H/lua/"
cp -a "$HERE"/hypr-lua/scripts/. "$H/scripts/"
cp -a "$HERE"/hypr-lua/UserScripts/. "$H/UserScripts/"
cp -a "$HERE"/hypr-lua/animations/. "$H/animations/"
cp -n "$HERE"/hypr-lua/scheme/default.lua "$H/scheme/default.lua"
[[ -e $H/scheme/current.lua ]] || cp "$H/scheme/default.lua" "$H/scheme/current.lua"

mkdir -p "$HOME/.config/fuzzel"
sed "s|\$HOME|$HOME|" "$HERE"/hypr-lua/fuzzel-clipboard.ini > "$HOME/.config/fuzzel/clipboard.ini"
[[ -e $HOME/.config/kdeglobals ]] || cp "$HERE"/kdeglobals "$HOME/.config/kdeglobals"
mkdir -p "$HOME/.local/share/color-schemes" && cp -n "$HERE"/CatppuccinMocha.colors "$HOME/.local/share/color-schemes/"
mkdir -p "$HOME/.config/caelestia"
cp -n "$HERE"/caelestia/shell.json "$HOME/.config/caelestia/shell.json" || true
cp -n "$HERE"/caelestia/cli.json "$HOME/.config/caelestia/cli.json" || true
cp "$HERE"/caelestia/session.webp "$HOME/.config/caelestia/session.webp"  # session menu sticker (paths.sessionGif)

# KDE apps (Dolphin...) follow the caelestia scheme: path unit re-renders on every scheme change
mkdir -p "$HOME/.config/systemd/user"
cp "$HERE"/systemd/caelestia-kde-colors.{path,service} "$HOME/.config/systemd/user/"
systemctl --user daemon-reload
systemctl --user enable --now caelestia-kde-colors.path
systemctl --user start caelestia-kde-colors.service || true

# VS Code follows the scheme via caelestia's own extension (theme "Caelestia")
if command -v code >/dev/null; then
    code --install-extension "$HERE"/vscode/caelestia-vscode-integration-1.2.0.vsix >/dev/null 2>&1 || true
    s=$HOME/.config/Code/User/settings.json
    if [[ -e $s ]] && ! grep -q '"workbench.colorTheme"' "$s"; then
        sed -i '0,/^{/s//{\n    "workbench.colorTheme": "Caelestia",/' "$s"
    fi
fi

# validate before activating
cp "$HERE"/hypr-lua/hyprland.lua "$H/.verify-hyprland.lua"
if Hyprland --verify-config -c "$H/.verify-hyprland.lua" 2>&1 | tee /dev/stderr | grep -q '^config ok'; then
    mv "$H/.verify-hyprland.lua" "$H/hyprland.lua"
    echo "Installed $H/hyprland.lua"
else
    rm -f "$H/.verify-hyprland.lua"
    echo "verify-config failed, hyprland.lua NOT activated" >&2
    exit 1
fi
