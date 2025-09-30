#!/usr/bin/env bash
set -euo pipefail
LOGDIR="/var/log/arch_cleanup"
mkdir -p "$LOGDIR"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
LOG="$LOGDIR/run-$TIMESTAMP.log"

echo "Arch Hyprland cleanup/replace script — log -> $LOG"
exec > >(tee -a "$LOG") 2>&1

# Check running as root
if [ "$EUID" -ne 0 ]; then
  echo "Запусти скрипт от root (sudo)." >&2
  exit 1
fi

echo "1) Создаём резервную копию /etc и списка установленных пакетов..."
BACKUP_DIR="/root/arch_cleanup_backup-$TIMESTAMP"
mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/etc-backup-$TIMESTAMP.tar.gz" /etc || true
pacman -Qqe > "$BACKUP_DIR/pacman-explicit-$TIMESTAMP.txt"

echo "Резервные файлы: $BACKUP_DIR"

echo
echo "2) Обновление базы пакетов (pacman -Syu) — предлагается сделать сначала обновление."
read -p "Выполнить 'pacman -Syu' сейчас? [y/N]: " yn
if [[ "${yn,,}" == "y" ]]; then
  pacman -Syu
else
  echo "Пропускаем полное обновление по запросу."
fi

echo
echo "3) Просмотр текущих ошибок в журнале (severity >= err). Сохраняю в $LOGDIR/journal_errors-$TIMESTAMP.log"
journalctl -p 3 -xb | tee "$LOGDIR/journal_errors-$TIMESTAMP.log" || true

echo
echo "4) Проверка целостности установленных пакетов (pacman -Qkk). Это может занять время..."
PKG_ISSUES_FILE="$LOGDIR/pacman_pkg_problems-$TIMESTAMP.txt"
# pacman -Qkk выводит строки вида "missing file: /path" или "altered: /path"
pacman -Qkk | awk '/^(.+):/ {pkg=$1} /missing file|altered file/ {print pkg; next}' | sort -u > "$PKG_ISSUES_FILE" || true

if [ -s "$PKG_ISSUES_FILE" ]; then
  echo "Найдены пакеты с проблемами, список -> $PKG_ISSUES_FILE"
  echo "Первый кусок списка (если много):"
  head -n 30 "$PKG_ISSUES_FILE"
  read -p "Попробовать переустановить эти пакеты (pacman -S <список>)? [y/N]: " reinstall
  if [[ "${reinstall,,}" == "y" ]]; then
    # безопасно читаем пакетный список в массив и переустанавливаем порционно
    mapfile -t pkgs < "$PKG_ISSUES_FILE"
    # проверка на пустоту
    if [ "${#pkgs[@]}" -gt 0 ]; then
      echo "Переустанавливаем ${#pkgs[@]} пакетов..."
      pacman -S --needed "${pkgs[@]}"
    fi
  else
    echo "Пропускаем переустановку пакетов."
  fi
else
  echo "Проблем с целостностью пакетов не найдено."
fi

echo
echo "5) Поиск и отключение дисплей-менеджеров (gdm, sddm, lightdm, lxdm)..."
DM_CANDIDATES=(gdm sddm lightdm lxdm)
for dm in "${DM_CANDIDATES[@]}"; do
  if pacman -Qi "$dm" &>/dev/null; then
    echo "Найден дисплей-менеджер: $dm"
    systemctl disable --now "$dm.service" || true
    read -p "Удалить пакет $dm и связанные зависимости? [y/N]: " del
    if [[ "${del,,}" == "y" ]]; then
      pacman -Rns "$dm" || echo "Не удалось удалить $dm автоматически."
    else
      echo "Оставляем $dm."
    fi
  fi
done

echo
echo "6) Удаление мета-пакетов рабочих окружений (GNOME, KDE, XFCE и пр.)."
DE_GROUPS=(gnome gnome-extra plasma kde-applications xfce4 xfce4-goodies mate cinnamon)
echo "Будут рассмотрены группы: ${DE_GROUPS[*]}"
read -p "Удаляем перечисленные группы (попытка pacman -Rns group)? Это может удалить много пакетов. [y/N]: " delde
if [[ "${delde,,}" == "y" ]]; then
  for grp in "${DE_GROUPS[@]}"; do
    if pacman -Qg "$grp" &>/dev/null; then
      echo "Удаляю группу/пакеты для: $grp"
      # получим пакеты группы и удалим их
      pkgs_to_remove=($(pacman -Qg "$grp" | awk '{print $2}' | sort -u))
      if [ "${#pkgs_to_remove[@]}" -gt 0 ]; then
        pacman -Rns --noconfirm "${pkgs_to_remove[@]}" || echo "Ошибка при удалении группы $grp"
      fi
    else
      echo "Группа $grp не установлена или не найдена."
    fi
  done
else
  echo "Пропускаем массовое удаление окружений."
fi

echo
echo "7) Установка Hyprland и рекомендованных компонентов."
# Изменяй список по необходимости
HYPR_PACKAGES=(hyprland waybar-hyprland hyprpaper mako wlogout sddm-wayland wofi hyprland-profiles)
echo "Пакеты для установки: ${HYPR_PACKAGES[*]}"
read -p "Установить перечисленные пакеты? [y/N]: " install_hypr
if [[ "${install_hypr,,}" == "y" ]]; then
  pacman -S --needed "${HYPR_PACKAGES[@]}"
  echo "Установка завершена. Создаю простую skeleton конфигурацию в /etc/skel/.config/hypr/"
  mkdir -p /etc/skel/.config/hypr
  if [ ! -f /etc/skel/.config/hypr/hyprland.conf ]; then
    cat > /etc/skel/.config/hypr/hyprland.conf <<'EOF'
# minimal hyprland config skeleton
general {
  monitor=auto
}
# Add keybindings, autostart, etc. See ArchWiki Hyprland for details.
EOF
  fi
else
  echo "Пропускаем установку Hyprland."
fi

echo
echo "8) Повторная проверка журналов и целостности после изменений..."
journalctl -p 3 -xb | tee "$LOGDIR/journal_errors_after-$TIMESTAMP.log" || true
pacman -Qkk | awk '/^(.+):/ {pkg=$1} /missing file|altered file/ {print pkg; next}' | sort -u > "$LOGDIR/pacman_problems_after-$TIMESTAMP.txt" || true

echo
echo "9) Результаты и рекомендации:"
echo "Журналы ошибок (до)  : $LOGDIR/journal_errors-$TIMESTAMP.log"
echo "Журналы ошибок (после): $LOGDIR/journal_errors_after-$TIMESTAMP.log"
echo "Проблемы пакетов (до): $PKG_ISSUES_FILE"
echo "Проблемы пакетов (после): $LOGDIR/pacman_problems_after-$TIMESTAMP.txt"
echo "Полный лог выполнения: $LOG"

echo
echo "Если после удаления/установки у тебя не загрузится графика, переключись в TTY (Ctrl+Alt+F2) и посмотри лог $LOG"
echo "Готово."
