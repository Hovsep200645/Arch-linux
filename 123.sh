#!/bin/bash

# KDE Plasma Recovery Script for Fedora
# Полное восстановление рабочего состояния KDE

set -e

echo "=================================================="
echo " KDE Plasma Recovery Script"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as user (not root)
if [ "$EUID" -eq 0 ]; then
    print_error "Please run this script as regular user, not root"
    exit 1
fi

# Create backup directory
BACKUP_DIR="$HOME/kde_backup_$(date +%Y%m%d_%H%M%S)"
print_status "Creating backup in: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Backup current KDE configuration
backup_kde_config() {
    print_status "Backing up current KDE configuration..."
    
    # Backup main config directories
    [ -d "$HOME/.config" ] && cp -r "$HOME/.config" "$BACKUP_DIR/" 2>/dev/null || true
    [ -d "$HOME/.kde" ] && cp -r "$HOME/.kde" "$BACKUP_DIR/" 2>/dev/null || true
    [ -d "$HOME/.local/share/kxmlgui5" ] && cp -r "$HOME/.local/share/kxmlgui5" "$BACKUP_DIR/" 2>/dev/null || true
    
    # Specific KDE configs
    [ -f "$HOME/.config/plasmarc" ] && cp "$HOME/.config/plasmarc" "$BACKUP_DIR/" 2>/dev/null || true
    [ -f "$HOME/.config/kdeglobals" ] && cp "$HOME/.config/kdeglobals" "$BACKUP_DIR/" 2>/dev/null || true
    [ -f "$HOME/.config/kwinrc" ] && cp "$HOME/.config/kwinrc" "$BACKUP_DIR/" 2>/dev/null || true
}

# Stop KDE processes
stop_kde_processes() {
    print_status "Stopping KDE processes..."
    
    # Graceful stop
    killall plasmashell kwin_x11 krunner plasma-desktop 2>/dev/null || true
    sleep 2
    
    # Force stop if still running
    killall -9 plasmashell kwin_x11 krunner plasma-desktop 2>/dev/null || true
}

# Clear KDE cache and configs
clear_kde_cache() {
    print_status "Clearing KDE cache and configuration..."
    
    # Remove cache directories
    rm -rf "$HOME/.cache/plasmashell"
    rm -rf "$HOME/.cache/plasma*"
    rm -rf "$HOME/.cache/org.kde.*"
    rm -rf "$HOME/.cache/krunner*"
    rm -rf "$HOME/.cache/kwin*"
    
    # Remove temporary files
    rm -rf "$HOME/.tmp/kde-*"
    rm -rf "/tmp/kde-*"
    rm -rf "/tmp/plasma-*"
    
    # Remove broken configs but keep backup
    [ -d "$HOME/.config" ] && mv "$HOME/.config" "$HOME/.config.bak" 2>/dev/null || true
    [ -d "$HOME/.kde" ] && mv "$HOME/.kde" "$HOME/.kde.bak" 2>/dev/null || true
    [ -d "$HOME/.local/share/kxmlgui5" ] && mv "$HOME/.local/share/kxmlgui5" "$HOME/.local/share/kxmlgui5.bak" 2>/dev/null || true
}

# Recreate basic directory structure
recreate_dirs() {
    print_status "Recreating directory structure..."
    
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.local/share"
    mkdir -p "$HOME/.cache"
    mkdir -p "$HOME/.kde"
}

# Reset DBus and systemd user services
reset_dbus_services() {
    print_status "Resetting DBus and user services..."
    
    # Kill existing DBus session
    killall dbus-daemon 2>/dev/null || true
    
    # Reset systemd user services
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user reset-failed 2>/dev/null || true
    
    # Remove user service runtime files
    rm -rf "$HOME/.local/state/systemd/user/*"
    rm -rf "$HOME/.config/systemd/user/*.d"
}

# Rebuild KDE system configuration
rebuild_kde_config() {
    print_status "Rebuilding KDE system configuration..."
    
    # Start new DBus session if needed
    export $(dbus-launch) 2>/dev/null || true
    
    # Rebuild KDE configuration cache
    kbuildsycoca5 --noincremental 2>/dev/null || true
    
    # Reset to default theme
    kdeglobals5 --default 2>/dev/null || true
    plasmarc5 --default 2>/dev/null || true
}

# Repair package dependencies
repair_packages() {
    print_status "Checking and repairing KDE packages..."
    
    # Reinstall critical KDE packages
    sudo dnf reinstall -y \
        plasma-desktop \
        plasma-workspace \
        sddm \
        kde-settings \
        kde-globaltheme 2>/dev/null || true
    
    # Fix broken dependencies
    sudo dnf check-update 2>/dev/null || true
    sudo dnf autoremove -y 2>/dev/null || true
}

# Start KDE environment
start_kde_environment() {
    print_status "Starting KDE environment..."
    
    # Start KDE components
    kstart5 plasmashell 2>/dev/null &
    sleep 2
    kstart5 kwin_x11 2>/dev/null &
    sleep 1
    kstart5 krunner 2>/dev/null &
    
    # Final system rebuild
    sleep 5
    kbuildsycoca5 --noincremental 2>/dev/null || true
}

# Main execution
main() {
    print_warning "This script will reset your KDE configuration to defaults"
    print_warning "All current KDE settings will be backed up and reset"
    echo
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Operation cancelled"
        exit 0
    fi
    
    # Execute recovery steps
    backup_kde_config
    stop_kde_processes
    clear_kde_cache
    recreate_dirs
    reset_dbus_services
    repair_packages
    rebuild_kde_config
    start_kde_environment
    
    print_status "KDE recovery completed!"
    echo
    print_status "Backup created in: $BACKUP_DIR"
    print_status "You may need to:"
    print_status "1. Log out and log back in"
    print_status "2. Reconfigure your desktop settings"
    print_status "3. Reinstall any custom themes/plugins"
    echo
    print_warning "If problems persist, try restarting the system"
}

# Run main function
main "$@"