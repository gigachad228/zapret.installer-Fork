#!/bin/sh

set -e  

install_dependencies() {
    kernel="$(uname -s)"
    if [ "$kernel" = "Linux" ]; then
        . /etc/os-release

        declare -A command_by_ID=(
            ["arch"]="pacman -S --noconfirm git"
            ["debian"]="DEBIAN_FRONTEND=noninteractive apt install -y git"
            ["fedora"]="dnf install -y git"
            ["ubuntu"]="DEBIAN_FRONTEND=noninteractive apt install -y git"
            ["mint"]="DEBIAN_FRONTEND=noninteractive apt install -y git"
            ["void"]="xpbs-install -y git "
            ["gentoo"]="emerge --ask=n dev-vcs/git"
            ["opensuse"]="zypper install -y git "
        )

        if [[ -v command_by_ID[$ID] ]]; then
            eval "${command_by_ID[$ID]}"
        elif [[ -v command_by_ID[$ID_LIKE] ]]; then
            eval "${command_by_ID[$ID_LIKE]}"
        fi
    elif [ "$kernel" = "Darwin" ]; then
        echo "macOS не поддерживается на данный момент." 
        exit 1
    else
        echo "Неизвестная ОС: ${kernel}"
        exit 1
    fi
}


if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    elif command -v doas &> /dev/null; then
        SUDO="doas"
    else
        echo "Скрипт не может быть выполнен не от имени суперпользователя."
        exit 1
    fi
fi

if command -v git > /dev/null 2>&1; then
    echo "" 
else
    $SUDO install_dependencies
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

