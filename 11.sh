#!/bin/bash

set -e  # Выход при ошибке

echo "🔄 Начинаем установку базовых пакетов и настройку системы..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для проверки установки пакета
install_package() {
    local package=$1
    if pacman -Qi "$package" &> /dev/null; then
        echo -e "${YELLOW}⚠️  $package уже установлен, пропускаем...${NC}"
        return 1
    else
        echo -e "${GREEN}📦 Устанавливаем $package...${NC}"
        sudo pacman -S --noconfirm --needed "$package"
        return 0
    fi
}

# Функция для установки из AUR
install_aur_package() {
    local package=$1
    if yay -Qi "$package" &> /dev/null; then
        echo -e "${YELLOW}⚠️  $package уже установлен, пропускаем...${NC}"
        return 1
    else
        echo -e "${GREEN}📦 Устанавливаем $package из AUR...${NC}"
        yay -S --noconfirm --needed "$package"
        return 0
    fi
}

# Обновление системы
echo -e "${GREEN}🔄 Обновляем систему...${NC}"
sudo pacman -Syu --noconfirm

# Базовые утилиты
echo -e "${GREEN}📦 Устанавливаем базовые утилиты...${NC}"
base_packages=(
    "base-devel"           # Инструменты разработки
    "git"                  # Git
    "curl"                 # Curl
    "wget"                 # Wget
    "htop"                 # Мониторинг системы
    "neofetch"             # Информация о системе
    "tree"                 # Дерево каталогов
    "unzip"                # Распаковка архивов
    "p7zip"                # 7zip архиватор
    "rsync"                # Синхронизация файлов
    "sudo"                 # Sudo
    "man"                  # Мануалы
    "tmux"                 # Менеджер терминалов
    "zsh"                  # Zsh shell
    "fzf"                  # Fuzzy finder
    "ripgrep"              # Быстрый grep
    "fd"                   # Улучшенный find
    "bat"                  # Cat с подсветкой
    "exa"                  # Улучшенный ls
    "dust"                 # Анализ дискового пространства
    "bottom"               # Системный монитор
)

for package in "${base_packages[@]}"; do
    install_package "$package" || true
done

# Установка yay (AUR helper)
echo -e "${GREEN}📦 Устанавливаем yay...${NC}"
if ! command -v yay &> /dev/null; then
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd -
    rm -rf /tmp/yay
else
    echo -e "${YELLOW}⚠️  yay уже установлен${NC}"
fi

# Установка paru (альтернативный AUR helper)
echo -e "${GREEN}📦 Устанавливаем paru...${NC}"
if ! command -v paru &> /dev/null; then
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    cd /tmp/paru
    makepkg -si --noconfirm
    cd -
    rm -rf /tmp/paru
else
    echo -e "${YELLOW}⚠️  paru уже установлен${NC}"
fi

# Графические приложения
echo -e "${GREEN}📦 Устанавливаем графические приложения...${NC}"
gui_packages=(
    "firefox"              # Браузер
    "chromium"             # Браузер
    "vlc"                  # Видеоплеер
    "gimp"                 # Графический редактор
    "inkscape"             # Векторная графика
    "obs-studio"           # Запись экрана
    "libreoffice-fresh"    # Офисный пакет
    "libreoffice-fresh-ru" # Русский язык для LibreOffice
    "feh"                  # Просмотр изображений
    "viewnior"             # Просмотр изображений
    "thunar"               # Файловый менеджер
    "filezilla"            # FTP клиент
    "transmission-gtk"     # Торрент клиент
)

for package in "${gui_packages[@]}"; do
    install_package "$package" || true
done

# Мультимедиа кодеки
echo -e "${GREEN}📦 Устанавливаем кодеки...${NC}"
codec_packages=(
    "ffmpeg"
    "ffmpegthumbnailer"
    "gst-libav"
    "gst-plugins-good"
    "gst-plugins-bad"
    "gst-plugins-ugly"
)

for package in "${codec_packages[@]}"; do
    install_package "$package" || true
done

# Шрифты
echo -e "${GREEN}📦 Устанавливаем шрифты...${NC}"
font_packages=(
    "ttf-dejavu"
    "ttf-liberation"
    "noto-fonts"
    "noto-fonts-emoji"
    "ttf-nerd-fonts-symbols"
    "ttf-roboto"
    "ttf-fira-code"
)

for package in "${font_packages[@]}"; do
    install_package "$package" || true
done

# Установка пакетов из AUR
echo -e "${GREEN}📦 Устанавливаем пакеты из AUR...${NC}"
aur_packages=(
    "google-chrome"        # Chrome браузер
    "visual-studio-code-bin" # VS Code
    "spotify"              # Spotify
    "discord"              # Discord
    "teamviewer"           # TeamViewer
    "yay"                  # Обновляем yay через AUR
)

for package in "${aur_packages[@]}"; do
    install_aur_package "$package" || true
done

# Настройка APT и DPKG (для работы с deb пакетами)
echo -e "${GREEN}🔧 Настраиваем поддержку deb пакетов...${NC}"

# Установка debtap для конвертации deb пакетов
if ! command -v debtap &> /dev/null; then
    yay -S --noconfirm debtap
    sudo debtap -u  # Обновляем базу debtap
fi

# Установка dpkg (альтернативный способ)
if ! command -v dpkg &> /dev/null; then
    install_package "dpkg" || true
fi

# Создаем директории для apt (символические ссылки)
echo -e "${GREEN}📁 Создаем структуру каталогов для apt...${NC}"
sudo mkdir -p /etc/apt/sources.list.d
sudo mkdir -p /var/lib/apt/lists/partial
sudo mkdir -p /var/cache/apt/archives/partial

# Установка alien для конвертации пакетов (если нужно)
install_package "alien" || true

# Настройка Zsh как оболочки по умолчанию
echo -e "${GREEN}🐚 Настраиваем Zsh...${NC}"
if [[ $SHELL != *"zsh"* ]]; then
    chsh -s $(which zsh)
    echo -e "${GREEN}Zsh установлен как оболочка по умолчанию${NC}"
else
    echo -e "${YELLOW}Zsh уже установлен как оболочка по умолчанию${NC}"
fi

# Установка Oh My Zsh
echo -e "${GREEN}🎨 Устанавливаем Oh My Zsh...${NC}"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo -e "${YELLOW}Oh My Zsh уже установлен${NC}"
fi

# Установка полезных плагинов для Zsh
echo -e "${GREEN}🔌 Устанавливаем плагины для Zsh...${NC}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# zsh-syntax-highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
fi

# zsh-autosuggestions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
fi

# Финальное сообщение
echo -e "${GREEN}✅ Установка завершена!${NC}"
echo ""
echo -e "${YELLOW}📝 Что было установлено:${NC}"
echo "• Базовые утилиты и инструменты разработки"
echo "• Yay и Paru (AUR helpers)"
echo "• Графические приложения"
echo "• Мультимедиа кодеки"
echo "• Шрифты"
echo "• Поддержка deb пакетов через debtap"
echo "• Zsh и Oh My Zsh с плагинами"
echo ""
echo -e "${YELLOW}🚀 Полезные команды:${NC}"
echo "• debtap package.deb  # Конвертировать deb пакет"
echo "• yay -S package      # Установить из AUR"
echo "• paru -S package     # Установить из AUR (альтернатива)"
echo ""
echo -e "${GREEN}Перезагрузите систему для применения всех изменений!${NC}"