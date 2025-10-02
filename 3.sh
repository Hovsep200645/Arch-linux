#!/bin/bash

# CachyOS GNOME Setup Script with Swap
# Usage: chmod +x cachyos_gnome_setup.sh && ./cachyos_gnome_setup.sh

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

# Configuration
SWAP_SIZE="15G"
CURRENT_STEP=0
TOTAL_STEPS=6

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    log_error "Please run as regular user, not root. Use sudo when needed."
    exit 1
fi

# Display progress
show_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    log_step "Step $CURRENT_STEP/$TOTAL_STEPS: $1"
}

# Check available disk space
check_disk_space() {
    local available_space
    available_space=$(df / | awk 'NR==2 {print $4}')
    local required_space=16000000  # 16GB in KB
    
    if [ "$available_space" -lt "$required_space" ]; then
        log_error "Not enough disk space. Required: 16GB, Available: $((available_space / 1024 / 1024))GB"
        exit 1
    fi
    log_success "Disk space check passed"
}

# Create and configure swap file
setup_swap_file() {
    show_progress "Creating ${SWAP_SIZE} swap file"
    
    # Check if swap already exists
    if swapon --show | grep -q "/swapfile"; then
        log_info "Swap file already exists, recreating..."
        sudo swapoff /swapfile 2>/dev/null || true
        sudo rm -f /swapfile
    fi
    
    # Check disk space
    check_disk_space
    
    # Create swap file
    log_info "Creating swap file of size ${SWAP_SIZE}..."
    sudo fallocate -l "$SWAP_SIZE" /swapfile
    
    # Set secure permissions
    sudo chmod 600 /swapfile
    
    # Make it a swap file
    log_info "Formatting swap file..."
    sudo mkswap /swapfile
    
    # Enable swap
    log_info "Enabling swap..."
    sudo swapon /swapfile
    
    # Add to fstab if not already there
    if ! grep -q "/swapfile" /etc/fstab; then
        log_info "Adding swap to fstab..."
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    fi
    
    # Optimize swap settings
    log_info "Optimizing swap settings..."
    sudo tee /etc/sysctl.d/99-cachyos-swap.conf > /dev/null << EOF
# CachyOS Swap Optimizations
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.dirty_ratio=15
vm.dirty_background_ratio=5
vm.watermark_scale_factor=200
EOF
    
    # Apply settings immediately
    sudo sysctl --system
    
    log_success "${SWAP_SIZE} swap file created and optimized"
}

# Install CachyOS repositories
setup_cachyos_repos() {
    show_progress "Setting up CachyOS repositories"
    
    # Backup original pacman.conf
    if [ ! -f /etc/pacman.conf.backup ]; then
        sudo cp /etc/pacman.conf /etc/pacman.conf.backup
    fi
    
    # Add CachyOS repositories if not already present
    if ! grep -q "cachyos" /etc/pacman.conf; then
        log_info "Adding CachyOS repositories..."
        sudo tee -a /etc/pacman.conf > /dev/null << EOF

[cachyos]
SigLevel = Optional TrustAll
Server = https://mirror.cachyos.org/repo/\$arch/\$repo

[cachyos-extra]
SigLevel = Optional TrustAll
Server = https://mirror.cachyos.org/repo/\$arch/\$repo
EOF
    fi
    
    # Update package database
    log_info "Updating package database..."
    sudo pacman -Syy
    
    # Install CachyOS keyring if needed
    if ! pacman -Q cachyos-keyring &>/dev/null; then
        log_info "Installing CachyOS keyring..."
        sudo pacman -S cachyos-keyring --noconfirm --needed
    fi
    
    log_success "CachyOS repositories configured"
}

