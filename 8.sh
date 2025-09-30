#!/usr/bin/env bash
# arch_total_reset_hypr.sh
# Полная очистка Arch + установка Hyprland
set -euo pipefail

### Настройки ###
KEEP_PKGS=(base linux linux-firmware pacman bash coreutils filesystem systemd sudo util-linux e2fsprogs grub networkmanager)
HYPR_PKGS=(hyprland waybar-hyprland hyprpaper mako wlogout wofi kitty \
           xdg-desktop-portal-hyprland xdg-desktop-portal-gtk sddm)

LOGDIR="/var/log/arch_reset"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="/root/arch_reset_backup-$TIMESTAMP"

mkdir -p "$LOGDIR" "$BACKUP_DIR"
LOG="$LOGDIR/run-$TIMESTAMP.log"
exec > >(tee -a "$LOG") 2>&1

echo "=== Arch Total Reset & Hyprland Install ==="
echo "Лог: $LOG"

# Проверка root
if [ "$EUID" -ne 0 ]; then
  echo "Ошибка: запусти от root (sudo)." >&2
  exit 1
fi

# Определяем пользователя
MAIN_USER="$(logname 2>/dev/null || echo ${SUDO_USER:-})"
if [ -z "$MAIN_USER" ] || [ "$MAIN_USER" = "root" ]; then
  read -p "Введи имя пользователя, чей /home не трогать: " MAIN_USER
fi
echo "Основной пользователь: $MAIN_USER"

# Бэкап
echo "1) Создание бэкапов..."
tar -czf "$BACKUP_DIR/etc-backup.tar.gz" /etc || true
pacman -Qqe > "$BACKUP_DIR/pkglist-explicit.txt"
pacman -Qq  > "$BACKUP_DIR/pkglist-all.txt"
pacman -Qqm > "$BACKUP_DIR/pkglist-foreign.txt"

# Удаление пакетов кроме KEEP_PKGS
echo "2) Очистка системы..."
mapfile -t KEEP_UNIQ < <(printf "%s\n" "${KEEP_PKGS[@]}" | sort -u)
mapfile -t EXPL < <(pacman -Qqe)
mapfile -t BASE_GROUP < <(pacman -Sg base | awk '{print $2}')

KEEP_ALL=("${KEEP_UNIQ[@]}" "${BASE_GROUP[@]}")
declare -A KEEP_MAP
for p in "${KEEP_ALL[@]}"; do KEEP_MAP["$p"]=1; done

TO_REMOVE=()
for p in "${EXPL[@]}"; do
  if [ -z "${KEEP_MAP[$p]:-}" ]; then
    TO_REMOVE+=("$p")
  fi
done

if [ "${#TO_REMOVE[@]}" -gt 0 ]; then
  pacman -Rns --noconfirm "${TO_REMOVE[@]}" || true
fi

# Переустановка базы
echo "3) Переустановка базовой системы..."
pacman -Syu --noconfirm
pacman -S --noconfirm "${KEEP_UNIQ[@]}"

# Восстановление прав
echo "4) Восстановление прав..."
for d in /etc /bin /sbin /usr /var /lib /opt; do
  [ -d "$d" ] && chown -R root:root "$d" || true
done
if [ -d "/home/$MAIN_USER" ]; then
  chown -R "$MAIN_USER:$MAIN_USER" "/home/$MAIN_USER"
fi

# Установка Hyprland
echo "5) Установка Hyprland и зависимостей..."
pacman -S --noconfirm "${HYPR_PKGS[@]}"

# Включение SDDM
systemctl enable sddm.service

# Конфигурация Hyprland
echo "6) Настройка Hyprland..."
USER_CONFIG="/home/$MAIN_USER/.config/hypr"
mkdir -p "$USER_CONFIG"
cat > "$USER_CONFIG/hyprland.conf" <<'EOF'
# Минимальная конфигурация Hyprland
monitor=,preferred,auto,auto
exec = waybar
exec = hyprpaper
bind = SUPER, RETURN, exec, kitty
EOF
chown -R "$MAIN_USER:$MAIN_USER" "$USER_CONFIG"

# Проверка
echo "7) Финальная проверка..."
journalctl -p 3 -xb > "$LOGDIR/journal_errors_after-$TIMESTAMP.log" || true
pacman -Qkk > "$LOGDIR/pacman_check_after-$TIMESTAMP.log" || true

echo "=== Готово! ==="
echo "Бэкапы: $BACKUP_DIR"
echo "Логи: $LOGDIR"
echo "Перезагрузи систему: reboot"
