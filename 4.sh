#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Функции для вывода
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_debug() { echo -e "${CYAN}[DEBUG]${NC} $1"; }
print_section() { echo -e "${MAGENTA}=== $1 ===${NC}"; }

# Переменные
USER_HOME=$HOME
CONFIG_DIR="$USER_HOME/.config"
HYPR_DIR="$CONFIG_DIR/hypr"
WAYBAR_DIR="$CONFIG_DIR/waybar"
DUNST_DIR="$CONFIG_DIR/dunst"
ROFI_DIR="$CONFIG_DIR/rofi"
SCRIPTS_DIR="$HYPR_DIR/scripts"

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

# Очистка старых конфигов
cleanup_old_configs() {
    print_section "ОЧИСТКА СТАРЫХ КОНФИГОВ"
    
    print_info "Создание резервной копии..."
    BACKUP_DIR="$USER_HOME/hyprland-backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    [ -d "$HYPR_DIR" ] && cp -r "$HYPR_DIR" "$BACKUP_DIR/" 2>/dev/null
    [ -d "$WAYBAR_DIR" ] && cp -r "$WAYBAR_DIR" "$BACKUP_DIR/" 2>/dev/null
    [ -d "$DUNST_DIR" ] && cp -r "$DUNST_DIR" "$BACKUP_DIR/" 2>/dev/null
    [ -d "$ROFI_DIR" ] && cp -r "$ROFI_DIR" "$BACKUP_DIR/" 2>/dev/null
    
    print_info "Удаление старых конфигов..."
    rm -rf "$HYPR_DIR" "$WAYBAR_DIR" "$DUNST_DIR" "$ROFI_DIR"
    
    print_success "Резервная копия создана в: $BACKUP_DIR"
}

# Установка Hyprland и зависимостей
install_packages() {
    print_section "УСТАНОВКА ПАКЕТОВ"
    
    print_info "Обновление системы..."
    sudo pacman -Syu --noconfirm
    
    print_info "Установка Hyprland и Wayland..."
    sudo pacman -S --needed --noconfirm \
        hyprland \
        wayland \
        xorg-xwayland \
        mesa \
        vulkan-icd-loader \
        vulkan-intel \
        vulkan-radeon \
        nvidia \
        nvidia-utils \
        base-devel \
        git \
        cmake \
        ninja \
        gcc
    
    print_info "Установка графического менеджера (SDDM)..."
    sudo pacman -S --needed --noconfirm sddm sddm-kcm
    
    print_info "Установка основных утилит..."
    sudo pacman -S --needed --noconfirm \
        kitty \
        thunar \
        thunar-archive-plugin \
        thunar-volman \
        firefox \
        nano \
        vim \
        networkmanager \
        network-manager-applet \
        pulseaudio \
        pulseaudio-alsa \
        pulseaudio-bluetooth \
        pavucontrol \
        brightnessctl \
        playerctl \
        wl-clipboard \
        qt5-wayland \
        qt6-wayland \
        noto-fonts \
        noto-fonts-emoji \
        noto-fonts-cjk \
        ttf-jetbrains-mono \
        ttf-font-awesome \
        ttf-dejavu
    
    print_info "Установка компонентов рабочего стола..."
    sudo pacman -S --needed --noconfirm \
        waybar \
        rofi \
        rofi-calc \
        dunst \
        swaybg \
        swaylock \
        grim \
        slurp \
        wlogout \
        gammastep \
        blueman \
        blueberry \
        polkit-kde-agent \
        xdg-desktop-portal-hyprland \
        xdg-desktop-portal-gtk \
        xdg-utils \
        xdg-user-dirs
    
    print_info "Установка дополнительных утилит..."
    sudo pacman -S --needed --noconfirm \
        btop \
        htop \
        neofetch \
        cmatrix \
        cowsay \
        fortune-mod \
        lolcat \
        feh \
        imagemagick \
        mpv \
        vlc \
        viewnior \
        gparted \
        gimp \
        obs-studio \
        discord \
        telegram-desktop \
        filezilla \
        libreoffice-fresh
    
    print_success "Все пакеты установлены!"
}