# Install CachyOS GNOME packages
install_gnome_packages() {
    show_progress "Installing CachyOS GNOME packages and optimizations"
    
    # CachyOS optimization packages
    log_info "Installing CachyOS optimization packages..."
    cachyos_packages=(
        "cachyos-gnome-settings"
        "cachyos-settings"
        "cachyos-skel"
        "cachyos-ksm-settings-git"
        "cachyos-ananicy-rules-git"
        "cachyos-zram-config"
        "cachyos-browser-settings"
        "cachyos-package-manager"
    )
    
    for pkg in "${cachyos_packages[@]}"; do
        if ! pacman -Q "$pkg" &>/dev/null; then
            log_info "Installing $pkg..."
            yay -S "$pkg" --noconfirm --needed 2>/dev/null || \
            sudo pacman -S "$pkg" --noconfirm --needed 2>/dev/null || \
            log_warning "Failed to install $pkg"
        else
            log_info "$pkg already installed"
        fi
    done
    
    # Performance optimization packages
    log_info "Installing performance packages..."
    performance_packages=(
        "ananicy-cpp"
        "auto-cpufreq"
        "gamemode"
        "cpupower"
        "thermald"
        "irqbalance"
        "earlyoom"
    )
    
    for pkg in "${performance_packages[@]}"; do
        sudo pacman -S "$pkg" --noconfirm --needed 2>/dev/null || \
        log_warning "Failed to install $pkg"
    done
    
    # GNOME optimization packages
    log_info "Installing GNOME enhancements..."
    gnome_packages=(
        "gnome-shell-extension-appindicator"
        "gnome-shell-extension-dash-to-dock"
        "gnome-shell-extension-arc-menu"
        "gnome-shell-extension-blur-my-shell"
        "gnome-shell-extension-tray-icons-reloaded"
        "gnome-shell-extension-vitals"
        "gnome-tweaks"
        "gnome-shell-extensions"
        "gdm-tools"
    )
    
    for pkg in "${gnome_packages[@]}"; do
        sudo pacman -S "$pkg" --noconfirm --needed 2>/dev/null || \
        log_warning "Failed to install $pkg"
    done
    
    log_success "GNOME packages and optimizations installed"
}

# Configure system services
configure_services() {
    show_progress "Configuring system services"
    
    # Enable performance services
    log_info "Enabling performance services..."
    
    services=(
        "ananicy-cpp"
        "auto-cpufreq"
        "thermald"
        "irqbalance"
        "earlyoom"
        "fstrim.timer"
    )
    
    for service in "${services[@]}"; do
        if systemctl list-unit-files | grep -q "$service"; then
            sudo systemctl enable --now "$service" 2>/dev/null && \
            log_info "Enabled $service" || \
            log_warning "Failed to enable $service"
        fi
    done
    
    # Configure GNOME autostart
    log_info "Configuring GNOME autostart..."
    
    # Create autostart directory
    mkdir -p ~/.config/autostart
    
    # Create performance autostart entry
    cat > ~/.config/autostart/cachyos-performance.desktop << EOF
[Desktop Entry]
Type=Application
Name=CachyOS Performance
Exec=gamemoded -d
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Comment=CachyOS Performance Optimizations
EOF
    
    log_success "System services configured"
}

