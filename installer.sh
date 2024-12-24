#!/bin/bash

if command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
    INSTALL_CMD="sudo pacman -S --noconfirm"
elif command -v apt &> /dev/null; then
    PKG_MANAGER="apt"
    INSTALL_CMD="sudo apt-get install -y"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    INSTALL_CMD="sudo dnf install -y"
elif command -v zypper &> /dev/null; then
    PKG_MANAGER="zypper"
    INSTALL_CMD="sudo zypper install -y"
elif command -v opkg &> /dev/null; then
    PKG_MANAGER="opkg"
    INSTALL_CMD="sudo opkg install"
elif command -v apk &> /dev/null; then
    PKG_MANAGER="apk"
    INSTALL_CMD="sudo apk add"
else
    echo "Не удалось определить пакетный менеджер. Убедитесь, что ваш дистрибутив поддерживается."
    exit 1
fi

$INSTALL_CMD git libnetfilter_queue

echo "Выберите вариант установки:"
echo "1) Установить чистый zapret"
echo "2) Установить zapret с конфигами"
read -p "Введите номер выбора (1 или 2): " choice

sudo git clone https://github.com/bol-van/zapret /opt/zapret
cd /opt/zapret || exit 1
sudo sh ./install_bin.sh
sudo sh ./install_prereq.sh
sudo sh ./install_easy.sh

if [ "$choice" -eq 2 ]; then
    cd /tmp || exit 1
    git clone https://github.com/Snowy-Fluffy/zapret.cfgs.git
    cd zapret.cfgs || exit 1
    sudo cp -r config /opt/zapret/config
    sudo cp -r zapret-hosts-user.txt /opt/zapret/ipset/zapret-hosts-user.txt
    sudo cp -r zapret-hosts-auto.txt /opt/zapret/ipset/zapret-hosts-auto.txt
    sudo cp -r ipset-discord.txt /opt/zapret/ipset/ipset-discord.txt
    sudo cp -r quic_initial_www_google_com.bin /opt/zapret/files/fake/quic_initial_www_google_com.bin
    sudo cp -r tls_clienthello_www_google_com.bin /opt/zapret/files/fake/tls_clienthello_www_google_com.bin
fi

if command -v systemctl &> /dev/null; then
    sudo systemctl restart zapret
elif [ "$PKG_MANAGER" == "opkg" ]; then
    echo "Перезапустите zapret вручную: /etc/init.d/zapret restart"
else
    echo "Не удалось автоматически перезапустить zapret. Проверьте службу вручную."
fi

echo "Установка завершена."
