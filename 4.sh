#!/bin/bash
echo "========================================="
echo "ПРОВЕРКА УСТАНОВЛЕННЫХ ГРАФИЧЕСКИХ ОКРУЖЕНИЙ"
echo "========================================="

check_de() {
    local name=$1
    local packages=("${@:2}")
    
    for pkg in "${packages[@]}"; do
        if pacman -Q "$pkg" &>/dev/null; then
            echo "✓ $name установлен (через $pkg)"
            return 0
        fi
    done
    echo "✗ $name не установлен"
    return 1
}

# Проверка основных окружений
check_de "KDE Plasma" "plasma-desktop" "plasma" "plasma-workspace"
check_de "GNOME" "gnome-shell" "gnome-session" "gnome"
check_de "XFCE" "xfce4-session" "xfdesktop" "xfce4-panel"
check_de "Cinnamon" "cinnamon-session" "cinnamon" "nemo"
check_de "MATE" "mate-session-manager" "mate-panel" "mate-desktop"
check_de "LXQt" "lxqt-session" "lxqt-panel" "pcmanfm-qt"
check_de "LXDE" "lxde-common" "lxpanel" "pcmanfm"

echo ""
echo "Дисплей менеджер: $(systemctl status display-manager --no-pager -l | grep "Loaded:" | cut -d'(' -f2 | cut -d';' -f1)"
echo ""
echo "Доступные сессии:"
for session in /usr/share/xsessions/*.desktop; do
    if [ -f "$session" ]; then
        name=$(grep "^Name=" "$session" | cut -d'=' -f2)
        exec=$(grep "^Exec=" "$session" | cut -d'=' -f2)
        echo "  - $name ($exec)"
    fi
done