# Установка AUR пакетов (опционально)
install_aur_packages() {
    print_section "УСТАНОВКА AUR ПАКЕТОВ"
    
    read -p "Установить AUR пакеты? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Установка yay..."
        if ! command -v yay &> /dev/null; then
            git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
            cd /tmp/yay-bin
            makepkg -si --noconfirm
            cd -
        fi
        
        print_info "Установка AUR пакетов..."
        yay -S --needed --noconfirm \
            hyprpicker \
            hypridle \
            hyprlock \
            eww \
            swww \
            cava \
            tty-clock \
            fastfetch \
            nitch \
            pipes.sh \
            cpufetch
    fi
}

# Создание структуры директорий
create_directories() {
    print_section "СОЗДАНИЕ СТРУКТУРЫ ДИРЕКТОРИЙ"
    
    mkdir -p "$HYPR_DIR"
    mkdir -p "$WAYBAR_DIR"
    mkdir -p "$DUNST_DIR"
    mkdir -p "$ROFI_DIR"
    mkdir -p "$SCRIPTS_DIR"
    mkdir -p "$USER_HOME/Pictures/Wallpapers"
    mkdir -p "$USER_HOME/Downloads"
    mkdir -p "$USER_HOME/Documents"
    mkdir -p "$USER_HOME/Music"
    mkdir -p "$USER_HOME/Videos"
    
    print_success "Директории созданы"
}

# Скачивание обоев
download_wallpapers() {
    print_info "Скачивание обоев..."
    
    # Скачиваем несколько обоев
    WALLPAPER_URLS=(
        "https://wallpaperaccess.com/full/3853737.jpg"
        "https://wallpaperaccess.com/full/3853738.jpg" 
        "https://wallpaperaccess.com/full/3853740.jpg"
    )
    
    for i in "${!WALLPAPER_URLS[@]}"; do
        wget -q -O "$USER_HOME/Pictures/Wallpapers/wallpaper$((i+1)).jpg" "${WALLPAPER_URLS[$i]}" &
    done
    wait
    
    print_success "Обои скачаны"
}

# Настройка основного конфига Hyprland
configure_hyprland() {
    print_section "НАСТРОЙКА HYPRLAND"
    
    cat > "$HYPR_DIR/hyprland.conf" << 'EOF'
# HYPRLAND CONFIGURATION
# Complete configuration with all features

# Monitor configuration
monitor=,preferred,auto,auto

# Autostart applications
exec-once = waybar
exec-once = dunst
exec-once = nm-applet
exec-once = blueman-applet
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = swww init
exec-once = swww img ~/Pictures/Wallpapers/wallpaper1.jpg

# Input configuration
input {
    kb_layout = us,ru
    kb_options = grp:alt_shift_toggle
    follow_mouse = 1
    touchpad {
        natural_scroll = no
        disable_while_typing = true
        clickfinger_behavior = true
    }
    sensitivity = 0.0
    accel_profile = flat
}

# General settings
general {
    gaps_in = 5
    gaps_out = 15
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) rgba(ff3399ee) rgba(ffcc00ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
    cursor_inactive_timeout = 5
    no_focus_fallback = true
}

# Decoration settings
decoration {
    rounding = 10
    blur {
        enabled = true
        size = 5
        passes = 3
        new_optimizations = true
        noise = 0.01
        contrast = 1.0
        brightness = 1.0
        vibrancy = 0.5
        vibrancy_darkness = 0.5
    }
    drop_shadow = yes
    shadow_range = 20
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
    col.shadow_inactive = rgba(1a1a1a22)
    shadow_offset = 0 2
    dim_inactive = true
    dim_strength = 0.1
}

# Animations
animations {
    enabled = yes
    
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    bezier = overshot, 0.13, 0.99, 0.29, 1.1
    bezier = smoothOut, 0.36, 0, 0.66, -0.56
    bezier = smoothIn, 0.25, 1, 0.5, 1
    bezier = wind, 0.05, 0.9, 0.1, 1.05
    bezier = winIn, 0.1, 1.1, 0.1, 1.1
    bezier = winOut, 0.3, -0.3, 0, 1
    
    animation = windows, 1, 5, myBezier, popin
    animation = windowsOut, 1, 5, smoothOut, popin
    animation = windowsMove, 1, 5, wind
    animation = border, 1, 10, default
    animation = borderangle, 1, 30, linear, loop
    animation = fade, 1, 5, smoothIn
    animation = fadeDim, 1, 5, smoothIn
    animation = workspaces, 1, 6, wind
    animation = specialWorkspace, 1, 5, myBezier, slidefadevert
}

# Dwindle layout
dwindle {
    pseudotile = yes
    preserve_split = yes
    force_split = 2
    permanent_direction_override = true
    use_active_for_splits = true
}

# Master layout
master {
    new_is_master = true
    mfact = 0.55
    orientation = left
    always_center_master = false
    special_scale_factor = 0.8
    new_on_top = false
    no_gaps_when_only = false
}

# Gestures
gestures {
    workspace_swipe = true
    workspace_swipe_fingers = 3
    workspace_swipe_distance = 250
    workspace_swipe_invert = true
    workspace_swipe_min_speed_to_force = 15
    workspace_swipe_cancel_ratio = 0.5
    workspace_swipe_create_new = true
}

# Misc settings
misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
    force_default_wallpaper = 0
    mouse_move_enables_dpms = true
    key_press_enables_dpms = true
    enable_swallow = true
    swallow_regex = ^(kitty)$
    focus_on_activate = true
    no_direct_scanout = true
    mouse_move_focuses_monitor = true
}

