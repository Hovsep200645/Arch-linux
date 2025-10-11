#!/bin/bash

echo "🚀 Настройка Hyprland - полная установка"

# Создаем директории конфигов
mkdir -p ~/.config/hypr
mkdir -p ~/.config/waybar

# 1. Устанавливаем необходимые пакеты
echo "📦 Установка пакетов..."
sudo pacman -S --needed --noconfirm \
    hyprland \
    kitty \
    waybar \
    wofi \
    mako \
    nautilus \
    network-manager-applet \
    grim \
    slurp \
    wl-clipboard \
    swaylock \
    swaybg \
    wireplumber \
    ttf-jetbrains-mono-nerd \
    noto-fonts

# 2. Создаем основной конфиг Hyprland
echo "⚙️ Создание конфигурации Hyprland..."
cat > ~/.config/hypr/hyprland.conf << 'EOF'
# ~/.config/hypr/hyprland.conf

monitor=,preferred,auto,auto

exec-once = waybar &
exec-once = mako &
exec-once = nm-applet &
exec-once = swaybg -i ~/.config/hypr/wallpaper.jpg

input {
    kb_layout = us,ru
    kb_options = grp:alt_shift_toggle
    follow_mouse = 1
    
    touchpad {
        natural_scroll = false
    }
}

general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
}

decoration {
    rounding = 10
    blur {
        enabled = true
        size = 3
        passes = 1
    }
    drop_shadow = yes
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

animations {
    enabled = yes
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

dwindle {
    pseudotile = yes
    preserve_split = yes
}

master {
    new_is_master = true
}

gestures {
    workspace_swipe = false
}

# Основные биндинги
bind = SUPER, Q, exec, kitty
bind = SUPER, C, killactive
bind = SUPER, M, exit
bind = SUPER, E, exec, nautilus
bind = SUPER, V, togglefloating
bind = SUPER, R, exec, wofi --show drun
bind = SUPER, P, pseudo
bind = SUPER, J, togglesplit
bind = SUPER, F, fullscreen

# Перемещение фокуса
bind = SUPER, left, movefocus, l
bind = SUPER, right, movefocus, r
bind = SUPER, up, movefocus, u
bind = SUPER, down, movefocus, d

# Рабочие столы
bind = SUPER, 1, workspace, 1
bind = SUPER, 2, workspace, 2
bind = SUPER, 3, workspace, 3
bind = SUPER, 4, workspace, 4
bind = SUPER, 5, workspace, 5
bind = SUPER, 6, workspace, 6

# Перемещение окон
bind = SUPER SHIFT, 1, movetoworkspace, 1
bind = SUPER SHIFT, 2, movetoworkspace, 2
bind = SUPER SHIFT, 3, movetoworkspace, 3
bind = SUPER SHIFT, 4, movetoworkspace, 4
bind = SUPER SHIFT, 5, movetoworkspace, 5

# Скролл рабочих столов
bind = SUPER, mouse_down, workspace, e+1
bind = SUPER, mouse_up, workspace, e-1

# Снимки экрана
bind = , Print, exec, grim -g "$(slurp)" - | wl-copy
bind = SHIFT, Print, exec, grim - | wl-copy

# Блокировка экрана
bind = SUPER, L, exec, swaylock

# Перезагрузка конфига
bind = SUPER SHIFT, R, exec, hyprctl reload

# Громкость
bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

# Яркость (если поддерживается)
bind = , XF86MonBrightnessUp, exec, brightnessctl set +5%
bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
EOF

# 3. Создаем конфиг Waybar
echo "📊 Настройка Waybar..."
cat > ~/.config/waybar/config << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 35,
    "spacing": 4,
    
    "modules-left": ["hyprland/workspaces"],
    "modules-center": ["clock"],
    "modules-right": ["cpu", "memory", "battery", "pulseaudio", "network", "tray"],
    
    "hyprland/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "format": "{icon}",
        "format-icons": {
            "1": "",
            "2": "",
            "3": "",
            "4": "",
            "5": "",
            "6": ""
        }
    },
    
    "clock": {
        "format": "{:%H:%M}",
        "tooltip-format": "{:%Y-%m-%d | %H:%M}"
    },
    
    "cpu": {
        "format": "{usage}% ",
        "tooltip": false
    },
    
    "memory": {
        "format": "{}% "
    },
    
    "battery": {
        "format": "{capacity}% {icon}",
        "format-icons": ["", "", "", "", ""]
    },
    
    "network": {
        "format-wifi": "{essid} ({signalStrength}%) ",
        "format-ethernet": " {ipaddr}",
        "format-disconnected": " No connection",
        "tooltip-format": "{ifname} via {gwaddr}"
    },
    
    "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-muted": "🔇",
        "format-icons": ["🔈", "🔉", "🔊"],
        "on-click": "pavucontrol"
    }
}
EOF

# 4. Создаем стиль Waybar
cat > ~/.config/waybar/style.css << 'EOF'
* {
    border: none;
    border-radius: 0;
    font-family: "JetBrainsMono Nerd Font";
    font-size: 14px;
    min-height: 0;
}

window#waybar {
    background: rgba(21, 18, 27, 0.8);
    color: #cdd6f4;
}

#workspaces button {
    padding: 0 8px;
    background: transparent;
    color: #cdd6f4;
    border: 2px solid transparent;
    border-radius: 8px;
}

#workspaces button.active {
    background: linear-gradient(45deg, #cba6f7, #f5c2e7);
    color: #1e1e2e;
}

#clock, #cpu, #memory, #battery, #pulseaudio, #network {
    padding: 0 10px;
    margin: 0 3px;
    background: rgba(127, 132, 156, 0.2);
    border-radius: 8px;
}
EOF

# 5. Скачиваем обои по умолчанию
echo "🖼️ Установка обоев..."
curl -s https://raw.githubusercontent.com/hyprwm/hyprland/main/assets/wallpaper.png -o ~/.config/hypr/wallpaper.jpg

# 6. Создаем desktop файл для дисплейных менеджеров
echo "🎮 Создание файла сессии..."
sudo tee /usr/share/wayland-sessions/hyprland.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Hyprland
Comment=Hyprland Wayland compositor
Exec=Hyprland
Type=Application
EOF

# 7. Настраиваем автозапуск в TTY
echo "🔧 Настройка автозапуска..."
if [ ! -f ~/.zprofile ]; then
    touch ~/.zprofile
fi

if ! grep -q "Hyprland" ~/.zprofile; then
    cat >> ~/.zprofile << 'EOF'

# Autostart Hyprland
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec Hyprland
fi
EOF
fi

# 8. Даем права на выполнение
chmod +x ~/.zprofile

echo "✅ Настройка завершена!"
echo ""
echo "🎯 Доступные команды:"
echo "   SUPER + Q - терминал"
echo "   SUPER + R - запускатель приложений" 
echo "   SUPER + C - закрыть окно"
echo "   SUPER + F - полноэкранный режим"
echo "   Print - скриншот области"
echo "   SUPER + L - заблокировать экран"
echo ""
echo "🔄 Перезагрузите систему или запустите Hyprland вручную:"
echo "   Hyprland"
echo ""
echo "📝 Для изменения раскладки клавиатуры отредактируйте input.kb_layout в hyprland.conf"