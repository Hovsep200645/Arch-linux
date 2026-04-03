#!/bin/bash

# Цвета для красоты (как ты любишь)
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}>>> Начинаю настройку Wine для Intel Celeron N2820...${NC}"

# 1. Добавление архитектуры и обновление
echo -e "${GREEN}[1/5] Добавляю i386 и обновляю репозитории...${NC}"
sudo dpkg --add-architecture i386
sudo apt update

# 2. Установка Wine и базовых утилит
echo -e "${GREEN}[2/5] Устанавливаю Wine и Winetricks...${NC}"
sudo apt install -y wine wine32 wine64 libwine libwine:i386 winetricks zenity gamemode

# 3. Настройка префикса и окружения
echo -e "${GREEN}[3/5] Создаю конфигурацию...${NC}"
# Устанавливаем версию Windows 7 (она легче для этого процессора)
winecfg /v win7

# 4. Оптимизация под слабое железо (Registry Tweaks)
echo -e "${GREEN}[4/5] Оптимизирую реестр под Intel HD Graphics...${NC}"
# Отключаем тяжелые эффекты и настраиваем рендеринг через OpenGL (т.к. нет Vulkan)
winetricks nocrashdialog
winetricks d3dx9
winetricks corefonts
winetricks settings fontsmoothing=rgb

# Установка специфических ключей реестра для ускорения отрисовки
wine reg add "HKEY_CURRENT_USER\Software\Wine\Direct3D" /v "MaxShaderModelVS" /t REG_SZ /d "3" /f
wine reg add "HKEY_CURRENT_USER\Software\Wine\Direct3D" /v "MaxShaderModelPS" /t REG_SZ /d "3" /f
wine reg add "HKEY_CURRENT_USER\Software\Wine\Direct3D" /v "OffscreenRenderingMode" /t REG_SZ /d "fbo" /f
wine reg add "HKEY_CURRENT_USER\Software\Wine\Direct3D" /v "VideoMemorySize" /t REG_SZ /d "512" /f

# 5. Настройка zRAM (для твоих 4ГБ ОЗУ это критично)
echo -e "${GREEN}[5/5] Настраиваю сжатие памяти (zRAM)...${NC}"
sudo apt install -y zram-tools
echo "PERCENT=50" | sudo tee /etc/default/zramswap
sudo service zramswap restart

echo -e "${BLUE}>>> ГОТОВО! Перезагрузись, чтобы zRAM заработал на полную.${NC}"
echo -e "${BLUE}>>> Совет: запускай тяжелые игры командой: gamemoderun wine игра.exe${NC}"
