#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026) - Fixed Parser
# ==================================================

CONFIG_FILE="$HOME/.config/hypr/UserConfigs/01-UserDefaults.conf"

if [[ ! -f "$CONFIG_FILE" ]]; then
  notify-send -u critical "Config Error" "File not found: $CONFIG_FILE"
  exit 1
fi

# Функция для чтения значения переменной из конфига
# Поддерживает форматы: $var = value, var = value, var=value
# Игнорирует комментарии (#)
get_var() {
  local var_name="$1"
  # awk ищет строку, где первое поле (с учетом $ и пробелов) совпадает с именем переменной
  # Затем печатает всё после знака равно, удаляет комментарии и лишние пробелы
  awk -F'=' -v var="$var_name" '
        $1 ~ "^\\s*\\\$?" var "\\s*$" {
            gsub(/#.*/, "", $2); # Удаляем комментарий
            gsub(/^\\s+|\\s+$/, "", $2); # Trim пробелы
            print $2;
            exit
        }
    ' "$CONFIG_FILE"
}

TERM_CMD=$(get_var "term")
FILES_CMD=$(get_var "files")

# Дебаг вывод (можно раскомментировать для проверки, что скрипт видит)
# echo "DEBUG: TERM_CMD='$TERM_CMD'" >> /tmp/waybar_script.log

if [[ -z "$TERM_CMD" ]]; then
  notify-send -u critical "Config Error" "Variable 'term' is empty or not found in config.\nCheck format: \$term = ghostty"
  exit 1
fi

case "${1:-}" in
"--btop")
  if ! command -v btop &>/dev/null; then
    notify-send "Error" "btop not installed"
    exit 1
  fi
  nohup $TERM_CMD -e btop >/dev/null 2>&1 &
  ;;
"--nvtop")
  if ! command -v nvtop &>/dev/null; then
    notify-send "Error" "nvtop not installed"
    exit 1
  fi
  nohup $TERM_CMD -e nvtop >/dev/null 2>&1 &
  ;;
"--nmtui")
  nohup $TERM_CMD -e nmtui >/dev/null 2>&1 &
  ;;
"--term")
  nohup $TERM_CMD >/dev/null 2>&1 &
  ;;
"--files")
  if [[ -z "$FILES_CMD" ]]; then
    notify-send "Error" "Variable 'files' is not set."
    exit 1
  fi
  nohup $FILES_CMD >/dev/null 2>&1 &
  ;;
*)
  echo "Usage: $0 [--btop | --nvtop | --nmtui | --term | --files]"
  exit 1
  ;;
esac
