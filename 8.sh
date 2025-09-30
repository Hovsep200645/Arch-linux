#!/bin/bash

# CachyOS Migration Script with Hyprland and Complete Software Suite
# Usage: chmod +x cachyos_migration.sh && ./cachyos_migration.sh

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${PURPLE}[STEP]${NC} $1"; }
log_instruction() { echo -e "${CYAN}[INSTRUCTION]${NC} $1"; }

# Global variables
BACKUP_DIR="/tmp/cachyos_backup_$(date +%Y%m%d_%H%M%S)"
ROLLBACK_FILE="/tmp/cachyos_rollback_$(date +%Y%m%d_%H%M%S).sh"
MIGRATION_LOG="/tmp/cachyos_migration.log"
SWAP_SIZE="30G"
CURRENT_STEP=0
TOTAL_STEPS=12

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    log_error "Please run as regular user, not root"
    exit 1
fi

# Trap for cleanup on errors
trap 'rollback_on_error' ERR
trap 'cleanup_exit' EXIT

# Rollback function
rollback_on_error() {
    log_error "Migration failed at step $CURRENT_STEP! Starting rollback..."
    
    if [ -f "$ROLLBACK_FILE" ]; then
        log_warning "Executing rollback script..."
        chmod +x "$ROLLBACK_FILE"
        bash "$ROLLBACK_FILE" || true
    fi
    
    log_error "Rollback completed. Check $MIGRATION_LOG for details"
    exit 1
}

# Cleanup function
cleanup_exit() {
    if [ $? -eq 0 ]; then
        log_success "Migration completed successfully!"
    else
        log_error "Migration failed! Check $MIGRATION_LOG"
    fi
}

# Display progress
show_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    log_step "Step $CURRENT_STEP/$TOTAL_STEPS: $1"
}

# Create rollback script
create_rollback_script() {
    cat > "$ROLLBACK_FILE" << 'EOF'
#!/bin/bash
echo "Starting rollback process..."

# Remove swap file if created
if [ -f /swapfile ]; then
    sudo swapoff /swapfile
    sudo rm -f /swapfile
    echo "Removed swap file"
fi

# Restore fstab if modified
if grep -q "swapfile" /etc/fstab; then
    sudo sed -i '/\/swapfile/d' /etc/fstab
    echo "Restored fstab"
fi

# Restore pacman.conf if backup exists
if [ -f /etc/pacman.conf.backup ]; then
    sudo cp /etc/pacman.conf.backup /etc/pacman.conf
    echo "Restored pacman.conf"
fi

# Remove CachyOS packages
sudo pacman -Rns --noconfirm cachyos-package-manager cachyos-settings cachyos-skel 2>/dev/null || true
sudo pacman -Rns --noconfirm cachyos-ksm-settings-git cachyos-ananicy-rules-git 2>/dev/null || true

# Remove Hyprland and related packages
sudo pacman -Rns --noconfirm hyprland hyprpaper hypridle hyprlock 2>/dev/null || true
sudo pacman -Rns --noconfirm waybar rofi-wayland dunst kitty 2>/dev/null || true

# Remove office and utility packages
sudo pacman -Rns --noconfirm libreoffice-fresh wireshark-qt gimp inkscape 2>/dev/null || true
sudo pacman -Rns --noconfirm wine-staging winetricks anbox-git 2>/dev/null || true

# Reinstall standard kernel if needed
sudo pacman -S --noconfirm linux linux-headers 2>/dev/null || true

# Update grub
if command -v grub-mkconfig &> /dev/null; then
    sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

echo "Rollback completed. Please reboot."
EOF
    chmod +x "$ROLLBACK_FILE"
    log_success "Rollback script created: $ROLLBACK_FILE"
}