# Apply GNOME optimizations
apply_gnome_optimizations() {
    show_progress "Applying GNOME optimizations"
    
    # Check if GNOME is running
    if [ "$XDG_CURRENT_DESKTOP" != "GNOME" ]; then
        log_warning "GNOME is not running. Some optimizations may not apply."
    fi
    
    # Apply CachyOS GNOME settings
    log_info "Applying CachyOS GNOME settings..."
    
    # Copy CachyOS settings if available
    if [ -d /etc/skel/.config ] && [ -d /usr/share/cachyos-settings ]; then
        log_info "Copying CachyOS configuration..."
        cp -r /etc/skel/.config/* ~/.config/ 2>/dev/null || true
        cp -r /etc/skel/.local/* ~/.local/ 2>/dev/null || true
    fi
    
    # Enable GNOME extensions
    log_info "Enabling recommended GNOME extensions..."
    
    # Enable extensions via gsettings
    extensions=(
        "appindicatorsupport@rgcjonas.gmail.com"
        "dash-to-dock@micxgx.gmail.com"
        "arc-menu@linxgem33.com"
        "blur-my-shell@aunetx"
        "trayIconsReloaded@selfmade.pl"
        "Vitals@CoreCoding.com"
    )
    
    for extension in "${extensions[@]}"; do
        if gnome-extensions list | grep -q "$extension"; then
            gnome-extensions enable "$extension" 2>/dev/null && \
            log_info "Enabled extension: $extension" || \
            log_warning "Failed to enable extension: $extension"
        fi
    done
    
    # Apply performance settings
    log_info "Applying performance settings..."
    
    # GPU acceleration
    gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"
    
    # Animation settings
    gsettings set org.gnome.desktop.interface enable-animations true
    
    # Power settings
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
    
    log_success "GNOME optimizations applied"
}

# Display results and instructions
show_results() {
    show_progress "Finalizing setup"
    
    echo
    log_success "=== CACHYOS GNOME SETUP COMPLETED ==="
    echo
    
    # Display swap information
    swap_info=$(swapon --show --bytes | grep /swapfile)
    if [ -n "$swap_info" ]; then
        swap_size=$(echo "$swap_info" | awk '{print $3}')
        swap_size_gb=$((swap_size / 1024 / 1024 / 1024))
        log_info "Swap file: ${swap_size_gb}GB active"
    else
        log_warning "Swap file not active"
    fi
    
    # Display installed packages count
    cachyos_packages_count=$(pacman -Q | grep -c cachyos)
    log_info "CachyOS packages installed: $cachyos_packages_count"
    
    # Display service status
    echo
    log_info "Service Status:"
    for service in ananicy-cpp auto-cpufreq thermald irqbalance; do
        if systemctl is-active --quiet "$service"; then
            echo -e "  ${GREEN}✓${NC} $service: Active"
        else
            echo -e "  ${YELLOW}⚠${NC} $service: Inactive"
        fi
    done
    
    # Display recommendations
    echo
    log_info "Recommended next steps:"
    echo "  1. Reboot to apply all changes: sudo reboot"
    echo "  2. Open GNOME Tweaks to customize appearance"
    echo "  3. Check GNOME Extensions to enable/configure extensions"
    echo "  4. Configure auto-cpufreq if needed: sudo auto-cpufreq --stats"
    echo
    log_info "Swap monitoring:"
    echo "  Check swap usage: free -h"
    echo "  Check swap activity: sudo swapon --show"
    echo
    log_warning "If you experience issues:"
    echo "  - Check swap: sudo swapon --show"
    echo "  - Restart GNOME: Alt+F2, then type 'r'"
    echo "  - Reset GNOME settings: gsettings reset-recursively org.gnome"
    
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

# Main execution function
main() {
    clear
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║           CachyOS GNOME Setup Script         ║"
    echo "║           with 15GB Swap File                ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo "This script will:"
    echo "✓ Create 15GB swap file for better performance"
    echo "✓ Install CachyOS repositories and keyring"
    echo "✓ Install CachyOS GNOME settings and optimizations"
    echo "✓ Install performance packages (auto-cpufreq, gamemode)"
    echo "✓ Configure GNOME extensions and optimizations"
    echo "✓ Enable system services for better performance"
    echo
    log_warning "Requirements:"
    log_warning "  - Stable internet connection"
    log_warning "  - At least 20GB free disk space"
    log_warning "  - GNOME desktop environment (recommended)"
    echo
    
    read -p "Do you want to proceed? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Setup cancelled"
        exit 0
    fi
    
    # Execute setup steps
    setup_swap_file
    setup_cachyos_repos
    install_gnome_packages
    configure_services
    apply_gnome_optimizations
    show_results
}

# Run main function
main "$@"