#!/usr/bin/env bash
LOG="/tmp/pass_attempts.log"

read -rs -p "Пароль: " attempt
echo

# Проверяем через PAM тем же механизмом, что и вход
if echo "$attempt" | sudo -S true 2>/dev/null; then
    echo "✅ верно"
else
    echo "$(date +%H:%M:%S) | ввёл: $attempt" >> "$LOG"
    echo "❌ неверно, записано в $LOG"
fi

