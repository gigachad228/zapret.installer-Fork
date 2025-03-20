#!/bin/bash

set -e  

if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" "$@"
fi



REPO_DIR="/tmp/zapret.installer"


if [ ! -d "$REPO_DIR" ]; then
    cd /tmp || exit
    git clone https://github.com/Snowy-Fluffy/zapret.installer.git
else
    cd "$REPO_DIR" || exit
    if ! git pull; then
        echo "Ошибка при обновлении. Удаляю репозиторий и клонирую заново..."
        cd /tmp || exit
        rm -rf "$REPO_DIR"
        git clone https://github.com/Snowy-Fluffy/zapret.installer.git
        cd "$REPO_DIR" || exit
    fi
fi
cd $REPO_DIR || exit
chmod +x zapret-control.sh
bash zapret-control.sh