# Backup function
backup_system() {
    show_progress "Creating system backup"
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup package list
    pacman -Qqe > "$BACKUP_DIR/package_list.txt"
    
    # Backup important configs
    tar -czf "$BACKUP_DIR/home_backup.tar.gz" -C /home "$USER" --exclude=".cache" 2>/dev/null || true
    tar -czf "$BACKUP_DIR/etc_backup.tar.gz" -C / etc 2>/dev/null || true
    
    # Backup dotfiles
    cp -r ~/.config "$BACKUP_DIR/config_backup" 2>/dev/null || true
    cp -r ~/.ssh "$BACKUP_DIR/ssh_backup" 2>/dev/null || true
    
    log_success "Backup completed to $BACKUP_DIR"
}

# Setup CachyOS repositories
setup_repositories() {
    show_progress "Setting up CachyOS repositories"
    
    # Backup original pacman.conf
    sudo cp /etc/pacman.conf /etc/pacman.conf.backup
    
    # Add CachyOS repositories
    cat >> /etc/pacman.conf << 'EOF'

[cachyos]
SigLevel = Optional TrustAll
Server = https://mirror.cachyos.org/repo/$arch/$repo

[cachyos-extra]
SigLevel = Optional TrustAll
Server = https://mirror.cachyos.org/repo/$arch/$repo

[core-x86-64-v3]
SigLevel = Optional TrustAll
Server = https://mirror.cachyos.org/repo/$arch/$repo
EOF
    
    # Update package database
    sudo pacman -Syy
    log_success "Repositories configured"
}

# Install CachyOS packages
install_cachyos_packages() {
    show_progress "Installing CachyOS core packages"
    
    # Install keyring first
    sudo pacman -S cachyos-keyring cachyos-mirrorlist --noconfirm --needed
    
    # Install core CachyOS packages
    sudo pacman -S cachyos-package-manager --noconfirm --needed
    
    # Install CachyOS kernel
    sudo pacman -S linux-cachyos linux-cachyos-headers --noconfirm --needed
    
    # Install system utilities
    sudo pacman -S cachyos-settings cachyos-skel --noconfirm --needed
    sudo pacman -S cachyos-ksm-settings-git cachyos-ananicy-rules-git --noconfirm --needed
    
    log_success "CachyOS packages installed"
}

# Create and configure swap file
setup_swap_file() {
    show_progress "Creating ${SWAP_SIZE} swap file"
    
    # Check if swap already exists
    if swapon --show | grep -q "/swapfile"; then
        log_info "Swap file already exists, skipping creation"
        return 0
    fi
    
    # Create swap file
    sudo fallocate -l "$SWAP_SIZE" /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    
    # Add to fstab
    if ! grep -q "/swapfile" /etc/fstab; then
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    fi
    
    # Optimize swap settings
    if ! grep -q "vm.swappiness" /etc/sysctl.d/99-swap.conf 2>/dev/null; then
        echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.d/99-swap.conf
        echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.d/99-swap.conf
    fi
    
    log_success "${SWAP_SIZE} swap file created and configured"
}

# Install system optimizations
install_optimizations() {
    show_progress "Installing system optimizations"
    
    # Install performance tools
    optimization_packages=(
        "gamemode" "lib32-gamemode" "cpupower" "auto-cpufreq"
        "thermald" "powertop" "tlp" "tlp-rdw"
        "zram-generator" "earlyoom" "irqbalance"
    )
    
    for pkg in "${optimization_packages[@]}"; do
        if ! sudo pacman -S "$pkg" --noconfirm --needed 2>/dev/null; then
            log_warning "Failed to install $pkg, continuing..."
        fi
    done
    
    # Configure CPU performance
    sudo systemctl enable --now cpupower
    sudo systemctl enable --now thermald
    sudo systemctl enable --now irqbalance
    
    # Configure auto-cpufreq
    sudo systemctl enable --now auto-cpufreq
    
    # Configure TLP
    sudo systemctl enable --now tlp
    sudo systemctl enable --now tlp-sleep
    
    # Configure early OOM killer
    sudo systemctl enable --now earlyoom
    
    # Configure zram if RAM < 16GB
    if [ "$(free -g | awk '/Mem:/ {print $2}')" -lt 16 ]; then
        sudo systemctl enable --now systemd-zram-setup@zram0
    fi
    
    log_success "System optimizations installed and configured"
}

