#!/bin/bash

# Скрипт полного удаления GNOME и всех связанных компонентов
# Проверяем права sudo
if [ "$EUID" -ne 0 ]; then
    echo "Пожалуйста, запустите скрипт с sudo:"
    echo "sudo ./remove_gnome_complete.sh"
    exit 1
fi

echo "=========================================="
echo " ПОЛНОЕ УДАЛЕНИЕ GNOME И ВСЕХ КОМПОНЕНТОВ"
echo "=========================================="

# Функция для проверки и удаления пакетов
remove_packages() {
    local pattern=$1
    local description=$2
    
    echo "[УДАЛЕНИЕ] $description"
    packages=$(pacman -Q | grep -i "$pattern" | cut -d' ' -f1)
    
    if [ -n "$packages" ]; then
        echo "Найдены пакеты:"
        echo "$packages"
        echo ""
        pacman -Rns --noconfirm $packages 2>/dev/null || true
        echo "---"
    else
        echo "Пакеты не найдены"
    fi
}

# Создаем резервную копию списка пакетов
echo "[1/8] Создание резервной копии..."
BACKUP_DIR="/root/gnome_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
pacman -Q > "$BACKUP_DIR/installed_packages_before.txt"
echo "Резервная копия создана: $BACKUP_DIR"

# Останавливаем и отключаем GDM
echo "[2/8] Остановка GDM..."
systemctl stop gdm 2>/dev/null || true
systemctl disable gdm 2>/dev/null || true
systemctl mask gdm 2>/dev/null || true

# Удаление основных пакетов GNOME
echo "[3/8] Удаление основных пакетов GNOME..."
remove_packages "gnome" "Основные пакеты GNOME"

# Удаление приложений GNOME
echo "[4/8] Удаление приложений GNOME..."
remove_packages "nautilus" "Файловый менеджер Nautilus"
remove_packages "gedit" "Текстовый редактор Gedit"
remove_packages "eog" "Просмотр изображений"
remove_packages "evince" "Просмотр PDF"
remove_packages "totem" "Видеоплеер"
remove_packages "rhythmbox" "Музыкальный проигрыватель"

# Удаление компонентов GNOME
echo "[5/8] Удаление компонентов GNOME..."
remove_packages "mutter" "Оконный менеджер Mutter"
remove_packages "gdm" "Дисплей менеджер GDM"
remove_packages "gnome-shell" "Оболочка GNOME"
remove_packages "gnome-session" "Сессии GNOME"
remove_packages "gnome-control-center" "Центр управления"
remove_packages "gnome-terminal" "Терминал"
remove_packages "gnome-software" "Магазин приложений"
remove_packages "gnome-keyring" "Ключи GNOME"

# Удаление библиотек и тем GNOME
echo "[6/8] Удаление библиотек и тем..."
remove_packages "gtk" "GTK библиотеки (осторожно!)"
remove_packages "adwaita" "Темы Adwaita"
remove_packages "libgnome" "Библиотеки GNOME"
remove_packages "gvfs" "Виртуальная файловая система"

# Удаление оставшихся зависимостей
echo "[7/8] Очистка оставшихся зависимостей..."
echo "Удаление ненужных зависимостей..."
pacman -Rns $(pacman -Qtdq) 2>/dev/null || true

# Очистка кэша
echo "[8/8] Очистка кэша пакетов..."
paccache -rk1  # Оставляем только последние версии
paccache -ruk0  # Удаляем все незакрепленные версии

echo "=========================================="
echo " УДАЛЕНИЕ ЗАВЕРШЕНО!"
echo "=========================================="