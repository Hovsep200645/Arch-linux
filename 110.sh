#!/bin/bash

echo "=== УСТАНОВКА KDE БЕЗ GROUPINSTALL В TTY ==="

# Остановка графической сессии
sudo systemctl stop sddm gdm lightdm 2>/dev/null

# Удаление только XFCE без autoremove
echo "Удаление XFCE..."
sudo dnf remove -y @xfce-desktop-environment

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

# Установка Nordic темы (пропускаем если нет)
echo "Установка Nordic темы..."
sudo dnf install -y nordic-theme nordic-kde-theme --skip-broken 2>/dev/null || true

# Если темы нет, используем стандартные темы
if ! dnf list installed nordic-theme &>/dev/null; then
    echo "Установка стандартных тем KDE..."
    sudo dnf install -y breeze-dark breeze-gtk
fi

# Установка KDE Connect
sudo dnf install -y kdeconnect --skip-broken 2>/dev/null || true

# Установка инструментов для подсказок (только доступные пакеты)
echo "Установка улучшений терминала..."
sudo dnf install -y bash-completion --skip-broken 2>/dev/null || true

# Пробуем установить остальные пакеты по одному
for pkg in fzf bat exa tldr thefuck; do
    sudo dnf install -y $pkg --skip-broken 2>/dev/null || echo "Пакет $pkg недоступен, пропускаем"
done

# Настройка SDDM
echo "Настройка дисплей менеджера..."
sudo systemctl enable sddm
sudo systemctl disable lightdm gdm 2>/dev/null || true
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

# Конфигурация рабочего стола
cat > ~/.config/plasmarc << 'EOF'
[Theme]
name=BreezeDark
EOF

# Конфигурация окон
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

# Проверяем и устанавливаем алиасы только для установленных пакетов
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

# FZF если установлен
if command -v fzf &>/dev/null; then
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
fi

# The Fuck если установлен
if command -v thefuck &>/dev/null; then
    eval $(thefuck --alias)
fi
EOF

# Автозагрузка KDE Connect если установлен
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
echo "Установлено:"
echo "✓ KDE Plasma"
echo "✓ Две панели"
echo "✓ Темная тема"
if command -v kdeconnect-indicator &>/dev/null; then
    echo "✓ KDE Connect"
fi
echo "✓ Улучшения терминала"