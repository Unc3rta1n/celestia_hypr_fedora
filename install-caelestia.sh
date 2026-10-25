#!/usr/bin/env bash
# Build & install caelestia-shell + deps on Fedora 44.
# Everything is pinned; quickshell/m3shapes/cli follow caelestia-shell's flake.lock.
# Move to a newer caelestia with ./update-caelestia.sh (checks patches first), not by editing refs.
set -euo pipefail

QS_REV=9b0f339b19057f4731bf3b48293307d7ef241671       # quickshell
M3_REV=32ad9ce328bb77ed349b40a3be10ee9ea610b8ab       # qt6-m3shapes
CLI_REV=679af941c03f1899d017964c654f57d71cec47e5      # caelestia-cli
SHELL_REF=4b1dae84b1b3b28bf486776ba30c1c1ec74fb64d    # caelestia-shell (bump with ./update-caelestia.sh)

BUILD=${BUILD:-$HOME/.cache/caelestia-build}
mkdir -p "$BUILD"

# finished steps leave a stamp; rerun skips them (rm $BUILD/*.done to force)
done_or() { [[ -e $BUILD/$1.done ]] && { printf '\n\033[1;32m==> %s already built, skipping\033[0m\n' "$1"; return 0; }; return 1; }
mark() { touch "$BUILD/$1.done"; }

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

clone() { # url dir rev
    if [[ ! -d $2/.git ]]; then git clone "$1" "$2"; fi
    git -C "$2" fetch --tags origin
    git -C "$2" checkout -q "$3"
}

step "dnf: build + runtime deps"
# screen recorder used by `caelestia record` / utilities panel (not in Fedora or RPM Fusion)
sudo dnf copr enable -y lezetho/gpu-screen-recorder
# Fedora's libva-intel-media-driver has H.264/HEVC encode stripped -> recorder fails; RPM Fusion has the full one
if lspci | grep -qi 'VGA.*Intel' && rpm -q libva-intel-media-driver >/dev/null 2>&1; then
    sudo dnf swap -y libva-intel-media-driver intel-media-driver --allowerasing
fi
sudo dnf install -y \
    gcc-c++ cmake ninja-build meson pkgconf-pkg-config git autoconf-archive \
    qt6-qtbase-devel qt6-qtbase-private-devel qt6-qtdeclarative-devel qt6-qtshadertools-devel \
    qt6-qtwayland-devel qt6-qtsvg-devel qt6-qtmultimedia-devel qt6-qtimageformats qt6-qt5compat \
    spirv-tools cli11-devel wayland-devel wayland-protocols-devel libdrm-devel mesa-libgbm-devel \
    jemalloc-devel pam-devel polkit-devel glib2-devel pipewire-devel libxcb-devel \
    aubio-devel libqalculate-devel fftw-devel iniparser-devel \
    fish fuzzel grim slurp swappy wl-clipboard cliphist libnotify dconf trash-cli \
    ddcutil brightnessctl lm_sensors lm_sensors-devel NetworkManager \
    google-rubik-fonts cascadia-code-nf-fonts cascadia-mono-nf-fonts \
    python3-pillow python3-pip python3-devel \
    gpu-screen-recorder tesseract tesseract-langpack-rus tesseract-langpack-eng adw-gtk3-theme udiskie

step "wl-clip-persist (cargo; not packaged for Fedora)"
command -v wl-clip-persist >/dev/null || [[ -x $HOME/.cargo/bin/wl-clip-persist ]] || cargo install --locked wl-clip-persist

step "libcava (LukashonakV/cava)"
if ! done_or libcava; then
clone https://github.com/LukashonakV/cava "$BUILD/libcava" master
meson setup --reconfigure --prefix=/usr -Dcava_font=false "$BUILD/libcava/build" "$BUILD/libcava" \
    || meson setup --reconfigure --prefix=/usr "$BUILD/libcava/build" "$BUILD/libcava"
meson compile -C "$BUILD/libcava/build"
sudo meson install -C "$BUILD/libcava/build"
sudo ldconfig
mark libcava
fi

