#!/bin/bash

echo "🔄 Полная переустановка Hyprland с новым стилем"

# 1. Останавливаем и удаляем старый Hyprland
echo "🗑️ Удаление старого Hyprland..."
sudo pkill hyprland || true
sudo pkill waybar || true

# Удаляем пакеты
sudo pacman -Rns hyprland waybar rofi kitty --noconfirm 2>/dev/null || true

# Чистим конфиги
rm -rf ~/.config/hypr
rm -rf ~/.config/waybar
rm -rf ~/.config/rofi
rm -rf ~/.config/kitty
rm -rf ~/.cache/hyprland

# 2. Устанавливаем пакеты заново
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
    noto-fonts-emoji \
    nautilus \
    viewnior

# 3. Создаем директории
mkdir -p ~/.config/hypr
mkdir -p ~/.config/waybar
mkdir -p ~/.config/rofi
mkdir -p ~/.config/kitty

# 4. Создаем конфиг Hyprland в стиле Western с CTRL
echo "⚙️ Создание конфига Hyprland в стиле Western..."
cat > ~/.config/hypr/hyprland.conf << 'EOF'
# Western Style Hyprland Configuration
# Inspired by clean, minimal design with CTRL keybinds

monitor=,preferred,auto,1

# Autostart
exec-once = waybar &
exec-once = nm-applet &
exec-once = swaybg -i ~/.config/hypr/wallpaper.jpg

# Input configuration
input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = false
        tap-to-click = true
    }
    sensitivity = 0
}

# General appearance
general {
    gaps_in = 3
    gaps_out = 6
    border_size = 1
    col.active_border = rgb(8B4513)
    col.inactive_border = rgb(654321)
    layout = dwindle
    cursor_inactive_timeout = 5
}

# Window decoration
decoration {
    rounding = 0
    blur {
        enabled = no
    }
    drop_shadow = no
    active_opacity = 1.0
    inactive_opacity = 0.95
}

# Animations (minimal)
animations {
    enabled = yes
    animation = windows, 1, 2, default
    animation = border, 1, 3, default
    animation = fade, 1, 2, default
}

dwindle {
    pseudotile = yes
    preserve_split = yes
}

master {
    new_is_master = true
}

# CTRL Keybindings (Western Style)
# Applications
bind = CTRL, T, exec, kitty
bind = CTRL, F, exec, nautilus
bind = CTRL, W, exec, firefox
bind = CTRL, E, exec, viewnior
bind = CTRL, O, exec, libreoffice
bind = CTRL, M, exec, rofi -show drun

# Window management
bind = CTRL, Q, killactive
bind = CTRL, SPACE, togglefloating
bind = CTRL, P, pseudo
bind = CTRL, S, togglesplit
bind = CTRL, F11, fullscreen

# Focus windows
bind = CTRL, left, movefocus, l
bind = CTRL, right, movefocus, r
bind = CTRL, up, movefocus, u
bind = CTRL, down, movefocus, d

# Move windows
bind = CTRL SHIFT, left, movewindow, l
bind = CTRL SHIFT, right, movewindow, r
bind = CTRL SHIFT, up, movewindow, u
bind = CTRL SHIFT, down, movewindow, d

# Workspaces (Western numbering)
bind = CTRL, 1, workspace, 1
bind = CTRL, 2, workspace, 2
bind = CTRL, 3, workspace, 3
bind = CTRL, 4, workspace, 4
bind = CTRL, 5, workspace, 5
bind = CTRL, 6, workspace, 6

# Move windows to workspaces
bind = CTRL SHIFT, 1, movetoworkspace, 1
bind = CTRL SHIFT, 2, movetoworkspace, 2
bind = CTRL SHIFT, 3, movetoworkspace, 3
bind = CTRL SHIFT, 4, movetoworkspace, 4
bind = CTRL SHIFT, 5, movetoworkspace, 5
bind = CTRL SHIFT, 6, movetoworkspace, 6