# Window rules
windowrule = float, ^(pavucontrol)$
windowrule = float, ^(blueman-manager)$
windowrule = float, ^(nm-connection-editor)$
windowrule = float, ^(org.gnome.Calculator)$
windowrule = float, ^(blueberry)$
windowrule = float, ^(polkit-kde-authentication-agent-1)$
windowrule = float, title:^(Firefox — Sharing Indicator)$
windowrule = float, title:^(Picture-in-Picture)$
windowrule = pin, title:^(Picture-in-Picture)$
windowrule = float, ^(imv)$
windowrule = size 800 600, ^(kitty)$
windowrule = center, ^(kitty)$
windowrule = workspace 2, ^(firefox)$
windowrule = workspace 3, ^(thunar)$
windowrule = workspace 4, ^(discord)$

# Layer rules
layerrule = blur, waybar
layerrule = ignorezero, waybar
layerrule = blur, rofi
layerrule = ignorezero, rofi

# Workspace assignments
workspace = 1, monitor:DP-1, default:true
workspace = 2, monitor:DP-1
workspace = 3, monitor:DP-1
workspace = 4, monitor:DP-1
workspace = 5, monitor:DP-1
workspace = 6, monitor:DP-1
workspace = 7, monitor:DP-1
workspace = 8, monitor:DP-1
workspace = 9, monitor:DP-1
workspace = 10, monitor:DP-1

# Key bindings - Applications
bind = SUPER, RETURN, exec, kitty
bind = SUPER, E, exec, thunar
bind = SUPER, W, exec, firefox
bind = SUPER, D, exec, rofi -show drun
bind = SUPER, F, exec, rofi -show filebrowser
bind = SUPER, C, exec, rofi -show calc -modi calc -no-show-match -no-sort
bind = SUPER, B, exec, blueberry
bind = SUPER, N, exec, nm-connection-editor
bind = SUPER, A, exec, pavucontrol

# Key bindings - System
bind = SUPER, Q, killactive,
bind = SUPER, M, exit,
bind = SUPER, L, exec, swaylock
bind = SUPER, X, exec, wlogout --protocol layer-shell
bind = SUPER, P, exec, grim -g "$(slurp)" - | wl-copy
bind = SUPER SHIFT, P, exec, grim - | wl-copy
bind = SUPER, PRINT, exec, hyprpicker -a
bind = SUPER, R, exec, hyprctl reload

# Key bindings - Window management
bind = SUPER, F, fullscreen,
bind = SUPER, SPACE, togglefloating,
bind = SUPER, O, pin,
bind = SUPER, S, togglesplit,
bind = SUPER, G, togglegroup,
bind = SUPER, TAB, changegroupactive,