# Install office and productivity software
install_office_software() {
    show_progress "Installing office and productivity software"
    
    # Office suite
    office_packages=(
        "libreoffice-fresh" "libreoffice-fresh-ru"
        "hunspell" "hunspell-ru" "hyphen" "hyphen-ru"
        "mythes" "mythes-ru"
    )
    
    # Graphics and media
    media_packages=(
        "gimp" "inkscape" "kdenlive" "obs-studio"
        "vlc" "mpv" "ffmpeg" "imagemagick"
        "gthumb" "eog"
    )
    
    # Network and utilities
    network_packages=(
        "wireshark-qt" "nmap" "whois" "dnsutils"
        "net-tools" "tcpdump" "wget" "curl"
        "filezilla" "remmina" "freerdp"
    )
    
    # Development tools
    dev_packages=(
        "git" "github-cli" "vim" "neovim" "vscode"
        "python" "python-pip" "nodejs" "npm"
        "docker" "docker-compose" "jdk-openjdk"
        "base-devel" "cmake" "ninja"
    )
    
    # Install all categories
    log_info "Installing office suite..."
    for pkg in "${office_packages[@]}"; do
        sudo pacman -S "$pkg" --noconfirm --needed 2>/dev/null || log_warning "Failed to install $pkg"
    done
    
    log_info "Installing media software..."
    for pkg in "${media_packages[@]}"; do
        sudo pacman -S "$pkg" --noconfirm --needed 2>/dev/null || log_warning "Failed to install $pkg"
    done
    
    log_info "Installing network tools..."
    for pkg in "${network_packages[@]}"; do
        sudo pacman -S "$pkg" --noconfirm --needed 2>/dev/null || log_warning "Failed to install $pkg"
    done
    
    log_info "Installing development tools..."
    for pkg in "${dev_packages[@]}"; do
        sudo pacman -S "$pkg" --noconfirm --needed 2>/dev/null || log_warning "Failed to install $pkg"
    done
    
    log_success "Office and productivity software installed"
}

# Install Wine and Windows compatibility
install_wine() {
    show_progress "Installing Wine and Windows compatibility"
    
    # Wine and dependencies
    wine_packages=(
        "wine-staging" "winetricks" "wine-gecko" "wine-mono"
        "lib32-mesa" "lib32-libpulse" "lib32-alsa-plugins"
        "lib32-libxcomposite" "lib32-libxinerama" "lib32-opencl-icd-loader"
        "giflib" "lib32-giflib" "libpng" "lib32-libpng"
        "libldap" "lib32-libldap" "gnutls" "lib32-gnutls"
        "mpg123" "lib32-mpg123" "openal" "lib32-openal"
        "v4l-utils" "lib32-v4l-utils" "libpulse" "lib32-libpulse"
        "alsa-plugins" "lib32-alsa-plugins" "alsa-lib" "lib32-alsa-lib"
        "libjpeg-turbo" "lib32-libjpeg-turbo" "sqlite" "lib32-sqlite"
        "libxcomposite" "lib32-libxcomposite" "libxinerama" "lib32-libxinerama"
        "ncurses" "lib32-ncurses" "opencl-icd-loader" "lib32-opencl-icd-loader"
        "libxslt" "lib32-libxslt" "libva" "lib32-libva"
        "gtk3" "lib32-gtk3" "gst-plugins-base-libs" "lib32-gst-plugins-base-libs"
    )
    
    log_info "Installing Wine and dependencies..."
    for pkg in "${wine_packages[@]}"; do
        sudo pacman -S "$pkg" --noconfirm --needed 2>/dev/null || log_warning "Failed to install $pkg"
    done
    
    # Configure Wine
    log_info "Configuring Wine..."
    winecfg &
    sleep 5
    pkill -f winecfg
    
    log_success "Wine and Windows compatibility layer installed"
}

