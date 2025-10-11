#!/bin/bash

echo "🔧 Создание рабочего интерфейса Hyprland"

# Проверяем, что мы в Arch/CachyOS
if ! command -v pacman &> /dev/null; then
    echo "❌ Это не Arch-based система"
    exit 1
fi

# 1. Установка пакетов с проверкой
echo "📦 Установка пакетов..."
sudo pacman -S --needed --noconfirm \
    hyprland \
    kitty \
    waybar \
    rofi \
    grim \
    slurp \
    wl-clipboard \
    swaylock \
    swaybg \
    wireplumber \
    pavucontrol \
    network-manager-applet \
    ttf-jetbrains-mono-nerd \
    ttf-font-awesome \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-emoji

# Проверяем установку
if ! command -v hyprland &> /dev/null; then
    echo "❌ Hyprland не установился"
    exit 1
fi

# Создаем директории
mkdir -p ~/.config/hypr
mkdir -p ~/.config/waybar
mkdir -p ~/.config/kitty

# 2. Простой рабочий конфиг Hyprland
echo "⚙️ Создание конфига Hyprland..."
cat > ~/.config/hypr/hyprland.conf << 'EOF'
# Простой рабочий конфиг

monitor=,preferred,auto,1

exec-once = waybar &
exec-once = nm-applet &

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
    col.active_border = rgb(89b4fa)
    col.inactive_border = rgb(585b70)
    layout = dwindle
}

decoration {
    rounding = 5
    blur {
        enabled = false
    }
    drop_shadow = false
}

animations {
    enabled = no
}

# Биндинги с ALT вместо SUPER
bind = ALT, Q, exec, kitty
bind = ALT, C, killactive
bind = ALT, M, exit
bind = ALT, E, exec, nautilus
bind = ALT, V, togglefloating
bind = ALT, D, exec, rofi -show drun
bind = ALT, F, fullscreen

# Фокус окон
bind = ALT, left, movefocus, l
bind = ALT, right, movefocus, r
bind = ALT, up, movefocus, u
bind = ALT, down, movefocus, d

# Рабочие столы
bind = ALT, 1, workspace, 1
bind = ALT, 2, workspace, 2
bind = ALT, 3, workspace, 3
bind = ALT, 4, workspace, 4
bind = ALT, 5, workspace, 5

bind = ALT SHIFT, 1, movetoworkspace, 1
bind = ALT SHIFT, 2, movetoworkspace, 2
bind = ALT SHIFT, 3, movetoworkspace, 3
bind = ALT SHIFT, 4, movetoworkspace, 4
bind = ALT SHIFT, 5, movetoworkspace, 5

# Скриншоты
bind = , Print, exec, grim -g "$(slurp)" - | wl-copy
bind = SHIFT, Print, exec, grim - | wl-copy

# Громкость
bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

# Блокировка
bind = ALT, L, exec, swaylock

# Перезагрузка конфига
bind = ALT SHIFT, R, exec, hyprctl reload

# Мышь
bindm = ALT, mouse:272, movewindow
bindm = ALT, mouse:273, resizewindow
EOF

# 3. Простой Waybar
echo "📊 Настройка Waybar..."
cat > ~/.config/waybar/config << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 35,
    
    "modules-left": ["hyprland/workspaces"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "battery", "tray"],
    
    "hyprland/workspaces": {
        "disable-scroll": true,
        "all-outputs": true
    },
    
    "clock": {
        "format": "{:%H:%M}"
    },
    
    "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-muted": "🔇",
        "format-icons": ["🔈", "🔉", "🔊"]
    },
    
    "battery": {
        "format": "{capacity}% {icon}",
        "format-icons": ["", "", "", "", ""]
    }
}
EOF

cat > ~/.config/waybar/style.css << 'EOF'
* {
    font-family: "JetBrainsMono Nerd Font";
    font-size: 14px;
}

window#waybar {
    background: #1e1e2e;
    color: #cdd6f4;
}

#workspaces button {
    color: #6c7086;
    background: transparent;
}

#workspaces button.active {
    color: #89b4fa;
    background: rgba(137, 180, 250, 0.2);
}

#clock, #pulseaudio, #battery {
    padding: 0 10px;
}
EOF

# 4. Простой Kitty
echo "🐱 Настройка Kitty..."
cat > ~/.config/kitty/kitty.conf << 'EOF'
font_family JetBrainsMono Nerd Font
font_size 12
background #1e1e2e
foreground #cdd6f4
EOF

# 5. Создаем обои
echo "🖼️ Создание обоев..."
convert -size 1920x1080 gradient:#1e1e2e-#89b4fa ~/.config/hypr/wallpaper.jpg 2>/dev/null || echo "⚠️ Не удалось создать обои, установите imagemagick"

# 6. Тестовый скрипт
echo "🧪 Создание тестового скрипта..."
cat > ~/test-hypr.sh << 'EOF'
#!/bin/bash
echo "Тест Hyprland:"
echo "1. Проверка конфига: hyprctl reload"
hyprctl reload
echo "2. Рабочие столы: hyprctl workspaces"
hyprctl workspaces
echo "3. Запустите терминал: ALT+Q"
echo "4. Запустите меню: ALT+D"
EOF
chmod +x ~/test-hypr.sh

echo ""
echo "✅ Базовый интерфейс настроен!"
echo ""
echo "🎮 Горячие клавиши:"
echo "   ALT + Q - терминал"
echo "   ALT + D - меню приложений"
echo "   ALT + 1-5 - рабочие столы"
echo "   ALT + L - блокировка"
echo ""
echo "🔧 Для теста запустите: ./test-hypr.sh"
echo "🚀 Перезапустите Hyprland или выполните: hyprctl reload"