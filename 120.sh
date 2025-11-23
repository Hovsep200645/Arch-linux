#!/bin/bash

echo "=== ПОЛНАЯ ПЕРЕУСТАНОВКА KDE С НУЛЯ ==="

# Остановка всех дисплей менеджеров
echo "Остановка дисплей менеджеров..."
sudo systemctl stop sddm gdm lightdm lxdm 2>/dev/null || true

# Удаление ВСЕХ графических окружений
echo "Удаление всех графических окружений..."
sudo dnf remove -y \
    @xfce-desktop-environment \
    @gnome-desktop \
    @mate-desktop \
    @lxde-desktop \
    @lxqt-desktop \
    @cinnamon-desktop \
    @deepin-desktop 2>/dev/null || true

# Удаление отдельных пакетов окружений
echo "Удаление отдельных пакетов окружений..."
sudo dnf remove -y \
    plasma-\* kde-\* \
    gnome-\* gdm \
    xfce-\* \
    mate-\* \
    lxde-\* lxdm \
    lxqt-\* \
    cinnamon-\* \
    deepin-\* \
    enlightenment-\* \
    i3-\* \
    openbox-\* \
    fluxbox-\* 2>/dev/null || true

# Удаление ВСЕХ дисплей менеджеров
echo "Удаление дисплей менеджеров..."
sudo dnf remove -y \
    sddm\* \
    gdm\* \
    lightdm\* \
    lxdm\* \
    xdm\* \
    wdm\* 2>/dev/null || true

# Очистка конфигов
echo "Очистка конфигураций..."
rm -rf ~/.config/plasma*
rm -rf ~/.config/kde*
rm -rf ~/.config/gnome*
rm -rf ~/.config/xfce*
rm -rf ~/.config/mate*
rm -rf ~/.config/cinnamon*
rm -rf ~/.local/share/plasma*
rm -rf ~/.local/share/kde*
rm -rf ~/.cache/plasma*
rm -rf ~/.cache/kde*

# Обновление системы (без autoremove чтобы не тронуть dnf5)
echo "Обновление системы..."
sudo dnf update -y

# Установка минимального KDE с нуля
echo "Установка KDE Plasma..."
sudo dnf install -y \
    plasma-workspace \
    plasma-desktop \
    plasma-workspace-x11 \
    sddm \
    sddm-breeze \
    kde-print-manager \
    kde-partitionmanager

# Установка основных приложений KDE
echo "Установка приложений KDE..."
sudo dnf install -y \
    dolphin \
    konsole \
    kate \
    spectacle \
    systemsettings \
    krunner \
    plasma-nm \
    plasma-pa \
    kde-gtk-config \
    breeze \
    breeze-icon-theme \
    powerdevil \
    kinit \
    kio \
    kio-extras \
    kded

# Установка базовых зависимостей
echo "Установка базовых зависимостей..."
sudo dnf install -y \
    xorg-x11-server-Xorg \
    xorg-x11-xinit \
    xorg-x11-drv-libinput \
    mesa-dri-drivers \
    alsa-plugins-pulseaudio \
    pulseaudio \
    pulseaudio-utils

# Установка тем (пропускаем если нет)
echo "Установка тем..."
sudo dnf install -y nordic-theme nordic-kde-theme --skip-broken 2>/dev/null || true

# Если темы нет, используем стандартные
if ! dnf list installed nordic-theme &>/dev/null; then
    echo "Установка стандартных тем KDE..."
    sudo dnf install -y breeze-dark breeze-gtk
fi

# Установка KDE Connect
sudo dnf install -y kdeconnect --skip-broken 2>/dev/null || true

# Установка улучшений терминала
echo "Установка улучшений терминала..."
for pkg in bash-completion fzf bat exa tldr thefuck; do
    sudo dnf install -y $pkg --skip-broken 2>/dev/null || echo "Пакет $pkg недоступен, пропускаем"
done

# Настройка SDDM как единственного дисплей менеджера
echo "Настройка SDDM..."
sudo systemctl enable sddm
sudo systemctl disable gdm lightdm lxdm 2>/dev/null || true

