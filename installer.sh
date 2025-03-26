#!/bin/sh

set -e  

install_dependencies() {
    kernel="$(uname -s)"
    if [ "$kernel" = "Linux" ]; then
        . /etc/os-release

        case "$ID" in
            arch) $SUDO pacman -S --noconfirm git ;;
            debian|ubuntu|mint) $SUDO DEBIAN_FRONTEND=noninteractive apt install -y git ;;
            fedora) $SUDO dnf install -y git ;;
            void) $SUDO xbps-install -y git ;;
            gentoo) $SUDO emerge --ask=n dev-vcs/git ;;
            opensuse) $SUDO zypper install -y git ;;
            *)
                if [ -n "$ID_LIKE" ]; then
                    case "$ID_LIKE" in
                        debian) $SUDO DEBIAN_FRONTEND=noninteractive apt install -y git ;;
                        *) echo "Неизвестная ОС: ${ID} ${ID_LIKE}"; exit 1 ;;
                    esac
                else
                    echo "Неизвестная ОС: ${ID}"; exit 1
                fi
            ;;
        esac
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
    if command -v sudo > /dev/null 2>&1; then
        SUDO="sudo"
    elif command -v doas > /dev/null 2>&1; then
        SUDO="doas"
    else
        echo "Скрипт не может быть выполнен не от имени суперпользователя."
        exit 1
    fi
fi

if ! command -v git > /dev/null 2>&1; then
    install_dependencies
fi

if [ ! -d "/opt/zapret.installer" ]; then
    $SUDO git clone https://github.com/Snowy-Fluffy/zapret.installer.git /opt/zapret.installer
else
    cd /opt/zapret.installer || exit
    if ! $SUDO git pull; then
        echo "Ошибка при обновлении. Удаляю репозиторий и клонирую заново..."
        $SUDO rm -rf /opt/zapret.installer
        $SUDO git clone https://github.com/Snowy-Fluffy/zapret.installer.git /opt/zapret.installer
    fi
fi

$SUDO chmod +x /opt/zapret.installer/zapret-control.sh
bash /opt/zapret.installer/zapret-control.sh