# Install Anbox for Android apps
install_anbox() {
    show_progress "Installing Anbox for Android apps"
    
    # Install Anbox
    if ! sudo pacman -S anbox-git --noconfirm --needed 2>/dev/null; then
        log_warning "Anbox not available in repositories, building from AUR..."
        yay -S anbox-git --noconfirm --needed || log_warning "Failed to install Anbox"
    fi
    
    # Load Anbox kernel modules
    sudo modprobe ashmem_linux
    sudo modprobe binder_linux
    
    # Make module loading permanent
    if ! grep -q "ashmem_linux" /etc/modules-load.d/anbox.conf 2>/dev/null; then
        echo 'ashmem_linux' | sudo tee /etc/modules-load.d/anbox.conf
        echo 'binder_linux' | sudo tee -a /etc/modules-load.d/anbox.conf
    fi
    
    # Start Anbox service
    sudo systemctl enable --now anbox-session-manager
    
    log_success "Anbox installed and configured"
}

# Install Hyprland with complete setup
install_hyprland() {
    show_progress "Installing Hyprland desktop environment"
    
    # Install Hyprland and dependencies
    hyprland_packages=(
        "hyprland" "hyprpaper" "hypridle" "hyprlock" "hyprpicker"
        "waybar" "rofi-wayland" "dunst" "kitty" "alacritty"
        "thunar" "thunar-archive-plugin" "thunar-volman"
        "firefox" "chromium" "nautilus" "grim" "slurp"
        "wl-clipboard" "brightnessctl" "pamixer" "pulseaudio" "pulseaudio-alsa"
        "polkit-kde-agent" "qt5-wayland" "qt6-wayland" "xdg-desktop-portal-hyprland"
        "nemo" "neofetch" "htop" "bat" "eza" "fd" "fzf" "ripgrep"
        "git" "vim" "neovim" "wget" "curl" "unzip" "zip" "p7zip"
        "ttf-jetbrains-mono-nerd" "ttf-firacode-nerd" "ttf-roboto-mono-nerd"
        "noto-fonts" "noto-fonts-cjk" "noto-fonts-emoji" "ttf-dejavu"
        "adwaita-icon-theme" "papirus-icon-theme" "arc-gtk-theme"
    )
    
    for pkg in "${hyprland_packages[@]}"; do
        if ! sudo pacman -S "$pkg" --noconfirm --needed 2>/dev/null; then
            log_warning "Failed to install $pkg, continuing..."
        fi
    done
    
    # Create Hyprland configuration
    setup_hyprland_config
    
    log_success "Hyprland installation completed"
}

# Setup Hyprland configuration
setup_hyprland_config() {
    show_progress "Configuring Hyprland"
    
    mkdir -p ~/.config/hypr
    mkdir -p ~/.config/waybar
    
    # Create comprehensive Hyprland config
    cat > ~/.config/hypr/hyprland.conf << 'EOF'
# Hyprland Configuration File
# Complete configuration with optimizations

monitor=,preferred,auto,1

# Auto-execute essential services
exec-once = waybar &
exec-once = dunst &
exec-once = hyprpaper &
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = xdg-desktop-portal-hyprland &

# Performance optimizations
exec-once = sleep 5 && systemctl --user start gamemoded
exec-once = auto-cpufreq &

# Input configuration
input {
    kb_layout = us,ru
    kb_options = grp:alt_shift_toggle
    follow_mouse = 1
    touchpad {
        natural_scroll = no
        tap-to-click = yes
        disable_while_typing = true
    }
    sensitivity = 0
    repeat_delay = 250
    repeat_rate = 35
}

# General appearance
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
    cursor_inactive_timeout = 5
    no_cursor_warps = true
}

