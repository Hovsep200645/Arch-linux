#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функции для вывода
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Проверка на root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "Этот скрипт не должен запускаться от root!"
        exit 1
    fi
}

# Проверка интернет соединения
check_internet() {
    print_info "Проверка интернет соединения..."
    if ! ping -c 1 archlinux.org &> /dev/null; then
        print_error "Нет интернет соединения!"
        exit 1
    fi
}

# Установка Hyprland и зависимостей
install_hyprland() {
    print_info "Установка Hyprland и зависимостей..."
    
    # Обновление системы
    sudo pacman -Syu --noconfirm
    
    # Установка основных пакетов
    sudo pacman -S --needed --noconfirm \
        wayland \
        xorg-xwayland \
        mesa \
        vulkan-icd-loader \
        base-devel \
        git \
        cmake \
        ninja \
        gcc
    
    # Установка Hyprland
    sudo pacman -S --needed --noconfirm hyprland
    
    # Установка графического менеджера (SDDM)
    sudo pacman -S --needed --noconfirm sddm
    
    # Установка необходимых утилит
    sudo pacman -S --needed --noconfirm \
        kitty \
        thunar \
        firefox \
        nano \
        networkmanager \
        pulseaudio \
        pulseaudio-alsa \
        pavucontrol \
        brightnessctl \
        playerctl \
        wl-clipboard \
        qt5-wayland \
        qt6-wayland \
        noto-fonts \
        noto-fonts-emoji \
        waybar \
        rofi \
        dunst \
        swaybg \
        swaylock \
        grim \
        slurp \
        wlogout
}

# Настройка конфигурации Hyprland
configure_hyprland() {
    print_info "Настройка конфигурации Hyprland..."
    
    # Создание директорий конфигурации
    mkdir -p ~/.config/hypr
    mkdir -p ~/.config/waybar
    mkdir -p ~/.config/dunst
    
    # Создание основного конфига Hyprland
    cat > ~/.config/hypr/hyprland.conf << 'EOF'
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
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

# Раскладка окон
dwindle {
    pseudotile = yes
    preserve_split = yes
}

# Жесты
gestures {
    workspace_swipe = on
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

# Перемещение окон на рабочие столы
bind = SUPER SHIFT, 1, movetoworkspace, 1
bind = SUPER SHIFT, 2, movetoworkspace, 2
bind = SUPER SHIFT, 3, movetoworkspace, 3
bind = SUPER SHIFT, 4, movetoworkspace, 4

# Управление медиа
bind = , XF86AudioRaiseVolume, exec, pamixer -i 5
bind = , XF86AudioLowerVolume, exec, pamixer -d 5
bind = , XF86AudioMute, exec, pamixer -t
bind = , XF86MonBrightnessUp, exec, brightnessctl set +5%
bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

# Скриншоты
bind = , PRINT, exec, grim -g "$(slurp)" - | wl-copy
bind = SUPER, PRINT, exec, grim - | wl-copy

# Блокировка экрана
bind = SUPER, L, exec, swaylock

# Меню выхода
bind = SUPER, X, exec, wlogout
EOF

    # Создание конфига Waybar
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
            "5": ""
        }
    },
    
    "clock": {
        "format": "{:%H:%M}",
        "format-alt": "{:%Y-%m-%d}"
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
        "format-ethernet": "{ifname} ",
        "format-disconnected": "Disconnected ⚠",
        "tooltip-format": "{ifname}: {ipaddr}/{cidr}"
    },
    
    "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-muted": "",
        "format-icons": ["", "", ""]
    }
}
EOF

    # Создание скрипта для обоев
    cat > ~/.config/hypr/set-wallpaper.sh << 'EOF'
#!/bin/bash
# Скачивание обоев по умолчанию (можно заменить на свои)
if [ ! -f ~/.config/hypr/wallpaper.jpg ]; then
    curl -s -o ~/.config/hypr/wallpaper.jpg "https://picsum.photos/1920/1080"
fi
swaybg -i ~/.config/hypr/wallpaper.jpg &
EOF

    chmod +x ~/.config/hypr/set-wallpaper.sh
    
    print_success "Конфигурация Hyprland создана!"
}

# Включение служб
enable_services() {
    print_info "Включение системных служб..."
    
    # Включение SDDM
    sudo systemctl enable sddm
    
    # Включение NetworkManager
    sudo systemctl enable NetworkManager
    
    # Включение PulseAudio
    systemctl --user enable pulseaudio
    
    print_success "Службы включены!"
}

# Создание скрипта запуска
create_launch_script() {
    print_info "Создание скрипта запуска..."
    
    cat > ~/start-hyprland.sh << 'EOF'
#!/bin/bash

# Проверка Wayland сессии
if [ "$XDG_SESSION_TYPE" != "wayland" ]; then
    echo "Запуск Hyprland..."
    exec Hyprland
else
    echo "Wayland сессия уже запущена!"
fi
EOF

    chmod +x ~/start-hyprland.sh
    
    # Создание desktop файла для автозапуска
    mkdir -p ~/.config/autostart
    cat > ~/.config/autostart/hyprland-setup.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Hyprland Setup
Exec=/home/$USER/.config/hypr/set-wallpaper.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

    print_success "Скрипты запуска созданы!"
}

# Финальная настройка
final_setup() {
    print_info "Выполнение финальной настройки..."
    
    # Установка прав на шрифты
    fc-cache -fv
    
    # Создание необходимых директорий
    mkdir -p ~/.cache/{waybar,dunst}
    
    print_success "Финальная настройка завершена!"
}

# Основная функция
main() {
    print_info "Начало установки Hyprland..."
    
    check_root
    check_internet
    install_hyprland
    configure_hyprland
    enable_services
    create_launch_script
    final_setup
    
    print_success "Установка Hyprland завершена!"
    print_warning "Перезагрузите систему для применения изменений: sudo reboot"
    print_info "После перезагрузки выберите Hyprland в меню SDDM"
}

# Запуск основной функции
main "$@"