step "quickshell @ ${QS_REV:0:8}"
if ! done_or "quickshell-${QS_REV:0:8}"; then
clone https://git.outfoxxed.me/quickshell/quickshell "$BUILD/quickshell" "$QS_REV"
cmake -S "$BUILD/quickshell" -B "$BUILD/quickshell/build" -G Ninja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=/usr \
    -DCRASH_HANDLER=OFF -DDISTRIBUTOR="fedora-local"
cmake --build "$BUILD/quickshell/build"
sudo cmake --install "$BUILD/quickshell/build"
mark "quickshell-${QS_REV:0:8}"
fi

step "qt6-m3shapes @ ${M3_REV:0:8}"
if ! done_or "m3shapes-${M3_REV:0:8}"; then
clone https://github.com/soramanew/m3shapes "$BUILD/m3shapes" "$M3_REV"
cmake -S "$BUILD/m3shapes" -B "$BUILD/m3shapes/build" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DINSTALL_QMLDIR=lib64/qt6/qml
cmake --build "$BUILD/m3shapes/build"
sudo cmake --install "$BUILD/m3shapes/build"
# pinned m3shapes defaulted INSTALL_QMLDIR to "usr/lib/qt6/qml" -> stray /usr/usr from first run
[[ -d /usr/usr/lib/qt6/qml/M3Shapes ]] && sudo rm -rf /usr/usr/lib/qt6/qml/M3Shapes && sudo rmdir -p --ignore-fail-on-non-empty /usr/usr/lib/qt6/qml 2>/dev/null || true
mark "m3shapes-${M3_REV:0:8}"
fi

step "caelestia-shell @ $SHELL_REF"
# drop previously applied local patches, incl. files they created (keep build/), then go to the pin
if [[ -d $BUILD/shell/.git ]]; then
    git -C "$BUILD/shell" reset -q --hard
    git -C "$BUILD/shell" clean -fdq -e build
fi
clone https://github.com/caelestia-dots/shell "$BUILD/shell" "$SHELL_REF"
for p in "$(dirname "$0")"/patches/caelestia/*.patch; do
    [[ -e $p ]] || continue
    echo "applying $(basename "$p")"
    git -C "$BUILD/shell" apply "$(realpath "$p")" || {
        echo "patch $(basename "$p") no longer applies; installed shell left untouched" >&2
        exit 1
    }
done
cmake -S "$BUILD/shell" -B "$BUILD/shell/build" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr \
    -DINSTALL_LIBDIR=lib/caelestia -DINSTALL_QMLDIR=lib64/qt6/qml \
    -DINSTALL_QSCONFDIR=/etc/xdg/quickshell/caelestia
cmake --build "$BUILD/shell/build"
sudo cmake --install "$BUILD/shell/build"

step "caelestia-cli @ ${CLI_REV:0:8} (uv tool)"
uv tool install --force --python 3.14 "git+https://github.com/caelestia-dots/cli@${CLI_REV}"

step "swappy (patched: shortcuts work on non-latin layouts) -> ~/.local/bin"
if ! done_or swappy; then
clone https://github.com/jtheoof/swappy "$BUILD/swappy" v1.5.1
git -C "$BUILD/swappy" reset -q --hard
git -C "$BUILD/swappy" clean -fdq -e build
git -C "$BUILD/swappy" apply "$(realpath "$(dirname "$0")")/patches/swappy/0001-layout-independent-shortcuts.patch"
meson setup --reconfigure --prefix="$HOME/.local" --buildtype=release "$BUILD/swappy/build" "$BUILD/swappy"
meson compile -C "$BUILD/swappy/build"
meson install -C "$BUILD/swappy/build"
mark swappy
fi

step "Material Symbols Rounded font"
FONT_DIR=$HOME/.local/share/fonts/material-symbols
mkdir -p "$FONT_DIR"
curl -fL -o "$FONT_DIR/MaterialSymbolsRounded.ttf" \
    "https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL,GRAD,opsz,wght%5D.ttf"
fc-cache -f "$FONT_DIR"


step "done"
command -v qs caelestia
