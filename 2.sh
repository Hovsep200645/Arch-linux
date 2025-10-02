#!/bin/bash

# Скрипт установки KDE Plasma (X11) и удаления GNOME
# Проверяем, что запущено из-под sudo
if [ "$EUID" -ne 0 ]; then
    echo "Пожалуйста, запустите скрипт с sudo:"
    echo "sudo ./install_kde.sh"
    exit 1
fi

echo "========================================"
echo " Установка KDE Plasma (X11) и удаление GNOME"
echo "========================================"

# Обновление системы
echo "[1/7] Обновление системы..."
pacman -Syu --noconfirm

# Установка KDE Plasma (X11 версия)
echo "[2/7] Установка KDE Plasma..."
pacman -S --noconfirm \
    plasma-meta \
    plasma-desktop \
    plasma-workspace \
    plasma-pa \
    plasma-nm \
    dolphin \
    konsole \
    kate \
    spectacle \
    gwenview \
    okular \
    ark \
    filelight \
    kcalc \
    ksystemlog \
    sddm \
    sddm-kcm \
    xorg-server \
    xorg-xinit \
    xorg-xrandr \
    xorg-xset \
    xorg-xprop \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-emoji \
    ttf-dejavu \
    ttf-liberation

# Установка дополнительных приложений KDE (опционально)
echo "[3/7] Установка дополнительных приложений KDE..."
pacman -S --noconfirm \
    kdegraphics-thumbnailers \
    kde-gtk-config \
    kdesu \
    kdialog \
    kinfocenter \
    khelpcenter \
    plasma-systemmonitor

# Включение SDDM
echo "[4/7] Настройка дисплей менеджера..."
systemctl enable sddm

# Настройка X11 как сессии по умолчанию
echo "[5/7] Настройка X11 сессии..."
if [ -f /etc/sddm.conf ]; then
    cp /etc/sddm.conf /etc/sddm.conf.backup
fi

# Создаем конфиг для SDDM с X11
cat > /etc/sddm.conf << 'EOF'
[Autologin]
Relogin=false
Session=
User=

[General]
HaltCommand=
RebootCommand=

[Theme]
Current=breeze
CursorTheme=breeze_cursors
Font=Noto Sans,10,-1,5,50,0,0,0,0,0

[Users]
MaximumUid=65000
MinimumUid=1000

[Wayland]
Enable=false

[X11]
Enable=true
EOF

# Удаление GNOME (осторожно!)
echo "[6/7] Удаление GNOME..."
# Сначала удаляем пакеты GNOME
pacman -Rns --noconfirm \
    gnome-shell \
    gnome-session \
    gnome-terminal \
    nautilus \
    gedit \
    gnome-control-center \
    gnome-system-monitor \
    gnome-calculator \
    gnome-disk-utility \
    gnome-software \
    gnome-keyring \
    gdm \
    mutter \
    baobab \
    eog \
    evince \
    file-roller \
    gnome-backgrounds \
    gnome-font-viewer \
    gnome-screenshot \
    gnome-themes-extra

# Удаляем зависимости GNOME
echo "[7/7] Очистка оставшихся зависимостей..."
pacman -Rns $(pacman -Qtdq) 2>/dev/null || true

echo "========================================"
echo " Установка завершена!"
echo "========================================"
echo ""
echo "Что было сделано:"
echo "✓ Установлен KDE Plasma с X11"
echo "✓ Настроен SDDM как дисплей менеджер"
echo "✓ Отключен Wayland"
echo "✓ Удалены пакеты GNOME"
echo "✓ Очищены ненужные зависимости"
echo ""
echo "Перезагрузите систему:"
echo "sudo reboot"
echo ""
echo "После перезагрузки выберите сессию 'Plasma (X11)'"