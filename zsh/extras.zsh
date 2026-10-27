# --- navigation ---
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

# --- safety / defaults ---
alias cp='cp -iv'
alias mv='mv -iv'
alias mkdir='mkdir -pv'
alias grep='grep --color=auto'
alias ip='ip -c'
alias diff='diff --color=auto'
alias please='sudo $(fc -ln -1)'

# --- dnf ---
alias dni='sudo dnf install'
alias dnu='sudo dnf upgrade --refresh'
alias dns='dnf search'
alias dnr='sudo dnf remove'
alias dninfo='dnf info'

# --- system ---
alias ports='ss -tulpn'
alias myip='curl -s ifconfig.me; echo'
alias psg='ps aux | grep -v grep | grep -i'
alias h='atuin history list 2>/dev/null | tail -30 || history 30'
alias reload='exec zsh'
alias weather='curl -s "wttr.in/?0"'
alias cheat='f() { curl -s "cht.sh/$1"; }; f'
alias jc='journalctl -xeu'
alias sc='systemctl'
alias scu='systemctl --user'
command -v lazygit >/dev/null && alias lg='lazygit'

# ghostty's TERM is unknown on most remote hosts (backspace/colours break over ssh)
alias ssh='TERM=xterm-256color ssh'

# --- SSH passwords from GNOME Keyring (imported from MobaXterm, 2026-10-27) ---
# SSH_ASKPASS_REQUIRE=force makes ssh use the askpass helper even with a
# controlling tty (needs OpenSSH >=8.4). Lookup: ~/.local/bin/ssh-askpass-keyring
export SSH_ASKPASS="$HOME/.local/bin/ssh-askpass-keyring"
export SSH_ASKPASS_REQUIRE=force

# --- global aliases: `cmd G pat`, `cmd L`, `cmd C` ---
alias -g G='| grep -i'
alias -g L='| less'
alias -g C='| wl-copy'
alias -g H='| head'
alias -g T='| tail'
alias -g J='| jq'

# --- notify when a long command finishes in an unfocused window ---
NOTIFY_MIN_SECONDS=30
NOTIFY_IGNORE=(nvim vim yazi y less man bat btop htop ssh claude lazygit lg fzf watch tail journalctl)

_notify_focus() { hyprctl activewindow -j 2>/dev/null | jq -r '.address // empty'; }

_notify_preexec() {
  _notify_cmd="$1"
  _notify_start=$EPOCHSECONDS
  _notify_win=$(_notify_focus)
}

_notify_precmd() {
  local rc=$?
  [[ -z $_notify_start ]] && return
  local elapsed=$(( EPOCHSECONDS - _notify_start )) cmd=${_notify_cmd%% *}
  unset _notify_start
  (( elapsed < NOTIFY_MIN_SECONDS )) && return
  (( ${NOTIFY_IGNORE[(Ie)$cmd]} )) && return
  # focused window unchanged = user is still looking at the terminal
  [[ "$(_notify_focus)" == "$_notify_win" ]] && return
  local icon=dialog-information urgency=normal title="Done: ${_notify_cmd[1,60]}"
  if (( rc != 0 )); then icon=dialog-error urgency=critical title="Failed ($rc): ${_notify_cmd[1,60]}"; fi
  notify-send -i $icon -u $urgency "$title" "took ${elapsed}s"
}

zmodload zsh/datetime
autoload -Uz add-zsh-hook
add-zsh-hook preexec _notify_preexec
add-zsh-hook precmd _notify_precmd

# --- cheatsheet: `zh` or F1 ---
zh() {
  local file=$HOME/.config/zsh/cheatsheet.txt
  if [[ -t 1 ]] && command -v fzf >/dev/null; then
    column -t -s $'\t' "$file" | fzf --no-sort --prompt='шпаргалка > ' --height=80% --layout=reverse >/dev/null
  else
    column -t -s $'\t' "$file"
  fi
}
_zh_widget() { zle -I; zh; zle reset-prompt }
zle -N _zh_widget
bindkey '^[OP' _zh_widget
bindkey '^[[11~' _zh_widget

# --- docker / uv (from shell history) ---
alias d='docker'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dpa='docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"'
alias dlogs='docker logs -f --tail 100'
alias dstopa='docker stop $(docker ps -q)'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f --tail 100'
alias uvr='uv run'
alias uva='uv add'
alias uvs='uv sync'

# pk: pick a parser in ~/check_parsers with fzf and cd into it
pk() {
  local dir
  dir=$(command ls ~/check_parsers | fzf --prompt='parser > ' --height=60% --layout=reverse \
        --preview 'ls ~/check_parsers/{}') && cd ~/check_parsers/"$dir"
}