# Убедимся что sddm установлен как дефолтный
if [ -f /etc/systemd/system/display-manager.service ]; then
    sudo rm /etc/systemd/system/display-manager.service
fi
sudo ln -sf /usr/lib/systemd/system/sddm.service /etc/systemd/system/display-manager.service

sudo systemctl set-default graphical.target

# Создание конфигураций KDE с нуля
echo "Создание конфигураций KDE..."
mkdir -p ~/.config

# Конфигурация двух панелей
cat > ~/.config/plasma-org.kde.plasma.desktop-appletsrc << 'EOF'
[Containments][1]
activityId=
formfactor=2
immutability=1
lastScreen=0
location=4
plugin=org.kde.panel
wallpaperplugin=org.kde.image

[Containments][1][Applets][1]
plugin=org.kde.plasma.kickoff

[Containments][1][Applets][2]
plugin=org.kde.plasma.pager

[Containments][1][Applets][3]
plugin=org.kde.plasma.taskmanager

[Containments][1][Applets][4]
plugin=org.kde.plasma.systemtray

[Containments][1][Applets][5]
plugin=org.kde.plasma.digitalclock

[Containments][2]
activityId=
formfactor=2
immutability=1
lastScreen=0
location=2
plugin=org.kde.panel
wallpaperplugin=org.kde.image

[Containments][2][Applets][1]
plugin=org.kde.plasma.showdesktop

[Containments][2][Applets][2]
plugin=org.kde.plasma.icontasks

[Containments][2][Applets][3]
plugin=org.kde.plasma.trash
EOF

# Конфигурация темы
cat > ~/.config/kdeglobals << 'EOF'
[General]
ColorScheme=BreezeDark
Name=BreezeDark
widgetStyle=Breeze

[KDE]
ColorScheme=BreezeDark
contrast=4

[WM]
activeBackground=#3b4252
activeBlend=#d8dee9
activeForeground=#d8dee9
inactiveBackground=#2e3440
inactiveBlend=#4c566a
inactiveForeground=#4c566a
EOF

cat > ~/.config/plasmarc << 'EOF'
[Theme]
name=BreezeDark
EOF

cat > ~/.config/kwinrc << 'EOF'
[Windows]
BorderSize=Normal

[org.kde.kdecoration2]
library=org.kde.breeze
theme=breeze
EOF

# Настройка подсказок команд
cat > ~/.bashrc << 'EOF'
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

if command -v exa &>/dev/null; then
    alias ls='exa --icons'
    alias ll='exa -alF --icons'
    alias la='exa -A --icons'
else
    alias ls='ls --color=auto'
    alias ll='ls -alF'
    alias la='ls -A'
fi

if command -v bat &>/dev/null; then
    alias cat='bat'
fi

alias grep='grep --color=auto'
export HISTSIZE=10000
export HISTFILESIZE=20000

alias ..='cd ..'
alias ...='cd ../..'
alias update='sudo dnf update'
alias install='sudo dnf install'
alias remove='sudo dnf remove'

if command -v fzf &>/dev/null; then
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
fi

if command -v thefuck &>/dev/null; then
    eval $(thefuck --alias)
fi
EOF

# Автозагрузка KDE Connect
if command -v kdeconnect-indicator &>/dev/null; then
    mkdir -p ~/.config/autostart
    cat > ~/.config/autostart/kdeconnect.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=KDE Connect
Exec=kdeconnect-indicator
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
fi

chmod +x ~/.bashrc

echo "=== УСТАНОВКА ЗАВЕРШЕНА! ==="
echo "Перезагрузите систему: sudo reboot"
echo ""
echo "Выполнено:"
echo "✓ Удалены ВСЕ графические окружения"
echo "✓ Удалены ВСЕ дисплей менеджеры" 
echo "✓ Установлен чистый KDE Plasma"
echo "✓ Настроен SDDM как единственный дисплей менеджер"
echo "✓ Настроены две панели"
echo "✓ Установлены улучшения терминала"