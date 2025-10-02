#!/bin/bash

# Скрипт резервного копирования перед изменениями
BACKUP_DIR="/home/$USER/backup_gnome_$(date +%Y%m%d_%H%M%S)"

echo "Создание резервной копии в $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Копируем важные конфиги
cp -r ~/.config/gnome* "$BACKUP_DIR/" 2>/dev/null || true
cp -r ~/.local/share/gnome* "$BACKUP_DIR/" 2>/dev/null || true
cp ~/.bashrc ~/.xprofile ~/.xsession "$BACKUP_DIR/" 2>/dev/null || true

# Сохраняем список установленных пакетов
pacman -Q > "$BACKUP_DIR/installed_packages.txt"

echo "Резервная копия создана в: $BACKUP_DIR"
echo "Размер: $(du -sh "$BACKUP_DIR" | cut -f1)"