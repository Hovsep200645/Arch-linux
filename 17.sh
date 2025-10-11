#!/bin/bash

echo "🎨 Создание красивого MacOS-подобного интерфейса для Hyprland"

# Установка необходимых пакетов
echo "📦 Установка пакетов..."
sudo pacman -S --needed --noconfirm \
    hyprland \
    kitty \
    waybar \
    rofi-lbonn-wayland \
    mako \
    grim \
    slurp \
    wl-clipboard \
    swaylock-effects \
    swaybg \
    wireplumber \
    playerctl \
    brightnessctl \
    ttf-jetbrains-mono-nerd \
    ttf-font-awesome \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-emoji \
    nwg-look \
    lxappearance \
    papirus-icon-theme

# Создание директорий конфигов
mkdir -p ~/.config/hypr
mkdir -p ~/.config/waybar
mkdir -p ~/.config/rofi
mkdir -p ~/.config/mako
mkdir -p ~/.config/kitty

# 1. Конфиг Hyprland в стиле MacOS с CTRL вместо SUPER
echo "⚙️ Настройка Hyprland..."
cat > ~/.config/hypr/hyprland.conf << 'EOF'
# MacOS-style Hyprland Configuration

monitor=,highrr,auto,1

exec-once = waybar &
exec-once = nm-applet --indicator &
exec-once = swaybg -i ~/.config/hypr/wallpaper.jpg

input {
    kb_layout = us
    kb_variant =
    kb_model =
    kb_options =
    kb_rules =

    follow_mouse = 1
    touchpad {
        natural_scroll = true
        tap-to-click = true
        drag_lock = false
    }
    repeat_rate = 50
    repeat_delay = 300
}

general {
    gaps_in = 8
    gaps_out = 12
    border_size = 2
    col.active_border = rgba(89b4faee) rgba(74c7ecee) 45deg
    col.inactive_border = rgba(595959aa)
    
    layout = dwindle
    resize_on_border = true
    allow_tearing = false
}

dwindle {
    pseudotile = yes
    preserve_split = yes
}

master {
    new_is_master = true
}

decoration {
    rounding = 12
    blur {
        enabled = true
        size = 8
        passes = 3
        new_optimizations = true
    }
    
    drop_shadow = yes
    shadow_range = 30
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

animations {
    enabled = yes
    
    bezier = overshot, 0.13, 0.99, 0.29, 1.10
    bezier = smoothOut, 0.36, 0, 0.66, -0.56
    
    animation = windows, 1, 5, overshot, slide
    animation = windowsOut, 1, 4, smoothOut, slide
    animation = border, 1, 10, default
    animation = fade, 1, 10, default
    animation = workspaces, 1, 6, default
}

# CTRL-based Keybindings (MacOS style)
bind = CTRL, Q, exec, kitty
bind = CTRL, C, killactive
bind = CTRL, M, exit
bind = CTRL, E, exec, nautilus
bind = CTRL, V, togglefloating
bind = CTRL, SPACE, exec, rofi -show drun
bind = CTRL, F, fullscreen
bind = CTRL, T, exec, thunar

# Window Focus
bind = CTRL, left, movefocus, l
bind = CTRL, right, movefocus, r
bind = CTRL, up, movefocus, u
bind = CTRL, down, movefocus, d

# Move Windows
bind = CTRL SHIFT, left, movewindow, l
bind = CTRL SHIFT, right, movewindow, r
bind = CTRL SHIFT, up, movewindow, u
bind = CTRL SHIFT, down, movewindow, d

# Workspaces
bind = CTRL, 1, workspace, 1
bind = CTRL, 2, workspace, 2
bind = CTRL, 3, workspace, 3
bind = CTRL, 4, workspace, 4
bind = CTRL, 5, workspace, 5

bind = CTRL SHIFT, 1, movetoworkspace, 1
bind = CTRL SHIFT, 2, movetoworkspace, 2
bind = CTRL SHIFT, 3, movetoworkspace, 3
bind = CTRL SHIFT, 4, movetoworkspace, 4
bind = CTRL SHIFT, 5, movetoworkspace, 5

# Resize Windows
bind = CTRL ALT, right, resizeactive, 20 0
bind = CTRL ALT, left, resizeactive, -20 0
bind = CTRL ALT, up, resizeactive, 0 -20
bind = CTRL ALT, down, resizeactive, 0 20

# Special Actions
bind = CTRL, Tab, cyclenext
bind = CTRL, Tab, bringactivetotop
bind = CTRL SHIFT, R, exec, hyprctl reload

# Screenshots
bind = , Print, exec, grim -g "$(slurp)" - | wl-copy
bind = SHIFT, Print, exec, grim - | wl-copy

# Media Keys
bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bind = , XF86AudioPlay, exec, playerctl play-pause
bind = , XF86AudioNext, exec, playerctl next
bind = , XF86AudioPrev, exec, playerctl previous

# Brightness
bind = , XF86MonBrightnessUp, exec, brightnessctl set +5%
bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

# Lock Screen
bind = CTRL, L, exec, swaylock

# Hide all UI elements (minimal mode)
bind = CTRL, H, exec, pkill waybar && pkill mako

# Show all UI elements
bind = CTRL SHIFT, H, exec, waybar & 

# Mouse binds
bindm = CTRL, mouse:272, movewindow
bindm = CTRL, mouse:273, resizewindow
EOF

# 2. Waybar config (чистый минималистичный)
echo "📊 Настройка Waybar..."
cat > ~/.config/waybar/config << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 35,
    "spacing": 4,
    "margin-top": 0,
    "margin-bottom": 0,
    "margin-left": 0,
    "margin-right": 0,
    
    "modules-left": ["custom/launcher", "hyprland/workspaces"],
    "modules-center": ["clock"],
    "modules-right": ["cpu", "memory", "pulseaudio", "network", "battery"],
    
    "custom/launcher": {
        "format": " ",
        "on-click": "rofi -show drun",
        "tooltip": false
    },
    
    "hyprland/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "format": "{icon}",
        "format-icons": {
            "1": "",
            "2": "", 
            "3": "",
            "4": "",
            "5": ""
        },
        "on-click": "activate"
    },
    
    "clock": {
        "format": "{:%H:%M}",
        "format-alt": "{:%Y-%m-%d}",
        "tooltip-format": "{:%A, %B %d %Y}"
    },
    
    "cpu": {
        "format": "{usage}% ",
        "interval": 5
    },
    
    "memory": {
        "format": "{}% ",
        "interval": 5
    },
    
    "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-muted": "",
        "format-icons": ["", "", ""],
        "on-click": "pavucontrol",
        "scroll-step": 5
    },
    
    "network": {
        "format-wifi": " {essid}",
        "format-ethernet": " {ipaddr}",
        "format-disconnected": " No connection",
        "tooltip-format": "{ifname}: {ipaddr}"
    },
    
    "battery": {
        "format": "{capacity}% {icon}",
        "format-icons": ["", "", "", "", ""],
        "format-charging": " {capacity}%",
        "interval": 10
    }
}
EOF

