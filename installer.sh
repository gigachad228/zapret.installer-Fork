#!/bin/bash

if [ "$EUID" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

if command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
    INSTALL_CMD="$SUDO pacman -S --noconfirm"
elif command -v apt &> /dev/null; then
    PKG_MANAGER="apt"
    INSTALL_CMD="$SUDO apt-get install -y"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    INSTALL_CMD="$SUDO dnf install -y"
elif command -v zypper &> /dev/null; then
    PKG_MANAGER="zypper"
    INSTALL_CMD="$SUDO zypper install -y"
elif command -v opkg &> /dev/null; then
    PKG_MANAGER="opkg"
    INSTALL_CMD="$SUDO opkg install"
elif command -v apk &> /dev/null; then
    PKG_MANAGER="apk"
    INSTALL_CMD="$SUDO apk add"
else
    echo "Не удалось определить пакетный менеджер. Убедитесь, что ваш дистрибутив поддерживается."
    exit 1
fi


read -p "Вы хотите видеть логи установки? (y/n): " show_logs
if [ "$show_logs" == "y" ]; then
    LOG_CMD="cat"
else
    LOG_CMD="grep --line-buffered \"^\""
fi

$INSTALL_CMD git libnetfilter_queue | $LOG_CMD

echo "Выберите режим установки:"
echo "1) Автоматическая установка"
echo "2) Ручная установка (выбор параметров самостоятельно)"
read -p "Введите номер выбора (1 или 2): " install_mode

echo "Выберите вариант установки:"
echo "1) Установить чистый zapret"
echo "2) Установить zapret с конфигами"
read -p "Введите номер выбора (1 или 2): " choice

if [ -d /opt/zapret ]; then
    $SUDO rm -rf /opt/zapret.old
    $SUDO mv /opt/zapret /opt/zapret.old
fi

if [ "$choice" -eq 2 ]; then
    cd /tmp || exit 1
    git clone https://github.com/Snowy-Fluffy/zapret.cfgs.git | $LOG_CMD
    cd /tmp/zapret.cfgs || exit 1
    tar -xf binaries.tar
fi
$SUDO git clone https://github.com/bol-van/zapret /opt/zapret | $LOG_CMD
cd /opt/zapret || exit 1
if [ "$choice" -eq 2 ]; then
    $SUDO cp -r /tmp/zapret.cfgs/binaries /opt/zapret/binaries
fi
$SUDO chmod -R 777 /opt/zapret

if [ "$install_mode" -eq 1 ]; then
    yes "" | $SUDO sh ./install_bin.sh | $LOG_CMD
    yes "" | $SUDO sh ./install_prereq.sh | $LOG_CMD
    yes "" | $SUDO sh ./install_easy.sh | $LOG_CMD
else
    $SUDO sh ./install_bin.sh
    $SUDO sh ./install_prereq.sh
    $SUDO sh ./install_easy.sh
fi

if [ "$choice" -eq 2 ]; then
    cd /tmp/zapret.cfgs || exit 1
    $SUDO cp -r config /opt/zapret/config
    $SUDO cp -r zapret-hosts-user.txt /opt/zapret/ipset/zapret-hosts-user.txt
    $SUDO cp -r zapret-hosts-auto.txt /opt/zapret/ipset/zapret-hosts-auto.txt
    $SUDO cp -r ipset-discord.txt /opt/zapret/ipset/ipset-discord.txt
    $SUDO cp -r quic_initial_www_google_com.bin /opt/zapret/files/fake/quic_initial_www_google_com.bin
    $SUDO cp -r tls_clienthello_www_google_com.bin /opt/zapret/files/fake/tls_clienthello_www_google_com.bin
fi

if command -v systemctl &> /dev/null; then
    $SUDO systemctl restart zapret
elif [ "$PKG_MANAGER" == "opkg" ]; then
    $SUDO /etc/init.d/zapret restart
else
    echo "Не удалось автоматически перезапустить zapret. Проверьте службу вручную."
fi

echo "Установка завершена."
