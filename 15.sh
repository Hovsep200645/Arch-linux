#!/bin/bash

echo "🔧 Полное исправление nwg-shell"

# 1. Удаляем проблемные версии
echo "🗑️ Удаляем проблемный nwg-shell..."
sudo pacman -Rns nwg-shell nwg-shell-config --noconfirm 2>/dev/null || true
yay -Rns nwg-shell nwg-shell-config --noconfirm 2>/dev/null || true

# 2. Чистим конфиги
echo "🧹 Чистим старые конфиги..."
rm -rf ~/.config/nwg-shell
rm -rf ~/.local/share/nwg-shell
rm -rf ~/.local/share/nwg-shell-config
rm -rf ~/.cache/nwg-shell

# 3. Создаем правильные директории
echo "📁 Создаем директории..."
mkdir -p ~/.local/share/nwg-shell
mkdir -p ~/.local/share/nwg-shell-config
mkdir -p ~/.config/nwg-shell
mkdir -p ~/.cache/nwg-shell

# 4. Устанавливаем заново из AUR
echo "📦 Устанавливаем nwg-shell..."
git clone https://aur.archlinux.org/nwg-shell.git /tmp/nwg-shell
cd /tmp/nwg-shell
makepkg -si --noconfirm

# 5. Создаем базовые конфиги
echo "⚙️ Создаем базовые настройки..."

# Основной конфиг
cat > ~/.config/nwg-shell/config.json << 'EOF'
{
    "panel": {
        "position": "top",
        "height": 35
    }
}
EOF

# Настройки конфигуратора
cat > ~/.local/share/nwg-shell-config/settings.json << 'EOF'
{
    "version": "0.4.0",
    "first-run": false
}
EOF

# Данные оболочки
cat > ~/.local/share/nwg-shell/data.json << 'EOF'
{
    "initialized": true,
    "version": "0.4.0"
}
EOF

# 6. Исправляем права
echo "🔐 Настраиваем права..."
chmod 755 ~/.local/share/nwg-shell
chmod 755 ~/.local/share/nwg-shell-config
chmod 644 ~/.local/share/nwg-shell/*.json
chmod 644 ~/.local/share/nwg-shell-config/*.json

# 7. Альтернатива - ставим nwg-shell-complete
echo "🔄 Устанавливаем nwg-shell-complete..."
yay -S nwg-shell-complete --noconfirm

# 8. Проверяем установку
echo "✅ Проверяем установку..."
if command -v nwg-shell-config &> /dev/null; then
    echo "🎉 nwg-shell установлен успешно!"
    echo "🚀 Запускаем конфигуратор..."
    nwg-shell-config
else
    echo "❌ Установка не удалась, используем альтернативы"
    
    # Устанавливаем альтернативные утилиты
    echo "📦 Устанавливаем альтернативные утилиты..."
    sudo pacman -S --noconfirm \
        lxappearance \
        pavucontrol \
        blueman \
        wdisplays \
        arandr
    
    yay -S --noconfirm \
        nwg-look \
        nwg-drawer
    
    echo "🎯 Альтернативные утилиты установлены:"
    echo "   lxappearance - темы GTK"
    echo "   pavucontrol - аудио"
    echo "   blueman - bluetooth"
    echo "   wdisplays - мониторы"
    echo "   nwg-look - настройки GTK"
    echo "   nwg-drawer - запускатель приложений"
fi

echo ""
echo "💡 Если nwg-shell не работает, используйте отдельные утилиты:"
echo "   nwg-drawer - меню приложений"
echo "   nwg-look - настройки тем"
echo "   lxappearance - внешний вид GTK"