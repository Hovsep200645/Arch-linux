#!/bin/bash

# Скрипт перехода с XFCE на KDE Plasma с настройкой Nordic стиля
# Для Fedora Linux

echo "=== Начинаем переход на KDE Plasma ==="

# Обновление системы
echo "Обновление системы..."
sudo dnf update -y

# Установка KDE Plasma
echo "Установка KDE Plasma..."
sudo dnf groupinstall -y "KDE Plasma Workspaces"

# Установка дополнительных компонентов KDE
echo "Установка дополнительных компонентов KDE..."
sudo dnf install -y \
    kde-globaltheme \
    kdeartwork \
    dolphin \
    konsole \
    kate \
    spectacle \
    gwenview \
    okular \
    ark \
    kcalc \
    ksystemlog \
    kdeconnect \
    sddm \
    sddm-breeze

# Удаление XFCE (опционально, если хотите полностью убрать XFCE)
echo "Удаление XFCE..."
sudo dnf remove -y @xfce-desktop-environment
sudo dnf autoremove -y

# Установка Nordic темы
echo "Установка Nordic темы..."
sudo dnf install -y \
    nordic-theme \
    nordic-kde-theme \
    papirus-icon-theme

# Установка шрифтов
echo "Установка шрифтов..."
sudo dnf install -y \
    google-noto-fonts \
    google-noto-fonts-common \
    google-noto-cjk-fonts \
    fontawesome-fonts

# Установка инструментов для подсказок команд (как в Kali)
echo "Установка инструментов для подсказок команд..."
sudo dnf install -y \
    bash-completion \
    fish \
    zsh \
    powerline \
    powerline-fonts \
    fzf \
    bat \
    exa \
    tldr \
    thefuck

# Настройка bash с улучшенными подсказками
echo "Настройка улучшенных подсказок команд..."
cat > ~/.bashrc << 'EOF'
# Kali-style command enhancements
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Enable bash completion
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

# Aliases for better command experience
alias ls='exa --icons'
alias ll='exa -alF --icons'
alias la='exa -A --icons'
alias cat='bat'
alias find='fdfind'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# FZF configuration
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# Powerline for bash
if [ -f `which powerline-daemon` ]; then
  powerline-daemon -q
  POWERLINE_BASH_CONTINUATION=1
  POWERLINE_BASH_SELECT=1
  . /usr/share/powerline/bash/powerline.sh
fi

# The Fuck alias
eval $(thefuck --alias)

# Color support for ls
export LS_COLORS='di=1;34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'

# Enhanced history
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth
shopt -s histappend

# Custom functions for Kali-like experience
command_not_found_handle() {
    echo "Команда '$1' не найдена."
    echo "Похожие команды:"
    compgen -c | grep "$1" | head -10
}

# Quick directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Git enhancements
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'

# System monitoring
alias psmem='ps auxf | sort -nr -k 4'
alias pscpu='ps auxf | sort -nr -k 3'

# Network
alias ports='netstat -tulanp'

# Safety nets
alias rm='rm -I --preserve-root'
alias mv='mv -i'
alias cp='cp -i'
alias ln='ln -i'

# Package management shortcuts
alias update='sudo dnf update'
alias install='sudo dnf install'
alias remove='sudo dnf remove'
alias search='sudo dnf search'

EOF

# Настройка fish shell (альтернатива с лучшими подсказками)
echo "Настройка Fish shell..."
sudo dnf install -y fish
chsh -s /usr/bin/fish

# Конфигурация Fish shell
mkdir -p ~/.config/fish
cat > ~/.config/fish/config.fish << 'EOF'
# Fish configuration for Kali-like experience

# Theme
set fish_greeting ""

# Aliases
alias ls "exa --icons"
alias ll "exa -l --icons"
alias la "exa -a --icons"
alias cat "bat"
alias find "fdfind"

# Environment
set -gx EDITOR kate

# FZF
set -gx FZF_DEFAULT_OPTS '--height 40% --layout=reverse --border'

# Path
set -gx PATH $PATH ~/.local/bin

function fish_prompt
    set_color brblue
    echo -n (prompt_pwd)
    set_color normal
    echo -n ' \$ '
end
EOF

# Установка Starship prompt (современные подсказки)
echo "Установка Starship prompt..."
curl -sS https://starship.rs/install.sh | sh -s -- -y

# Конфигурация Starship
mkdir -p ~/.config
cat > ~/.config/starship.toml << 'EOF'
format = """
$username\
$hostname\
$directory\
$git_branch\
$git_state\
$git_status\
$cmd_duration\
$line_break\
$python\
$character"""

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"

[directory]
truncation_length = 3
truncate_to_repo = false

[hostname]
ssh_only = false
format = "[@$hostname](bold red) "
disabled = false

[username]
show_always = true
format = "[$user](bold blue) "
EOF

# Добавляем Starship в bash
echo 'eval "$(starship init bash)"' >> ~/.bashrc

# Настройка SDDM как дисплей менеджера по умолчанию
echo "Настройка дисплей менеджера..."
sudo systemctl enable sddm
sudo systemctl set-default graphical.target

# Создание конфигурационных файлов для KDE
echo "Создание конфигураций KDE..."

# Создаем папку для конфигураций если её нет
mkdir -p ~/.config

# Конфигурация панелей (две панели как на фото)
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

# Конфигурация темы Nordic
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

[Wallpapers]
usersWallpapers=/usr/share/backgrounds/
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
echo "Настройка KDE Connect..."
cat > ~/.config/kdeconnect.conf << 'EOF'
[General]
name=Федора-PC
deviceId=fedora-kde-nordic
EOF

# Установка приложений в автозагрузку
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/org.kde.kdeconnect.daemon.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=KDE Connect
Exec=kdeconnect-cli --name Федора-PC
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# Финальные настройки
echo "Применение настроек..."

# Установка прав на конфигурационные файлы
chmod +x ~/.bashrc

# Создание ссылок для удобства
ln -sf ~/.bashrc ~/.bash_profile

echo "=== Установка завершена! ==="
echo "Перезагрузите систему для применения всех изменений:"
echo "sudo reboot"
echo ""
echo "После перезагрузки:"
echo "1. Будет загружена KDE Plasma с Nordic темой"
echo "2. Будут доступны две панели как на фото"
echo "3. KDE Connect будет настроен"
echo "4. Команды будут подсказываться как в Kali Linux"
echo "5. Доступны улучшенные alias и функции"