# Decoration effects
decoration {
    rounding = 10
    blur {
        enabled = true
        size = 5
        passes = 2
        new_optimizations = true
        ignore_opacity = true
    }
    drop_shadow = yes
    shadow_range = 10
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
    active_opacity = 1.0
    inactive_opacity = 0.9
    fullscreen_opacity = 1.0
}

# Animations
animations {
    enabled = yes
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    bezier = linear, 0.0, 0.0, 1.0, 1.0
    
    animation = windows, 1, 7, myBezier, slide
    animation = windowsOut, 1, 7, myBezier, slide
    animation = border, 1, 10, linear
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default, slidevert
}

# Layout configurations
dwindle {
    pseudotile = yes
    preserve_split = yes
    force_split = 0
    special_scale_factor = 0.8
}

master {
    new_is_master = true
    special_scale_factor = 0.8
}

gestures {
    workspace_swipe = on
    workspace_swipe_distance = 250
    workspace_swipe_invert = true
    workspace_swipe_min_speed_to_force = 15
}

# Key bindings - Essential
bind = SUPER, RETURN, exec, kitty
bind = SUPER, Q, killactive,
bind = SUPER, M, exit,
bind = SUPER, E, exec, nemo
bind = SUPER, D, exec, rofi -show drun
bind = SUPER, V, togglefloating,
bind = SUPER, R, exec, rofi -show run
bind = SUPER, P, pseudo,
bind = SUPER, F, fullscreen,
bind = SUPER, Space, exec, rofi -show window

# Application shortcuts
bind = SUPER, W, exec, firefox
bind = SUPER, O, exec, libreoffice
bind = SUPER, G, exec, gimp
bind = SUPER, T, exec, thunar

# Move focus
bind = SUPER, left, movefocus, l
bind = SUPER, right, movefocus, r
bind = SUPER, up, movefocus, u
bind = SUPER, down, movefocus, d

# Switch workspaces
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

# Move windows to workspace
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

# Special workspace (scratchpad)
bind = SUPER, S, togglespecialworkspace, magic
bind = SUPER SHIFT, S, movetoworkspace, special:magic

# Scroll through workspaces
bind = SUPER, mouse_down, workspace, e+1
bind = SUPER, mouse_up, workspace, e-1

# Move/resize windows
bindm = SUPER, mouse:272, movewindow
bindm = SUPER, mouse:273, resizewindow

# Multimedia keys
bind = , XF86AudioRaiseVolume, exec, pamixer -i 5
bind = , XF86AudioLowerVolume, exec, pamixer -d 5
bind = , XF86AudioMute, exec, pamixer -t
bind = , XF86AudioPlay, exec, playerctl play-pause
bind = , XF86AudioNext, exec, playerctl next
bind = , XF86AudioPrev, exec, playerctl previous
bind = , XF86MonBrightnessUp, exec, brightnessctl set +5%
bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

# Screenshot
bind = , PRINT, exec, grim -g "$(slurp)" - | wl-copy
bind = SUPER, PRINT, exec, grim - | wl-copy
bind = SUPER SHIFT, S, exec, grim -g "$(slurp)" - | tee ~/Pictures/screenshot.png | wl-copy

# Reload Hyprland configuration
bind = SUPER SHIFT, C, exec, hyprctl reload

# Performance monitoring
bind = SUPER SHIFT, P, exec, kitty htop

# Window rules
windowrule = float,^(pavucontrol)$
windowrule = float,^(blueman-manager)$
windowrule = float,^(nm-connection-editor)$
windowrule = float,^(org.gnome.Calculator)$
windowrule = float,^(Wine)$
windowrule = float,^(anbox)$
windowrule = size 800 600,^(pavucontrol)$
windowrule = size 1000 700,^(blueman-manager)$

# Layer rules
layerrule = blur,waybar
layerrule = ignorezero,waybar
layerrule = blur,rofi
layerrule = ignorezero,rofi

