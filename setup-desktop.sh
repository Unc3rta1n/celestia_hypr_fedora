#!/usr/bin/env bash
# Desktop tweaks made by hand outside ~/.config/hypr during the migration. Idempotent: rerun safely.
#   ghostty / zsh colours from caelestia, Qt + KDE fonts, cursor (XCursor fallback), Dolphin defaults,
#   menus for "Open with", swaync out of the way, lid suspend when docked, workspace overview,
#   VS Code Ctrl+Shift+V paste (for clipboard.sh).
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

# set_line FILE REGEX LINE: replace the first line matching REGEX, else append LINE
set_line() {
    mkdir -p "$(dirname "$1")"; touch "$1"
    if grep -qE "$2" "$1"; then sed -i -E "0,/$2/s|$2.*|$3|" "$1"; else printf '%s\n' "$3" >>"$1"; fi
}

step "ghostty: caelestia owns the colours, new windows start in \$HOME"
g=$HOME/.config/ghostty/config
sed -i -E 's/^(theme *=)/# \1/' "$g" 2>/dev/null || true
set_line "$g" '^window-inherit-working-directory' 'window-inherit-working-directory = false'
mkdir -p "$HOME/.local/share/applications"
cp "$HERE"/com.mitchellh.ghostty.desktop "$HOME/.local/share/applications/"

step "zsh: new terminals get the current caelestia scheme"
z=$HOME/.zshrc
if ! grep -q 'caelestia/sequences.txt' "$z" 2>/dev/null; then
    cat >>"$z" <<'EOF'
# caelestia: apply the current colour scheme to new terminals (running ones are recoloured by caelestia)
[[ -o interactive && -r ~/.local/state/caelestia/sequences.txt ]] && cat ~/.local/state/caelestia/sequences.txt
EOF
fi
# zoxide's doctor wants its init to be the last thing in .zshrc
if grep -q 'zoxide init zsh' "$z" && [[ $(grep -v '^\s*\(#.*\)\?$' "$z" | tail -1) != *'zoxide init zsh'* ]]; then
    sed -i '/zoxide init zsh/d' "$z"
    printf '\n# zoxide must be initialised last (its doctor warns otherwise)\neval "$(zoxide init zsh)"\n' >>"$z"
fi

step "Qt font + icons (qt6ct): icons as in KDE apps (KoolDots' Flat-Remix theme isn't installed)"
q=$HOME/.config/qt6ct/qt6ct.conf
[[ -e $q ]] && set_line "$q" '^general=' 'general="Noto Sans,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"'
[[ -e $q ]] && set_line "$q" '^icon_theme=' 'icon_theme=breeze-dark'

step "cursor: gruvbox-light 28 everywhere (XCursor rebuilt from hyprcursor for XWayland/GTK/Electron)"
for t in "$HOME"/.icons/gruvbox-light "$HOME"/.icons/gruvbox-dark; do
    # 28 = XCURSOR_SIZE: without an exact size GTK/XWayland apps fall back to the 24px cursor
    [[ -d $t/hyprcursors ]] && python3 "$HERE"/hyprcursor2xcursor.py "$t" 28
done
mkdir -p "$HOME/.icons/default"
printf '[Icon Theme]\nInherits=gruvbox-light\n' >"$HOME/.icons/default/index.theme"
kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme gruvbox-light
kwriteconfig6 --file kcminputrc --group Mouse --key cursorSize 28
gsettings set org.gnome.desktop.interface cursor-theme gruvbox-light
gsettings set org.gnome.desktop.interface cursor-size 28

step "Dolphin: default file manager, starts in \$HOME, ghostty as terminal"
xdg-mime default org.kde.dolphin.desktop inode/directory
kwriteconfig6 --file dolphinrc --group General --key RememberOpenedTabs false
kwriteconfig6 --file dolphinrc --group General --key HomeUrl "$HOME"
# show hidden files everywhere (one global view instead of per-folder settings)
kwriteconfig6 --file dolphinrc --group General --key GlobalViewProps true
mkdir -p "$HOME/.local/share/dolphin/view_properties/global"
kwriteconfig6 --file "$HOME/.local/share/dolphin/view_properties/global/.directory" --group Settings --key HiddenFilesShown true
kwriteconfig6 --file kdeglobals --group General --key TerminalApplication "ghostty +new-window"
kwriteconfig6 --file kdeglobals --group General --key TerminalService com.mitchellh.ghostty.desktop
# KDE "Open with" lists apps from the XDG menu; outside Plasma there is none -> borrow xfce's
mkdir -p "$HOME/.config/menus"
[[ -e $HOME/.config/menus/applications.menu ]] || ln -s /etc/xdg/menus/xfce-applications.menu "$HOME/.config/menus/applications.menu"
kbuildsycoca6 >/dev/null 2>&1 || true

step "swaync: masked (it D-Bus-activates and steals caelestia's notifications)"
systemctl --user mask swaync.service 2>/dev/null || true

step "logind: lid closed -> suspend, also with external monitors (sudo)"
lid=/etc/systemd/logind.conf.d/10-lid-suspend.conf
if ! cmp -s "$HERE"/systemd/10-lid-suspend.conf "$lid"; then
    sudo install -Dm644 "$HERE"/systemd/10-lid-suspend.conf "$lid"
    sudo systemctl kill -s HUP systemd-logind  # reload config without ending the session
fi

step "workspace overview (Super+A)"
ov=$HOME/.config/quickshell/overview
[[ -d $ov/.git ]] || git clone https://github.com/Shanu-Kumawat/quickshell-overview "$ov"
git -C "$ov" checkout -q 47f0d402822b26805ed0ecea4a770c38c537b728

step "VS Code: Ctrl+Shift+V pastes in the editor too (Super+V clipboard.sh sends it for text)"
kb=$HOME/.config/Code/User/keybindings.json
if [[ -f $kb ]] && ! grep -q '"editor.action.clipboardPasteAction"' "$kb"; then
    # keybindings.json is JSONC (comments, trailing commas): insert before the closing bracket
    python3 - "$kb" <<'EOF'
import sys
p = sys.argv[1]
s = open(p).read().rstrip()
entry = '''    // Super+V (hypr clipboard.sh) pastes text into VS Code with Ctrl+Shift+V: the integrated terminal
    // already pastes with it, make the editor do the same (Markdown preview stays on Ctrl+K V)
    {
        "key": "ctrl+shift+v",
        "command": "editor.action.clipboardPasteAction",
        "when": "editorTextFocus && !terminalFocus"
    },
]'''
open(p, "w").write(s[:-1].rstrip() + "\n" + entry + "\n")
EOF
fi

echo -e "\nDone. Log out/in so cursor + env changes reach every app."
