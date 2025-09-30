#!/bin/bash

echo "Удаляем старый конфиг..."
rm -rf ~/.config/hypr

echo "Создаем директории..."
mkdir -p ~/.config/hypr

echo "Создаем простой рабочий конфиг..."
cat > ~/.config/hypr/hyprland.conf << 'EOF'
monitor=,preferred,auto,auto

exec-once = waybar

input {
    kb_layout = us,ru
    kb_options = grp:alt_shift_toggle
}

general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee)
    col.inactive_border = rgba(595959aa)
}

decoration {
    rounding = 5
    blur {
        enabled = true
        size = 3
        passes = 1
    }
}

animations {
    enabled = yes
}

bind = SUPER, Q, exec, kitty
bind = SUPER, C, killactive,
bind = SUPER, M, exit,
bind = SUPER, E, exec, thunar
bind = SUPER, F, fullscreen,
bind = SUPER, V, togglefloating,

bind = SUPER, 1, workspace, 1
bind = SUPER, 2, workspace, 2
bind = SUPER, 3, workspace, 3

bind = SUPER SHIFT, 1, movetoworkspace, 1
bind = SUPER SHIFT, 2, movetoworkspace, 2
bind = SUPER SHIFT, 3, movetoworkspace, 3
EOF

echo "Проверяем конфиг..."
hyprctl reload

if [ $? -eq 0 ]; then
    echo "✅ Конфиг работает!"
else
    echo "❌ Есть ошибки, создаем минимальный конфиг..."
    # Создаем абсолютно минимальный конфиг
    cat > ~/.config/hypr/hyprland.conf << 'EOF'
monitor=,preferred,auto,auto

exec-once = waybar

input {
    kb_layout = us
}

general {
    gaps_in = 5
    border_size = 2
}

bind = SUPER, Q, exec, kitty
bind = SUPER, C, killactive,
EOF
fi

echo "Готово!"
