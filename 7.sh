#!/usr/bin/env bash
set -euo pipefail

LOGDIR="/var/log/arch_reset"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
mkdir -p "$LOGDIR"
LOG="$LOGDIR/run-$TIMESTAMP.log"
exec > >(tee -a "$LOG") 2>&1

echo "=== Arch radical cleanup and Hyprland reinstall ==="
echo "Log file: $LOG"

# Проверка root
if [ "$EUID" -ne 0 ]; then
  echo "Запусти от root (sudo)." >&2
  exit 1
fi

# 1. Определяем текущего пользователя
DEFAULT_USER=$(logname || echo "")
if [ -z "$DEFAULT_USER" ]; then
  read -p "Не удалось определить пользователя. Введи имя вручную: " DEFAULT_USER
fi
echo "Основной пользователь: $DEFAULT_USER"

# 2. Бэкап /etc и списка пакетов
BACKUP_DIR="/root/arch_reset_backup-$TIMESTAMP"
mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/etc-backup.tar.gz" /etc || true
pacman -Qqe > "$BACKUP_DIR/pkglist.txt"
echo "Бэкап в $BACKUP_DIR"

# 3. Полная очистка системы (кроме базовых и ядра)
echo "Удаляем все пакеты кроме базы и необходимых для загрузки..."
pacman -D --asexplicit base linux linux-firmware sudo systemd
pacman -Qqett | grep -vE "^(base|linux|linux-firmware|sudo|systemd)$" | pacman -Rns --noconfirm - || true

# 4. Переустановка ядра и базы
echo "Переустановка базовой системы..."
pacman -S --noconfirm base linux linux-firmware sudo systemd

# 5. Сброс прав
echo "Восстанавливаем права в / и /home/$DEFAULT_USER ..."
chown root:root / -R
chown "$DEFAULT_USER":"$DEFAULT_USER" "/home/$DEFAULT_USER" -R || true

# 6. Установка Hyprland и зависимостей
echo "Устанавливаем Hyprland и зависимости..."
pacman -Syu --noconfirm
pacman -S --noconfirm \
  hyprland waybar-hyprland hyprpaper mako wlogout \
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  kitty wofi \
  sddm

# 7. Включение SDDM (Wayland)
systemctl enable sddm.service

# 8. Минимальная конфигурация Hyprland
USER_CONFIG="/home/$DEFAULT_USER/.config/hypr"
mkdir -p "$USER_CONFIG"
cat > "$USER_CONFIG/hyprland.conf" <<'EOF'
# Minimal Hyprland config
monitor=,preferred,auto,auto
exec = waybar
exec = hyprpaper
EOF
chown -R "$DEFAULT_USER":"$DEFAULT_USER" "$USER_CONFIG"

# 9. Финал
echo "=== Завершено ==="
echo "Полный лог: $LOG"
echo "Рестартни систему: reboot"