# Special actions
bind = CTRL, TAB, cyclenext
bind = CTRL SHIFT, C, exec, hyprctl reload
bind = CTRL, L, exec, swaylock

# Screenshots
bind = , Print, exec, grim -g "$(slurp)" - | wl-copy
bind = SHIFT, Print, exec, grim - | wl-copy

# Media controls
bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bind = , XF86AudioPlay, exec, playerctl play-pause
bind = , XF86AudioNext, exec, playerctl next
bind = , XF86AudioPrev, exec, playerctl previous

# Mouse bindings
bindm = CTRL, mouse:272, movewindow
bindm = CTRL, mouse:273, resizewindow

# Function keys
bind = CTRL, F1, exec, kitty htop
bind = CTRL, F2, exec, pavucontrol
bind = CTRL, F3, exec, nm-connection-editor
EOF

# 5. Создаем Waybar в Western стиле
echo "📊 Настройка Waybar в Western стиле..."
cat > ~/.config/waybar/config << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 28,
    "spacing": 2,
    "margin-top": 0,
    "margin-bottom": 0,
    "margin-left": 0,
    "margin-right": 0,
    
    "modules-left": ["custom/launcher", "hyprland/workspaces"],
    "modules-center": ["clock"],
    "modules-right": ["cpu", "memory", "pulseaudio", "battery", "tray"],
    
    "custom/launcher": {
        "format": "🌵",
        "on-click": "rofi -show drun",
        "tooltip": false
    },
    
    "hyprland/workspaces": {
        "disable-scroll": false,
        "all-outputs": true,
        "format": "{name}",
        "format-icons": {
            "1": "",
            "2": "",
            "3": "", 
            "4": "",
            "5": "",
            "6": ""
        },
        "on-click": "activate"
    },
    
    "clock": {
        "format": "{:%a %d %b %H:%M}",
        "format-alt": "{:%Y-%m-%d}",
        "tooltip-format": "Western Time\n{:%A, %B %d %Y\n%H:%M:%S}"
    },
    
    "cpu": {
        "format": " {usage}%",
        "interval": 5
    },
    
    "memory": {
        "format": " {used:0.1f}G",
        "interval": 5
    },
    
    "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-muted": "",
        "format-icons": ["", "", ""],
        "on-click": "pavucontrol",
        "scroll-step": 5
    },
    
    "battery": {
        "format": "{capacity}% {icon}",
        "format-icons": ["", "", "", "", ""],
        "format-charging": " {capacity}%",
        "interval": 10
    },
    
    "tray": {
        "spacing": 8
    }
}
EOF

# 6. Стиль Waybar (Western theme)
cat > ~/.config/waybar/style.css << 'EOF'
* {
    border: none;
    border-radius: 0;
    font-family: "JetBrainsMono Nerd Font", monospace;
    font-size: 12px;
    font-weight: bold;
    min-height: 0;
}

window#waybar {
    background: rgba(139, 69, 19, 0.9);  /* SaddleBrown */
    color: #f5f5dc;  /* Beige text */
    border-bottom: 1px solid #8b4513;
}

#custom-launcher {
    background: rgba(160, 82, 45, 0.8);  /* Sienna */
    color: #f5f5dc;
    padding: 0 12px;
    margin: 2px 1px;
    border-right: 1px solid #a0522d;
}

#workspaces button {
    padding: 0 6px;
    background: transparent;
    color: #d2b48c;  /* Tan */
    border-right: 1px solid #a0522d;
}

#workspaces button.active {
    background: rgba(160, 82, 45, 0.6);  /* Sienna */
    color: #fffaf0;  /* FloralWhite */
}

#workspaces button:hover {
    background: rgba(205, 133, 63, 0.4);  /* Peru */
    color: #fffaf0;
}

#clock {
    background: rgba(139, 69, 19, 0.7);
    color: #f5f5dc;
    padding: 0 10px;
    font-weight: normal;
}

