#!/usr/bin/env bash
# Move caelestia-shell to a newer revision without breaking the running setup.
#   ./update-caelestia.sh            latest upstream main
#   ./update-caelestia.sh <rev>      a specific commit/tag
#   ./update-caelestia.sh --check    only report (no install)
#   --no-qml                         skip the QML load test (it shows a second bar for a few seconds;
#                                    used by the weekly scripts/caelestia-upstream-check)
# Steps: fetch -> apply all local patches on the new rev in a scratch worktree -> compare the
# flake.lock pins (quickshell / m3shapes / cli) -> load the patched QML for a few seconds and
# scan for errors -> only then bump the pins in install-caelestia.sh and run it.
# Anything failing stops here; the installed shell is untouched.
# Rollback: git checkout <old commit> -- install-caelestia.sh && ./install-caelestia.sh
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
INSTALL=$HERE/install-caelestia.sh
BUILD=${BUILD:-$HOME/.cache/caelestia-build}
SRC=$BUILD/shell
WT=$BUILD/shell-update

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
die() { printf '\033[1;31m%s\033[0m\n' "$*" >&2; exit 1; }
pin() { sed -n "s/^$1=\([0-9a-f]*\).*/\1/p" "$INSTALL"; }

check_only=false
qml_test=true
rev=origin/main
for a in "$@"; do
    case $a in
    --check) check_only=true ;;
    --no-qml) qml_test=false ;;
    -h | --help) sed -n '2,13p' "$0"; exit 0 ;;
    *) rev=$a ;;
    esac
done

[[ -d $SRC/.git ]] || die "no caelestia source in $SRC: run ./install-caelestia.sh once first"

step "fetch caelestia-shell"
git -C "$SRC" fetch -q --tags origin
old=$(pin SHELL_REF)
new=$(git -C "$SRC" rev-parse "$rev^{commit}") || die "unknown revision: $rev"
[[ $old == "$new" ]] && { echo "already at ${new:0:8}"; exit 0; }
echo "${old:0:8} -> ${new:0:8}"
git -C "$SRC" log --oneline --no-decorate --max-count=40 "$old..$new" # not | head: SIGPIPE under pipefail kills the script

step "apply local patches on ${new:0:8}"
git -C "$SRC" worktree remove --force "$WT" 2>/dev/null || rm -rf "$WT"
git -C "$SRC" worktree prune
git -C "$SRC" worktree add -q --detach "$WT" "$new"
cleanup() { git -C "$SRC" worktree remove --force "$WT" 2>/dev/null || true; }
trap cleanup EXIT
failed=()
for p in "$HERE"/patches/caelestia/*.patch; do
    if git -C "$WT" apply "$p" 2>/dev/null; then
        echo "  ok    $(basename "$p")"
    else
        echo "  FAIL  $(basename "$p")"
        failed+=("$(basename "$p")")
    fi
done
((${#failed[@]} == 0)) || die "patches need rebasing onto ${new:0:8}: ${failed[*]} (nothing installed)"

step "dependency pins (flake.lock)"
lock() { git -C "$SRC" show "$new:flake.lock" | jq -r --arg n "$1" '.nodes[$n].locked.rev // empty'; }
declare -A want=([QS_REV]=$(lock quickshell) [M3_REV]=$(lock m3shapes) [CLI_REV]=$(lock caelestia-cli))
deps_changed=false
for k in QS_REV M3_REV CLI_REV; do
    have=$(pin "$k")
    if [[ -n ${want[$k]} && ${want[$k]} != "$have" ]]; then
        echo "  $k ${have:0:8} -> ${want[$k]:0:8}"
        deps_changed=true
    else
        echo "  $k ${have:0:8} (unchanged)"
    fi
done

step "QML load test"
if ! $qml_test; then
    echo "  skipped (--no-qml)"
elif $deps_changed || ! git -C "$SRC" diff --quiet "$old" "$new" -- plugin CMakeLists.txt; then
    # the new QML may need the new C++ plugin / quickshell, which only exist after the real build
    echo "  skipped: plugin or dependencies changed, the build in install-caelestia.sh is the test"
else
    echo "  starting the patched shell for 8s (a second bar shows up meanwhile)"
    log=$(mktemp)
    timeout 8 env -u QT_QUICK_CONTROLS_STYLE -u QT_STYLE_OVERRIDE qs -p "$WT" >"$log" 2>&1 || true
    errors=$(grep -E 'ERROR|ReferenceError|TypeError|SyntaxError|is not a type|is not installed|Cannot assign|Type .* unavailable' "$log" |
        grep -vE 'quickshell\.dbus|desktopentry' || true)
    rm -f "$log"
    [[ -z $errors ]] || die "patched shell logs errors on ${new:0:8} (nothing installed):
$errors"
    echo "  no QML errors"
fi

$check_only && { echo -e "\n--check: ${new:0:8} looks installable"; exit 0; }

read -rp $'\nBump pins to '"${new:0:8}"$' and run install-caelestia.sh? [y/N] ' ans
[[ $ans == [yY]* ]] || { echo "not installed"; exit 0; }

sed -i -E "s/^SHELL_REF=[0-9a-f]+/SHELL_REF=$new/" "$INSTALL"
for k in QS_REV M3_REV CLI_REV; do
    [[ -n ${want[$k]} ]] && sed -i -E "s/^$k=[0-9a-f]+/$k=${want[$k]}/" "$INSTALL"
done
"$INSTALL"
echo -e "\nInstalled ${new:0:8}. Restart the shell (Super+Alt+R) and commit install-caelestia.sh."