# Key bindings - Focus
bind = SUPER, left, movefocus, l
bind = SUPER, right, movefocus, r
bind = SUPER, up, movefocus, u
bind = SUPER, down, movefocus, d

# Key bindings - Move windows
bind = SUPER SHIFT, left, movewindow, l
bind = SUPER SHIFT, right, movewindow, r
bind = SUPER SHIFT, up, movewindow, u
bind = SUPER SHIFT, down, movewindow, d

# Key bindings - Resize windows
bind = SUPER CTRL, left, resizeactive, -20 0
bind = SUPER CTRL, right, resizeactive, 20 0
bind = SUPER CTRL, up, resizeactive, 0 -20
bind = SUPER CTRL, down, resizeactive, 0 20

# Key bindings - Workspaces
bind = SUPER, 1, workspace, 1
bind = SUPER, 2, workspace, 2
bind = SUPER, 3, workspace, 3
bind = SUPER, 4, workspace, 4
bind = SUPER, 5, workspace, 5
bind = SUPER, 6, workspace, 6
bind = SUPER, 7, workspace, 7
bind = SUPER, 8, workspace, 8
bind = SUPER, 9, workspace, 9
bind = SUPER, 0, workspace, 10

# Key bindings - Move to workspaces
bind = SUPER SHIFT, 1, movetoworkspace, 1
bind = SUPER SHIFT, 2, movetoworkspace, 2
bind = SUPER SHIFT, 3, movetoworkspace, 3
bind = SUPER SHIFT, 4, movetoworkspace, 4
bind = SUPER SHIFT, 5, movetoworkspace, 5
bind = SUPER SHIFT, 6, movetoworkspace, 6
bind = SUPER SHIFT, 7, movetoworkspace, 7
bind = SUPER SHIFT, 8, movetoworkspace, 8
bind = SUPER SHIFT, 9, movetoworkspace, 9
bind = SUPER SHIFT, 0, movetoworkspace, 10

# Key bindings - Special workspace
bind = SUPER, minus, togglespecialworkspace, magic
bind = SUPER SHIFT, minus, movetoworkspace, special:magic

# Key bindings - Scroll through workspaces
bind = SUPER, mouse_down, workspace, e+1
bind = SUPER, mouse_up, workspace, e-1

# Key bindings - Media controls
bind = , XF86AudioRaiseVolume, exec, pamixer -i 5
bind = , XF86AudioLowerVolume, exec, pamixer -d 5
bind = , XF86AudioMute, exec, pamixer -t
bind = , XF86AudioPlay, exec, playerctl play-pause
bind = , XF86AudioNext, exec, playerctl next
bind = , XF86AudioPrev, exec, playerctl previous
bind = , XF86AudioStop, exec, playerctl stop
bind = , XF86MonBrightnessUp, exec, brightnessctl set +5%
bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

# Key bindings - Move/resize windows with mouse
bindm = SUPER, mouse:272, movewindow
bindm = SUPER, mouse:273, resizewindow

# Key bindings - Special functions
bind = SUPER, V, exec, pkill -USR1 waybar  # Toggle waybar
bind = SUPER SHIFT, B, exec, ~/.config/hypr/scripts/toggle_blur.sh
bind = SUPER SHIFT, O, exec, ~/.config/hypr/scripts/change_opacity.sh
bind = SUPER SHIFT, W, exec, ~/.config/hypr/scripts/wallpaper_random.sh
EOF

    print_success "Основной конфиг Hyprland создан!"
}