# 3. Стиль Waybar (MacOS-like)
cat > ~/.config/waybar/style.css << 'EOF'
* {
    border: none;
    border-radius: 0;
    font-family: "JetBrainsMono Nerd Font";
    font-weight: bold;
    font-size: 14px;
    min-height: 0;
}

window#waybar {
    background: rgba(30, 30, 46, 0.95);
    color: #cdd6f4;
    border-bottom: 1px solid rgba(89, 89, 89, 0.3);
}

#custom-launcher {
    background: rgba(137, 180, 250, 0.3);
    color: #89b4fa;
    border-radius: 8px;
    padding: 0 12px;
    margin: 4px 2px;
}

#workspaces button {
    padding: 0 8px;
    background: transparent;
    color: #6c7086;
    border-radius: 8px;
    margin: 4px 2px;
}

#workspaces button.active {
    background: rgba(137, 180, 250, 0.3);
    color: #89b4fa;
}

#workspaces button:hover {
    background: rgba(108, 112, 134, 0.3);
    color: #cdd6f4;
}

#clock, #cpu, #memory, #pulseaudio, #network, #battery {
    background: rgba(108, 112, 134, 0.2);
    color: #cdd6f4;
    border-radius: 8px;
    padding: 0 12px;
    margin: 4px 2px;
}

#clock {
    background: rgba(137, 180, 250, 0.2);
    color: #89b4fa;
}

#battery.charging {
    color: #a6e3a1;
}

#pulseaudio.muted {
    color: #f38ba8;
}

#network.disconnected {
    color: #f38ba8;
}
EOF

# 4. Конфиг Rofi (MacOS-like menu)
mkdir -p ~/.config/rofi
cat > ~/.config/rofi/config.rasi << 'EOF'
configuration {
    modi: "drun,run,window";
    show-icons: true;
    terminal: "kitty";
    drun-display-format: "{name}";
    window-format: "{w}  {i}  {c}  {t}";
}

@theme "Arc-Dark"

* {
    font: "JetBrainsMono Nerd Font 12";
}
EOF

# 5. Скачиваем красивые обои
echo "🖼️ Установка обоев..."
mkdir -p ~/.config/hypr
curl -s "https://raw.githubusercontent.com/linuxdotexe/hyprland-dots/main/wallpapers/macos-style.jpg" -o ~/.config/hypr/wallpaper.jpg || {
    # Если не скачалось, создаем градиентные обои
    convert -size 1920x1080 gradient:#1e1e2e-#89b4fa ~/.config/hypr/wallpaper.jpg
}

# 6. Настройка Kitty terminal
cat > ~/.config/kitty/kitty.conf << 'EOF'
font_family JetBrainsMono Nerd Font
font_size 12

background #1e1e2e
foreground #cdd6f4

selection_background #585b70
selection_foreground #cdd6f4

url_color #89b4fa

color0 #45475a
color1 #f38ba8
color2 #a6e3a1
color3 #f9e2af
color4 #89b4fa
color5 #f5c2e7
color6 #94e2d5
color7 #bac2de

color8 #585b70
color9 #f38ba8
color10 #a6e3a1
color11 #f9e2af
color12 #89b4fa
color13 #f5c2e7
color14 #94e2d5
color15 #a6adc8

cursor #f5e0dc
cursor_text_color #1e1e2e

window_padding_width 8
hide_window_decorations yes
EOF

# 7. Создаем скрипт для переключения UI
cat > ~/.config/hypr/toggle-ui.sh << 'EOF'
#!/bin/bash
if pgrep waybar > /dev/null; then
    pkill waybar
    pkill mako
    notify-send "UI Hidden" "Press Ctrl+Shift+H to show"
else
    waybar &
    notify-send "UI Shown" "Press Ctrl+H to hide"
fi
EOF
chmod +x ~/.config/hypr/toggle-ui.sh

echo "✅ Настройка завершена!"
echo ""
echo "🎮 Горячие клавиши:"
echo "   CTRL + SPACE - запуск приложений"
echo "   CTRL + Q - терминал"
echo "   CTRL + H - скрыть весь UI"
echo "   CTRL + SHIFT + H - показать UI"
echo "   CTRL + L - заблокировать экран"
echo ""
echo "🎨 Интерфейс в стиле MacOS с минималистичным дизайном"
echo "🚀 Перезагрузите Hyprland: hyprctl reload"