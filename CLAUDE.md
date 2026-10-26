# Working notes for Claude

Layout, install and patch list live in README.md. This file covers how to change things safely.

## Hypr Lua config
- Edit `hypr-lua/...` in the repo and copy the same file to `~/.config/hypr/...` (live copy, not a symlink),
  then `hyprctl reload` + `hyprctl configerrors` (empty = ok).
- `~/.config/hypr/{monitors,workspaces}.lua` are written by nwg-displays; the repo copies mirror them.
- Binds use keycodes (`code:NN`) so they work on us and ru; `hyprctl binds` shows keycode 0 for them, grep the Lua instead.

## caelestia patches
- Source tree with all patches applied: `~/.cache/caelestia-build/shell` (pin = `SHELL_REF` in install-caelestia.sh).
- New patch: edit there, then diff against a worktree of the pin with patches 0001..N already applied and
  committed (several patches touch the same files), save as `patches/caelestia/00NN-name.patch`, add a line to README.
- Check: all patches apply on a fresh worktree of the pin; `qs -p <worktree>` for ~6 s and grep the log for errors.
  That shows a second bar on screen: tell the user before running it.
- The user installs (`./install-caelestia.sh`, needs sudo) and must restart the shell (Super+Alt+R).
  If a fix "doesn't work", first compare the qs start time (`ps -o lstart -C qs`) with the install time.

## Rules
- Commits as Unc3rta1n <nubikkubik123@gmail.com> (local git config). Never publish the global/work email.
- Never store tokens or cookies in the repo. sudo commands are run by the user.
- Reply in Russian.
