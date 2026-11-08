# Dolphin: динамическая тема

- Caelestia сейчас использует dynamic; `~/.local/state/caelestia/scheme.json` меняется вместе с обоями. Firefox через Pywalfox обновляется.
- `caelestia-kde-colors.path` генерирует `~/.local/share/color-schemes/Caelestia.colors`, обновляет `kdeglobals` и `dolphinrc`; файл схемы обновился, но Dolphin визуально остался прежним.
- Глобально заданы `QT_QPA_PLATFORMTHEME=qt6ct`, стиль Kvantum, `custom_palette=true` с Catppuccin Mocha; тема Kvantum catppuccin-mocha-blue содержит фиксированные цвета. Какой слой перекрывает палитру Dolphin, пока не доказано.
- Пробный отдельный запуск через `QT_QPA_PLATFORMTHEME=kde QT_STYLE_OVERRIDE=breeze dbus-run-session -- dolphin --new-window` дал светлые панели и тёмный список с нечитаемым тёмным текстом; прозрачность Hyprland усугубляет. Постоянные настройки не менялись.
- Разобраться с источником смешанной палитры и сделать обновление цветов Dolphin от Caelestia без нежелательного влияния на остальные Qt-приложения.
- Пробный запуск qt6ct + Fusion с отдельной конфигурацией и палитрой из Caelestia понравился; выделение стало читаемым после замены цветов `Colors:Selection` и Qt Highlight/HighlightedText на тёмный фон `#315d54` и светлый текст `#f1fffa`.
- Это только эксперимент: отдельный `XDG_CONFIG_HOME` и `dbus-run-session` изолируют настройки и D-Bus; перед постоянным внедрением нужно сохранить обычные настройки Dolphin, открытие папок и обновление палитры при смене обоев. Цвет выделения следует получать из текущей схемы с достаточным контрастом, а не фиксировать под одни обои.
- Установлен `plasma-integration`: пробный Dolphin с `QT_QPA_PLATFORMTHEME=kde` и `QT_STYLE_OVERRIDE=Fusion` пользователь подтвердил. Настроены Super+E, desktop-файл и systemd-служба Dolphin. Осталось проверить смену обоев в открытом Dolphin и обычное открытие папок.

- Проверено пользователем: открытый Dolphin меняет цвета при смене обоев.