#cpu, #memory, #pulseaudio, #battery {
    background: rgba(160, 82, 45, 0.6);
    color: #f5f5dc;
    padding: 0 8px;
    margin: 2px 1px;
    border-left: 1px solid #8b4513;
}

#battery.charging {
    color: #90ee90;  /* LightGreen */
}

#pulseaudio.muted {
    color: #f08080;  /* LightCoral */
}

#tray {
    background: rgba(139, 69, 19, 0.8);
    padding: 0 8px;
}
EOF

# 7. Настройка Rofi (Western style menu)
cat > ~/.config/rofi/config.rasi << 'EOF'
configuration {
    modi: "drun,run";
    show-icons: true;
    terminal: "kitty";
    drun-display-format: "{name}";
    window-format: "{w} · {c} · {t}";
}

@theme "Arc-Dark"

* {
    font: "JetBrainsMono Nerd Font 11";
    background-color: transparent;
}

window {
    background-color: rgba(139, 69, 19, 0.95);
    border: 1px solid #8b4513;
    padding: 20px;
}

element selected {
    background-color: rgba(160, 82, 45, 0.8);
    text-color: #f5f5dc;
}
EOF

# 8. Настройка Kitty terminal (Western colors)
cat > ~/.config/kitty/kitty.conf << 'EOF'
# Western Color Theme
font_family JetBrainsMono Nerd Font
font_size 11

background #2c1a0a
foreground #f5f5dc

selection_background #8b4513
selection_foreground #f5f5dc

url_color #d2b48c

color0  #4d3717
color1  #cd5c5c
color2  #9acd32
color3  #f0e68c
color4  #87ceeb
color5  #da70d6
color6  #20b2aa
color7  #d3d3d3

color8  #8b7355
color9  #f08080
color10 #98fb98
color11 #ffffe0
color12 #b0e0e6
color13 #dda0dd
color14 #afeeee
color15 #ffffff

cursor #d2b48c
cursor_text_color #2c1a0a

window_padding_width 6
hide_window_decorations no
EOF

# 9. Создаем Western обои
echo "🖼️ Создание Western обоев..."
cat > ~/.config/hypr/create_wallpaper.sh << 'EOF'
#!/bin/bash
convert -size 1920x1080 \
  gradient:#2c1a0a-#8b4513 \
  -fill "#654321" -draw "rectangle 0,800 1920,1080" \
  -fill "#8b4513" -draw "rectangle 0,0 1920,100" \
  -pointsize 24 -fill "#f5f5dc" -annotate +50+50 "Western Desktop" \
  ~/.config/hypr/wallpaper.jpg
EOF

chmod +x ~/.config/hypr/create_wallpaper.sh
~/.config/hypr/create_wallpaper.sh

# 10. Создаем файл сессии для display manager
echo "🎮 Создание файла сессии..."
sudo tee /usr/share/wayland-sessions/hyprland-western.desktop << 'EOF'
[Desktop Entry]
Name=Hyprland Western
Comment=Western style Hyprland session
Exec=Hyprland
Type=Application
EOF

echo ""
echo "✅ Western Style Hyprland установлен!"
echo ""
echo "🎮 Горячие клавиши (CTRL-based):"
echo "   CTRL + T - Terminal"
echo "   CTRL + M - Application Menu"
echo "   CTRL + F - File Manager"
echo "   CTRL + W - Web Browser"
echo "   CTRL + 1-6 - Workspaces"
echo "   CTRL + L - Lock Screen"
echo ""
echo "🎨 Стиль: Western (коричневые тона, минимализм)"
echo "🚀 Перезагрузите систему или запустите: Hyprland"
echo ""
echo "⚠️  Если не работает:"
echo "   - Проверьте: hyprctl reload"
echo "   - Запустите вручную: Hyprland"
echo "   - Логи: journalctl -u hyprland -f"