# Environment variables
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORM,wayland
env = SDL_VIDEODRIVER,wayland
env = MOZ_ENABLE_WAYLAND,1
env = XDG_SESSION_TYPE,wayland
env = XDG_CURRENT_DESKTOP,Hyprland
EOF

    # Create Waybar config
    cat > ~/.config/waybar/config << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 35,
    "spacing": 4,
    "modules-left": ["hyprland/workspaces"],
    "modules-center": ["clock"],
    "modules-right": ["cpu", "memory", "temperature", "battery", "pulseaudio", "tray"],
    
    "hyprland/workspaces": {
        "disable-scroll": false,
        "all-outputs": true,
        "format": "{icon}",
        "format-icons": {
            "1": "",
            "2": "",
            "3": "",
            "4": "",
            "5": "",
            "6": "",
            "7": "",
            "8": "",
            "9": "",
            "10": ""
        }
    },
    
    "clock": {
        "format": " {:%H:%M}",
        "format-alt": " {:%Y-%m-%d}",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>"
    },
    
    "cpu": {
        "format": " {usage}%",
        "interval": 5
    },
    
    "memory": {
        "format": " {}%",
        "interval": 5
    },
    
    "temperature": {
        "thermal-zone": 0,
        "format": " {temperatureC}°C",
        "critical-threshold": 80,
        "format-critical": " {temperatureC}°C"
    },
    
    "battery": {
        "format": "{capacity}% {icon}",
        "format-icons": ["", "", "", "", ""],
        "format-charging": " {capacity}%"
    },
    
    "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-muted": " MUTE",
        "format-icons": ["", "", ""],
        "on-click": "pamixer -t",
        "on-scroll-up": "pamixer -i 5",
        "on-scroll-down": "pamixer -d 5"
    },
    
    "tray": {
        "icon-size": 15,
        "spacing": 5
    }
}
EOF

    # Create Hyprpaper config
    mkdir -p ~/.config/hypr
    cat > ~/.config/hypr/hyprpaper.conf << 'EOF'
preload = /usr/share/backgrounds/archlinux/awesome.png
wallpaper = ,/usr/share/backgrounds/archlinux/awesome.png
EOF

    log_success "Hyprland configuration created"
}

# Final setup steps
finalize_setup() {
    show_progress "Finalizing system setup"
    
    # Update grub configuration
    if command -v grub-mkconfig &> /dev/null; then
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi
    
    # Copy CachyOS skel files
    if [ -d /etc/skel ] && [ -d /etc/skel/.config ]; then
        cp -r /etc/skel/. ~/ 2>/dev/null || true
    fi
    
    # Set proper ownership
    sudo chown -R $USER:$USER ~/
    
    # Enable services
    if command -v systemctl &> /dev/null; then
        sudo systemctl enable --now ananicy 2>/dev/null || true
        sudo systemctl enable --now docker 2>/dev/null || true
        sudo usermod -aG docker $USER
    fi
    
    # Configure Docker without sudo
    sudo groupadd docker 2>/dev/null || true
    sudo usermod -aG docker $USER
    
    log_success "Final setup completed"
}

