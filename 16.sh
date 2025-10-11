#!/bin/bash

# Полностью пропускаем nwg-shell и настраиваем вручную
echo "🎯 Настройка рабочего стола без nwg-shell"

# 1. Устанавливаем отдельные компоненты
sudo pacman -S --noconfirm \
    waybar \
    wofi \
    nwg-drawer \
    nwg-look \
    lxappearance

# 2. Настраиваем Waybar как панель
mkdir -p ~/.config/waybar
cat > ~/.config/waybar/config << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 35,
    "spacing": 4,
    
    "modules-left": ["custom/menu", "hyprland/workspaces"],
    "modules-center": ["clock"],
    "modules-right": ["cpu", "memory", "pulseaudio", "network", "battery"],
    
    "custom/menu": {
        "format": " ",
        "on-click": "nwg-drawer",
        "tooltip": false
    },
    
    "hyprland/workspaces": {
        "disable-scroll": true,
        "all-outputs": true
    },
    
    "clock": {
        "format": "{:%H:%M}",
        "tooltip-format": "{:%Y-%m-%d | %H:%M}"
    }
}
EOF

# 3. Добавляем в автозапуск Waybar
if [ -f ~/.config/hypr/hyprland.conf ]; then
    if ! grep -q "waybar" ~/.config/hypr/hyprland.conf; then
        sed -i '/exec-once =/a exec-once = waybar &' ~/.config/hypr/hyprland.conf
    fi
fi

echo "✅ Готово! Перезагрузите Hyprland"
echo "🎮 Теперь у вас есть:"
echo "   - Waybar как панель"
echo "   - nwg-drawer как меню (клик на  в панели)"
echo "   - nwg-look для настройки тем"
echo "   - lxappearance для GTK"