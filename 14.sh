#!/bin/bash

echo "🔧 Исправление nwg-shell и установка альтернативных утилит"

# 1. Останавливаем возможные процессы nwg-shell
echo "🛑 Остановка процессов nwg-shell..."
pkill nwg-shell || true
pkill nwg-autotiling || true

# 2. Создаем необходимые директории
echo "📁 Создание директорий..."
mkdir -p ~/.local/share/nwg-shell
mkdir -p ~/.local/share/nwg-shell-config
mkdir -p ~/.config/nwg-shell
mkdir -p ~/.config/autostart

# 3. Создаем базовые конфигурационные файлы
echo "⚙️ Создание конфигурационных файлов..."

# Настройки nwg-shell-config
cat > ~/.local/share/nwg-shell-config/settings.json << 'EOF'
{
  "autotiling-workspace": true,
  "autotiling-layout": "tiling",
  "theme": "dark",
  "font-size": 12,
  "panel-position": "top"
}
EOF

# Данные nwg-shell
cat > ~/.local/share/nwg-shell/data.json << 'EOF'
{
  "version": "0.4.0",
  "initialized": true,
  "first-run": false
}
EOF

# 4. Исправляем права доступа
echo "🔐 Настройка прав доступа..."
chmod 755 ~/.local/share/nwg-shell
chmod 755 ~/.local/share/nwg-shell-config
chmod 644 ~/.local/share/nwg-shell-config/settings.json
chmod 644 ~/.local/share/nwg-shell/data.json

# 5. Переустанавливаем nwg-shell
echo "📦 Переустановка nwg-shell..."
yay -Rns nwg-shell --noconfirm 2>/dev/null || true
yay -S nwg-shell --noconfirm

# 6. Устанавливаем альтернативные графические утилиты
echo "🎛️ Установка графических утилит..."

# Основные системные утилиты
sudo pacman -S --needed --noconfirm \
    pavucontrol \
    blueman \
    wdisplays \
    arandr \
    lxappearance \
    qt5ct \
    gparted \
    file-roller \
    gtk-engine-murrine \
    gtk-engines

# Hyprland-специфичные утилиты
yay -S --needed --noconfirm \
    hyprpicker \
    hyprlock \
    hypridle \
    swaync \
    nwg-look \
    nwg-drawer

# 7. Создаем desktop файлы для автозапуска
echo "🚀 Настройка автозапуска..."

# Bluetooth
cat > ~/.config/autostart/blueman.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Bluetooth Manager
Exec=blueman-applet
EOF

# Network manager
cat > ~/.config/autostart/nm-applet.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Network Manager
Exec=nm-applet
EOF

# 8. Создаем скрипт для быстрого доступа к настройкам
echo "🎯 Создание скрипта быстрого доступа..."

cat > ~/hypr-config-launcher.sh << 'EOF'
#!/bin/bash
echo "Выберите утилиту для настройки:"
echo "1) Audio (pavucontrol)"
echo "2) Bluetooth (blueman)"
echo "3) Monitors (wdisplays)" 
echo "4) Appearance (lxappearance)"
echo "5) Notifications (swaync)"
echo "6) GTK Theme (nwg-look)"
echo "7) All in menu"
echo "8) Exit"

read -p "Введите номер: " choice

case $choice in
    1) pavucontrol ;;
    2) blueman-manager ;;
    3) wdisplays ;;
    4) lxappearance ;;
    5) swaync ;;
    6) nwg-look ;;
    7) 
        echo "Запуск меню настроек..."
        nwg-shell-config &
        sleep 2
        pavucontrol &
        blueman-manager &
        wdisplays &
        ;;
    8) exit ;;
    *) echo "Неверный выбор" ;;
esac
EOF

chmod +x ~/hypr-config-launcher.sh

# 9. Добавляем команду в Hyprland конфиг
echo "🔄 Обновление конфига Hyprland..."

# Добавляем биндинг для меню настроек если файл существует
if [ -f ~/.config/hypr/hyprland.conf ]; then
    if ! grep -q "hypr-config-launcher" ~/.config/hypr/hyprland.conf; then
        echo "" >> ~/.config/hypr/hyprland.conf
        echo "# Графические настройки" >> ~/.config/hypr/hyprland.conf
        echo "bind = SUPER, N, exec, ~/hypr-config-launcher.sh" >> ~/.config/hypr/hyprland.conf
    fi
fi

# 10. Завершаем настройку
echo "✅ Настройка завершена!"
echo ""
echo "🎮 Доступные команды:"
echo "   SUPER + N - меню графических настроек"
echo "   nwg-shell-config - настройки оболочки"
echo "   ~/hypr-config-launcher.sh - запуск утилит"
echo ""
echo "🛠️  Установленные утилиты:"
echo "   • pavucontrol - аудио"
echo "   • blueman - bluetooth" 
echo "   • wdisplays - мониторы"
echo "   • lxappearance - темы"
echo "   • swaync - уведомления"
echo "   • nwg-look - GTK настройки"
echo ""
echo "🔧 Для ручного запуска конфигуратора:"
echo "   nwg-shell-config"
echo ""
echo "🔄 Перезагрузите Hyprland для применения всех настроек:"
echo "   hyprctl reload"