# Настройка Waybar
configure_waybar() {
    print_section "НАСТРОЙКА WAYBAR"
    
    # Основной конфиг Waybar
    cat > "$WAYBAR_DIR/config" << 'EOF'
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
    "modules-right": ["cpu", "memory", "disk", "battery", "pulseaudio", "network", "bluetooth", "tray"],
    
    "custom/launcher": {
        "format": " ",
        "on-click": "rofi -show drun",
        "tooltip": false
    },
    
    "hyprland/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "format": "{icon}",
        "format-icons": {
            "1": "",
            "2": "", 
            "3": "",
            "4": "",
            "5": "",
            "6": "",
            "7": "",
            "8": "",
            "9": "",
            "10": "",
            "urgent": "",
            "focused": "",
            "default": ""
        },
        "on-click": "activate"
    },
    
    "clock": {
        "format": "{:%H:%M}",
        "format-alt": "{:%Y-%m-%d}",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
        "interval": 1
    },
    
    "cpu": {
        "format": "{usage}% ",
        "tooltip": false,
        "interval": 2
    },
    
    "memory": {
        "format": "{}% ",
        "interval": 2
    },
    
    "disk": {
        "format": "{percentage_used}% ",
        "path": "/",
        "interval": 30
    },
    
    "battery": {
        "format": "{capacity}% {icon}",
        "format-icons": ["", "", "", "", ""],
        "format-charging": "{capacity}% ",
        "format-plugged": "{capacity}% ",
        "format-full": "{capacity}% ",
        "states": {
            "warning": 20,
            "critical": 10
        },
        "interval": 5
    },
    
    "network": {
        "format-wifi": "{essid} ({signalStrength}%) ",
        "format-ethernet": "{ifname} ",
        "format-disconnected": "Disconnected ⚠",
        "format-alt": "{ifname}: {ipaddr}/{cidr}",
        "tooltip-format": "{ifname}: {ipaddr}/{cidr}",
        "interval": 5
    },
    
    "bluetooth": {
        "format": "",
        "format-disabled": "",
        "format-connected": " {num_connections}",
        "on-click": "blueman-manager",
        "interval": 5
    },
    
    "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-muted": "",
        "format-icons": ["", "", ""],
        "on-click": "pavucontrol",
        "scroll-step": 5,
        "tooltip": false
    },
    
    "tray": {
        "icon-size": 16,
        "spacing": 8
    }
}
EOF

    # Стиль Waybar
    cat > "$WAYBAR_DIR/style.css" << 'EOF'
* {
    border: none;
    border-radius: 0;
    font-family: "JetBrains Mono", "Font Awesome 6 Free";
    font-weight: bold;
    font-size: 14px;
    min-height: 0;
}

window#waybar {
    background: rgba(21, 18, 27, 0.8);
    color: #cdd6f4;
    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

#workspaces button {
    padding: 0 8px;
    background: transparent;
    color: #cdd6f4;
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 8px;
    margin: 2px;
}

#workspaces button.active {
    background: linear-gradient(45deg, #cba6f7, #f5c2e7);
    color: #1e1e2e;
}

#workspaces button:hover {
    background: rgba(255, 255, 255, 0.1);
}

#custom-launcher {
    background: linear-gradient(45deg, #cba6f7, #f5c2e7);
    color: #1e1e2e;
    border-radius: 8px;
    padding: 0 12px;
    margin: 2px;
}

#clock, #cpu, #memory, #disk, #battery, #pulseaudio, #network, #bluetooth {
    background: rgba(255, 255, 255, 0.05);
    padding: 0 12px;
    margin: 2px;
    border-radius: 8px;
    border: 1px solid rgba(255, 255, 255, 0.1);
}

#tray {
    background: rgba(255, 255, 255, 0.05);
    padding: 0 12px;
    margin: 2px;
    border-radius: 8px;
    border: 1px solid rgba(255, 255, 255, 0.1);
}

#battery.warning {
    color: #f9e2af;
}

#battery.critical {
    color: #f38ba8;
}
EOF

    print_success "Waybar настроен!"
}

