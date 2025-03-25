#!/bin/sh

set -e  

if command -v git &> /dev/null; then
    echo ""
else
    echo "Команда git не найдена. Установите пакет git вручную"
    exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    elif command -v doas &> /dev/null; then
        SUDO="doas"
    else
        echo "Скрипт не может быть выполнен не от суперпользователя."
        exit 1
    fi
fi

if [ ! -d "/opt/zapret.installer" ]; then
    cd /opt || exit
    $SUDO git clone https://github.com/Snowy-Fluffy/zapret.installer.git
else
    cd "/opt/zapret.installer" || exit
    if ! $SUDO git pull; then
        echo "Ошибка при обновлении. Удаляю репозиторий и клонирую заново..."
        cd /opt || exit
        $SUDO rm -rf "/opt/zapret.installer"
        $SUDO git clone https://github.com/Snowy-Fluffy/zapret.installer.git
        cd "/opt/zapret.installer" || exit
    fi
fi

$SUDO chmod +x /opt/zapret.installer/zapret-control.sh
bash /opt/zapret.installer/zapret-control.sh

