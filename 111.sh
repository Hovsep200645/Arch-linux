#!/bin/bash

echo "=== УСТАНОВКА KDE БЕЗ GROUPINSTALL В TTY ==="

# Остановка графической сессии
sudo systemctl stop sddm gdm lightdm 2>/dev/null

# Удаление старых окружений
echo "Удаление старых окружений..."
sudo dnf remove -y @xfce-desktop-environment
sudo dnf autoremove -y

# Обновление системы
echo "Обновление системы..."
sudo dnf update -y

# Установка минимального core KDE
echo "Установка базового KDE..."
sudo dnf install -y \
    plasma-workspace \
    plasma-desktop \
    plasma-workspace-x11 \
    sddm \
    sddm-breeze

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
    powerdevil

# Установка Nordic темы
echo "Установка Nordic темы..."
sudo dnf install -y \
    nordic-theme \
    nordic-kde-theme \
    papirus-icon-theme

# Установка KDE Connect
sudo dnf install -y kdeconnect

# Установка инструментов для подсказок
echo "Установка улучшений терминала..."
sudo dnf install -y \
    bash-completion \
    fzf \
    bat \
    exa \
    tldr \
    thefuck

# Настройка SDDM
echo "Настройка дисплей менеджера..."
sudo systemctl enable sddm
sudo systemctl set-default graphical.target

# Создание конфигураций KDE
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

# Конфигурация Nordic темы
cat > ~/.config/kdeglobals << 'EOF'
[General]
ColorScheme=Nordic
Name=Nordic
widgetStyle=Breeze

[KDE]
ColorScheme=Nordic
contrast=4

[WM]
activeBackground=#3b4252
activeBlend=#d8dee9
activeForeground=#d8dee9
inactiveBackground=#2e3440
inactiveBlend=#4c566a
inactiveForeground=#4c566a
EOF

# Конфигурация рабочего стола
cat > ~/.config/plasmarc << 'EOF'
[Theme]
name=Nordic
EOF

# Конфигурация окон
cat > ~/.config/kwinrc << 'EOF'
[Windows]
BorderSize=Normal

[org.kde.kdecoration2]
library=org.kde.breeze
theme=Nordic
EOF

# Настройка KDE Connect
cat > ~/.config/kdeconnect.conf << 'EOF'
[General]
name=Федора-KDE
deviceId=fedora-kde-nordic
EOF

# Настройка подсказок команд Kali
cat > ~/.bashrc << 'EOF'
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

alias ls='exa --icons'
alias ll='exa -alF --icons'
alias la='exa -A --icons'
alias cat='bat'
alias grep='grep --color=auto'

export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
eval $(thefuck --alias)

export HISTSIZE=10000
export HISTFILESIZE=20000

alias ..='cd ..'
alias ...='cd ../..'
alias update='sudo dnf update'
alias install='sudo dnf install'
alias remove='sudo dnf remove'
EOF

# Автозагрузка KDE Connect
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

chmod +x ~/.bashrc

echo "=== УСТАНОВКА ЗАВЕРШЕНА! ==="
echo "Перезагрузите систему: sudo reboot"
echo ""
echo "Будет установлено:"
echo "✓ KDE Plasma с Nordic темой"
echo "✓ Две панели"
echo "✓ KDE Connect"
echo "✓ Подсказки команд Kali"