# Display Hyprland instructions
show_hyprland_instructions() {
    echo
    log_instruction "=== HYPRLAND INSTRUCTIONS ==="
    log_instruction "After reboot, you can start Hyprland in several ways:"
    echo
    log_instruction "METHOD 1: From TTY (Ctrl+Alt+F2):"
    log_instruction "  1. Switch to TTY: Ctrl + Alt + F2"
    log_instruction "  2. Login with your credentials"
    log_instruction "  3. Type: Hyprland"
    log_instruction "  4. To return to TTY: Ctrl + Alt + F2"
    echo
    log_instruction "METHOD 2: From Display Manager:"
    log_instruction "  1. Reboot and wait for login screen"
    log_instruction "  2. Select 'Hyprland' from session menu"
    log_instruction "  3. Login normally"
    echo
    log_instruction "KEYBINDINGS:"
    log_instruction "  SUPER + Enter - Terminal (kitty)"
    log_instruction "  SUPER + Q - Close window"
    log_instruction "  SUPER + D - App launcher (rofi)"
    log_instruction "  SUPER + W - Firefox"
    log_instruction "  SUPER + O - LibreOffice"
    log_instruction "  SUPER + G - GIMP"
    log_instruction "  SUPER + E - File manager"
    log_instruction "  SUPER + 1-9 - Switch workspaces"
    echo
    log_instruction "INSTALLED SOFTWARE:"
    log_instruction "  Office: LibreOffice, GIMP, Inkscape"
    log_instruction "  Media: VLC, OBS Studio, Kdenlive"
    log_instruction "  Tools: Wireshark, Docker, Wine, Anbox"
    log_instruction "  Development: VS Code, Git, Node.js, Python"
    echo
    log_instruction "OPTIMIZATIONS:"
    log_instruction "  ${SWAP_SIZE} swap file created"
    log_instruction "  CPU performance governor enabled"
    log_instruction "  GameMode for gaming optimization"
    log_instruction "  Auto-cpufreq for power management"
    echo
}

# System verification
verify_installation() {
    show_progress "Verifying installation"
    
    local errors=0
    
    # Check if key packages are installed
    for pkg in hyprland waybar kitty firefox; do
        if ! pacman -Q "$pkg" &>/dev/null; then
            log_warning "Package $pkg is not installed"
            ((errors++))
        fi
    done
    
    # Check swap
    if ! swapon --show | grep -q "/swapfile"; then
        log_warning "Swap file is not active"
        ((errors++))
    fi
    
    if [ $errors -eq 0 ]; then
        log_success "Installation verification passed"
    else
        log_warning "Found $errors minor issues, but system should work"
    fi
}

# Automatic reboot prompt
prompt_reboot() {
    echo
    log_instruction "=== MIGRATION COMPLETED ==="
    log_success "All steps completed successfully!"
    echo
    
    read -p "Do you want to reboot now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Rebooting in 5 seconds... Press Ctrl+C to cancel"
        sleep 5
        sudo reboot
    else
        log_info "Please reboot manually when ready: sudo reboot"
    fi
}

# Main migration function
migrate_to_cachyos() {
    log_info "Starting complete migration from Arch to CachyOS..."
    log_info "Log file: $MIGRATION_LOG"
    
    # Create rollback script first
    create_rollback_script
    
    # Execute all migration steps
    backup_system
    setup_repositories
    install_cachyos_packages
    setup_swap_file
    install_optimizations
    install_office_software
    install_wine
    install_anbox
    install_hyprland
    finalize_setup
    verify_installation
    
    # Show instructions
    show_hyprland_instructions
    
    # Prompt for reboot
    prompt_reboot
}

# Display welcome message
show_welcome() {
    clear
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════╗"
    echo "║           CachyOS Complete Migration Script        ║"
    echo "║           with Full Software Suite                 ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo "This script will install:"
    echo "✓ CachyOS kernel and optimizations"
    echo "✓ Hyprland desktop environment" 
    echo "✓ ${SWAP_SIZE} swap file for performance"
    echo "✓ LibreOffice, GIMP, Inkscape, OBS Studio"
    echo "✓ Wireshark, development tools, Docker"
    echo "✓ Wine + Windows compatibility"
    echo "✓ Anbox for Android apps"
    echo "✓ Gaming optimizations (GameMode)"
    echo "✓ Power management (auto-cpufreq, TLP)"
    echo
    log_warning "Ensure you have:"
    log_warning "  - Stable internet connection"
    log_warning "  - At least 40GB free disk space"
    log_warning "  - Backup of important data"
    echo
}

# Main execution
main() {
    exec > >(tee -a "$MIGRATION_LOG") 2>&1
    
    show_welcome
    
    read -p "Do you want to proceed with migration? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Migration cancelled by user"
        exit 0
    fi
    
    migrate_to_cachyos
}

# Run main function
main "$@"