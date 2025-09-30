#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

CONFIG_FILE="$HOME/.config/hypr/hyprland.conf"
BACKUP_FILE="$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"

# Создаем бекап конфига
create_backup() {
    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "$BACKUP_FILE"
        print_info "Создан бекап конфига: $BACKUP_FILE"
    else
        print_error "Конфиг файл не найден: $CONFIG_FILE"
        exit 1
    fi
}

# Исправляем ошибки в конфиге
fix_config() {
    print_info "Исправление конфигурации Hyprland..."
    
    # Создаем исправленный конфиг
    cat > "$CONFIG_FILE" << 'EOF'
# Монитор
monitor=,preferred,auto,auto

# Автозапуск приложений
exec-once = waybar
exec-once = dunst
exec-once = nm-applet
exec-once = swaybg -i ~/.config/hypr/wallpaper.jpg

# Ввод
input {
    kb_layout = us,ru
    kb_options = grp:alt_shift_toggle
    follow_mouse = 1
    touchpad {
        natural_scroll = no
    }
}

# Общие настройки
general {
    gaps_in = 5
    gaps_out = 20
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
}

# Оформление
decoration {
    rounding = 10
    
    blur {
        enabled = true
        size = 3
        passes = 1
        new_optimizations = true
    }
    
    drop_shadow = yes
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

# Анимации
animations {
    enabled = yes
    
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    bezier = overshot, 0.13, 0.99, 0.29, 1.1
    bezier = smoothOut, 0.36, 0, 0.66, -0.56
    bezier = smoothIn, 0.25, 1, 0.5, 1
    
    animation = windows, 1, 5, myBezier, popin
    animation = windowsOut, 1, 5, smoothOut, popin
    animation = windowsMove, 1, 5, myBezier
    animation = border, 1, 10, default
    animation = fade, 1, 5, default
    animation = workspaces, 1, 6, overshot
}

# Раскладка окон
dwindle {
    pseudotile = yes
    preserve_split = yes
}

master {
    new_is_master = true
}

# Жесты
gestures {
    workspace_swipe = true
    workspace_swipe_fingers = 3
    workspace_swipe_distance = 250
    workspace_swipe_invert = true
    workspace_swipe_min_speed_to_force = 15
    workspace_swipe_cancel_ratio = 0.5
}

# Биндинги клавиш
bind = SUPER, Q, exec, kitty
bind = SUPER, C, killactive,
bind = SUPER, M, exit,
bind = SUPER, E, exec, thunar
bind = SUPER, V, togglefloating,
bind = SUPER, R, exec, rofi -show drun
bind = SUPER, P, pseudo,
bind = SUPER, F, fullscreen,
bind = SUPER, G, togglegroup,

# Перемещение между окнами
bind = SUPER, left, movefocus, l
bind = SUPER, right, movefocus, r
bind = SUPER, up, movefocus, u
bind = SUPER, down, movefocus, d

# Переключение рабочих столов
bind = SUPER, 1, workspace, 1
bind = SUPER, 2, workspace, 2
bind = SUPER, 3, workspace, 3
bind = SUPER, 4, workspace, 4
bind = SUPER, 5, workspace, 5

# Перемещение окон на рабочие столы
bind = SUPER SHIFT, 1, movetoworkspace, 1
bind = SUPER SHIFT, 2, movetoworkspace, 2
bind = SUPER SHIFT, 3, movetoworkspace, 3
bind = SUPER SHIFT, 4, movetoworkspace, 4
bind = SUPER SHIFT, 5, movetoworkspace, 5

# Прокрутка рабочих столов
bind = SUPER, mouse_down, workspace, e+1
bind = SUPER, mouse_up, workspace, e-1

# Управление окнами
bind = SUPER SHIFT, left, movewindow, l
bind = SUPER SHIFT, right, movewindow, r
bind = SUPER SHIFT, up, movewindow, u
bind = SUPER SHIFT, down, movewindow, d

# Изменение размера окон
bind = SUPER CTRL, left, resizeactive, -20 0
bind = SUPER CTRL, right, resizeactive, 20 0
bind = SUPER CTRL, up, resizeactive, 0 -20
bind = SUPER CTRL, down, resizeactive, 0 20

# Управление медиа
bind = , XF86AudioRaiseVolume, exec, pamixer -i 5
bind = , XF86AudioLowerVolume, exec, pamixer -d 5
bind = , XF86AudioMute, exec, pamixer -t
bind = , XF86AudioPlay, exec, playerctl play-pause
bind = , XF86AudioNext, exec, playerctl next
bind = , XF86AudioPrev, exec, playerctl previous
bind = , XF86MonBrightnessUp, exec, brightnessctl set +5%
bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

# Скриншоты
bind = , PRINT, exec, grim -g "$(slurp)" - | wl-copy
bind = SUPER, PRINT, exec, grim - | wl-copy

# Блокировка экрана
bind = SUPER, L, exec, swaylock

# Меню выхода
bind = SUPER, X, exec, wlogout --protocol layer-shell

# Перезагрузка конфига
bind = SUPER SHIFT, R, exec, hyprctl reload

# Перемещение между окнами в группе
bind = SUPER TAB, changegroupactive, f

# Окно поверх всех
bind = SUPER, O, pin,

# Misc
bind = SUPER, A, exec, hyprctl dispatch centerwindow
bind = SUPER, S, exec, hyprctl dispatch togglefloating

# Запуск приложений
bind = SUPER, W, exec, firefox
bind = SUPER, T, exec, thunar
bind = SUPER, B, exec, blueberry

# Окружение
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

# Правила для окон
windowrule = float, ^(pavucontrol)$
windowrule = float, ^(blueman-manager)$
windowrule = float, ^(nm-connection-editor)$
windowrule = float, ^(org.gnome.Calculator)$
windowrule = size 800 600, ^(kitty)$
windowrule = center, ^(kitty)$

# Рабочие столы по умолчанию
workspace = 1, monitor:DP-1, default:true
workspace = 2, monitor:DP-1
workspace = 3, monitor:DP-1
workspace = 4, monitor:DP-1
workspace = 5, monitor:DP-1
EOF

    print_success "Конфиг исправлен и обновлен!"
}

# Проверяем синтаксис конфига
check_syntax() {
    print_info "Проверка синтаксиса конфига..."
    if hyprctl reload; then
        print_success "Конфиг загружен без ошибок!"
    else
        print_error "В конфиге все еще есть ошибки!"
        exit 1
    fi
}

# Создаем базовые директории
create_directories() {
    print_info "Создание необходимых директорий..."
    
    mkdir -p ~/.config/hypr
    mkdir -p ~/.config/waybar
    mkdir -p ~/.config/dunst
    
    print_success "Директории созданы"
}

# Основная функция
main() {
    print_info "Запуск исправления конфига Hyprland..."
    
    create_directories
    create_backup
    fix_config
    check_syntax
    
    print_success "Конфиг Hyprland успешно исправлен!"
    print_info "Старый конфиг сохранен как: $BACKUP_FILE"
}

# Запуск
main "$@"