# Настройка Dunst (уведомления)
configure_dunst() {
    print_section "НАСТРОЙКА DUNST"
    
    cat > "$DUNST_DIR/dunstrc" << 'EOF'
[global]
    monitor = 0
    follow = mouse
    geometry = "300x5-30+50"
    indicate_hidden = yes
    shrink = no
    transparency = 20
    notification_height = 0
    separator_height = 2
    padding = 8
    horizontal_padding = 8
    frame_width = 2
    frame_color = "#cba6f7"
    separator_color = frame
    sort = yes
    idle_threshold = 120
    font = JetBrains Mono 10
    line_height = 0
    markup = full
    format = "<b>%s</b>\n%b"
    alignment = left
    show_age_threshold = 60
    word_wrap = yes
    ellipsize = middle
    ignore_newline = no
    stack_duplicates = true
    hide_duplicate_count = false
    show_indicators = yes
    icon_position = left
    max_icon_size = 32
    icon_path = /usr/share/icons/gnome/16x16/status/:/usr/share/icons/gnome/16x16/devices/
    sticky_history = yes
    history_length = 20
    browser = /usr/bin/firefox -new-tab
    always_run_script = true
    title = Dunst
    class = Dunst
    startup_notification = false
    verbosity = mesg
    corner_radius = 8

[shortcuts]
    close = ctrl+space
    close_all = ctrl+shift+space
    history = ctrl+grave
    context = ctrl+shift+period

[urgency_low]
    background = "#1e1e2e"
    foreground = "#cdd6f4"
    timeout = 4

[urgency_normal]
    background = "#1e1e2e" 
    foreground = "#cdd6f4"
    timeout = 6

[urgency_critical]
    background = "#1e1e2e"
    foreground = "#f38ba8"
    timeout = 0
EOF

    print_success "Dunst настроен!"
}

# Настройка Rofi
configure_rofi() {
    print_section "НАСТРОЙКА ROFI"
    
    cat > "$ROFI_DIR/config.rasi" << 'EOF'
configuration {
    modi: "drun,run,filebrowser,window";
    show-icons: true;
    terminal: "kitty";
    drun-display-format: "{name}";
    window-format: "{w}  {i}  {t}";
}

@theme "Arc-Dark"

* {
    bg-col:  #1e1e2e;
    bg-col-light: #1e1e2e;
    border-col: #cba6f7;
    selected-col: #cba6f7;
    blue: #89b4fa;
    fg-col: #cdd6f4;
    fg-col2: #f38ba8;
    grey: #6c7086;
    
    width: 800;
    font: "JetBrains Mono 12";
}

element-text, element-icon {
    background-color: inherit;
    text-color: inherit;
}

window {
    height: 360px;
    border: 2px;
    border-color: @border-col;
    border-radius: 12px;
    background-color: @bg-col;
}

mainbox {
    background-color: @bg-col;
}

inputbar {
    children: [prompt,entry];
    background-color: @bg-col;
    border-radius: 8px;
    padding: 4px;
}

prompt {
    background-color: @blue;
    padding: 4px 8px;
    border-radius: 8px;
    text-color: @bg-col;
}

textbox-prompt-colon {
    expand: false;
    str: "";
}

entry {
    background-color: inherit;
    text-color: inherit;
    placeholder: "Search...";
}

listview {
    background-color: @bg-col;
    border-radius: 8px;
    margin: 0px 4px 4px 4px;
}

element {
    background-color: inherit;
    text-color: inherit;
    border-radius: 8px;
    padding: 4px;
}

element selected {
    background-color: @selected-col;
    text-color: @bg-col;
}
EOF

    print_success "Rofi настроен!"
}

# Создание полезных скриптов
create_scripts() {
    print_section "СОЗДАНИЕ СКРИПТОВ"
    
    # Скрипт смены обоев
    cat > "$SCRIPTS_DIR/wallpaper_random.sh" << 'EOF'
#!/bin/bash
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | shuf -n 1)
swww img "$WALLPAPER" --transition-type any --transition-duration 2
dunstify "Wallpaper" "Changed to: $(basename "$WALLPAPER")" -i "$WALLPAPER"
EOF

    # Скрипт переключения blur
    cat > "$SCRIPTS_DIR/toggle_blur.sh" << 'EOF'
#!/bin/bash
CURRENT_BLUR=$(hyprctl getoption decoration:blur:enabled | grep -oP '(?<=int: ).*')
if [ "$CURRENT_BLUR" = "1" ]; then
    hyprctl keyword decoration:blur:enabled false
    dunstify "Blur" "Disabled" -i video-display
else
    hyprctl keyword decoration:blur:enabled true  
    dunstify "Blur" "Enabled" -i video-display
fi
EOF

    # Скрипт изменения прозрачности
    cat > "$SCRIPTS_DIR/change_opacity.sh" << 'EOF'
#!/bin/bash
OPACITY=$(echo -e "0.9\n0.8\n0.7\n0.6" | rofi -dmenu -p "Opacity")
if [ -n "$OPACITY" ]; then
    hyprctl keyword general:col.active_border "rgba(33ccffee) rgba(00ff99ee) rgba(ff3399ee) rgba(ffcc00ee) $OPACITY"
    dunstify "Opacity" "Changed to $OPACITY" -i preferences-desktop
fi
EOF

    # Скрипт информации о системе
    cat > "$SCRIPTS_DIR/system_info.sh" << 'EOF'
#!/bin/bash
INFO=$(neofetch --stdout)
dunstify "System Info" "$INFO" -t 10000
EOF

    # Делаем скрипты исполняемыми
    chmod +x "$SCRIPTS_DIR"/*.sh
    
    print_success "Скрипты созданы!"
}

# Включение служб
enable_services() {
    print_section "ВКЛЮЧЕНИЕ СЛУЖБ"
    
    print_info "Включение SDDM..."
    sudo systemctl enable sddm
    
    print_info "Включение NetworkManager..."
    sudo systemctl enable NetworkManager
    
    print_info "Включение Bluetooth..."
    sudo systemctl enable bluetooth
    
    print_info "Настройка пользовательских служб..."
    systemctl --user enable pulseaudio
    
    print_success "Службы включены!"
}

# Финальная настройка
final_setup() {
    print_section "ФИНАЛЬНАЯ НАСТРОЙКА"
    
    print_info "Обновление шрифтов..."
    fc-cache -fv
    
    print_info "Создание пользовательских директорий..."
    xdg-user-dirs-update
    
    print_info "Настройка прав..."
    chmod -R 755 "$CONFIG_DIR"
    
    print_info "Проверка конфигурации Hyprland..."
    if hyprctl reload; then
        print_success "Конфиг Hyprland корректен!"
    else
        print_error "В конфиге есть ошибки!"
        exit 1
    fi
    
    print_success "Финальная настройка завершена!"
}

# Показ информации после установки
show_post_install_info() {
    print_section "УСТАНОВКА ЗАВЕРШЕНА!"
    
    echo
    print_success "Hyprland полностью установлен и настроен!"
    echo
    print_info "Ключевые комбинации:"
    echo "  SUPER + Enter        - Terminal (Kitty)"
    echo "  SUPER + D            - Запуск приложений (Rofi)"
    echo "  SUPER + W            - Firefox"
    echo "  SUPER + E            - Файловый менеджер (Thunar)"
    echo "  SUPER + Q            - Закрыть окно"
    echo "  SUPER + L            - Заблокировать экран"
    echo "  SUPER + X            - Меню выхода"
    echo "  SUPER + P            - Скриншот области"
    echo "  SUPER + R            - Перезагрузить конфиг"
    echo
    print_info "Дополнительные возможности:"
    echo "  • Анимированные рабочие столы"
    echo "  • Blur эффекты"
    echo "  • Жесты для рабочих столов"
    echo "  • Кастомные скрипты в ~/.config/hypr/scripts/"
    echo "  • Waybar с системной информацией"
    echo "  • Уведомления (Dunst)"
    echo
    print_warning "Перезагрузите систему для применения изменений:"
    echo "  sudo reboot"
    echo
    print_info "После перезагрузки выберите Hyprland в меню SDDM"
}

# Основная функция
main() {
    print_section "ПОЛНАЯ ПЕРЕУСТАНОВКА HYPRLAND"
    
    check_root
    check_internet
    cleanup_old_configs
    install_packages
    install_aur_packages
    create_directories
    download_wallpapers
    configure_hyprland
    configure_waybar
    configure_dunst
    configure_rofi
    create_scripts
    enable_services
    final_setup
    show_post_install_info
    
    print_success "Процесс завершен! 🎉"
}

# Запуск
main "$@"
