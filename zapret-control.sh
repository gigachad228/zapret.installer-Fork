#!/bin/bash

set -e  

if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" "$@"
fi


detect_init() {
    if [ -d /run/systemd/system ]; then
        INIT_SYSTEM="systemd"
    elif command -v openrc-init >/dev/null 2>&1; then
        INIT_SYSTEM="openrc"
    elif command -v runit >/dev/null 2>&1; then
        INIT_SYSTEM="runit"
    elif [ -x /sbin/init ] && /sbin/init --version 2>&1 | grep -q "sysvinit"; then
        INIT_SYSTEM="sysvinit"
    else
        INIT_SYSTEM="unknown"
        echo "Ваш Init не поддерживается."
        exit 0
    fi
}

check_zapret_status() {
    case "$INIT_SYSTEM" in
        systemd)
        ZAPRET_ACTIVE=$(systemctl show -p ActiveState zapret | cut -d= -f2)
        ZAPRET_ENABLED=$(systemctl is-enabled zapret)
        ZAPRET_SUBSTATE=$(systemctl show -p SubState zapret | cut -d= -f2)
        if [[ "$ZAPRET_ACTIVE" == "active" && "$ZAPRET_SUBSTATE" == "running" ]]; then
           ZAPRET_ACTIVE=true
        else
            ZAPRET_ACTIVE=false
        fi

        if [[ "$ZAPRET_ENABLED" == "enabled" ]]; then
            ZAPRET_ENABLED=true
        else
            ZAPRET_ENABLED=false
        fi;;
        openrc)
            rc-service zapret status >/dev/null 2>&1 && ZAPRET_ACTIVE=true || ZAPRET_ACTIVE=false
            rc-update show | grep -q zapret && ZAPRET_ENABLED=true || ZAPRET_ENABLED=false
            ;;
        runit)
            sv status zapret >/dev/null 2>&1 && ZAPRET_ACTIVE=true || ZAPRET_ACTIVE=false
            [ -L /var/service/zapret ] && ZAPRET_ENABLED=true || ZAPRET_ENABLED=false
            ;;
        sysvinit)
            service zapret status >/dev/null 2>&1 && ZAPRET_ACTIVE=true || ZAPRET_ACTIVE=false
            ;;
    esac
}

manage_service() {
    case "$INIT_SYSTEM" in
        systemd)
            SYSTEMD_PAGER=cat systemctl "$1" zapret
            ;;
        openrc)
            rc-service zapret "$1"
            ;;
        runit)
            sv "$1" zapret
            ;;
        sysvinit)
            service zapret "$1"
            ;;
    esac
}

manage_autostart() {
    case "$INIT_SYSTEM" in
        systemd)
            systemctl "$1" zapret
            ;;
        openrc)
            if [[ "$1" == "enable" ]]; then
                rc-update add zapret default
            else
                rc-update del zapret default
            fi
            ;;
        runit)
            if [[ "$1" == "enable" ]]; then
                ln -s /etc/sv/zapret /var/service/
            else
                rm -f /var/service/zapret
            fi
            ;;
        sysvinit)
            if [[ "$1" == "enable" ]]; then
                update-rc.d zapret defaults
            else
                update-rc.d -f zapret remove
            fi
            ;;
    esac
}

install_dependencies() {
    kernel="$(uname -s)"
    if [ "$kernel" = "Linux" ]; then
        . /etc/os-release

        declare -A command_by_ID=(
            ["arch"]="pacman -S make gcc git zlib libcap \
                            libnetfilter_queue"
            ["debian"]="apt install make gcc git zlib1g-dev \
                            libcap-dev libnetfilter-queue-dev"
            ["fedora"]="dnf install git make gcc zlib-devel \
                            libcap-devel libnetfilter_queue-devel"
            ["ubuntu"]="apt install make gcc zlib1g-dev \
                            libcap-dev git libnetfilter-queue-dev"
            ["mint"]="apt install make gcc zlib1g-dev \
                            libcap-dev git libnetfilter-queue-dev"
            ["void"]="xpbs-install make gcc git zlib libcap \
                            libnetfilter_queue"
            ["gentoo"]="emerge sys-libs/zlib dev-vcs/git sys-libs/libcap \
                            net-libs/libnetfilter_queue"
            ["opensuse"]="zypper install make git gcc zlib-devel \
                            libcap-devel libnetfilter_queue-devel"
        )

        if [[ -v command_by_ID[$ID] ]]; then
            eval "${command_by_ID[$ID]}"
        elif [[ -v command_by_ID[$ID_LIKE] ]]; then
            eval "${command_by_ID[$ID_LIKE]}"
        fi
    elif [ "$kernel" = "Darwin" ]; then
        echo "macOS не поддерживается на данный момент." 
    else
        echo "Неизвестная ОС: ${kernel}"
        exit 1
    fi
}

main_menu() {
    while true; do
        clear
        check_zapret_status
        echo "===== Меню управления Запретом ====="
        if [[ $ZAPRET_ACTIVE == true ]]; then echo "!Запрет запущен!"; fi
        if [[ $ZAPRET_ACTIVE == false ]]; then echo "!Запрет выключен!"; fi
        if [[ -d /opt/zapret ]]; then
            echo "1) Проверить на обновления"
            echo "2) Сменить конфигурацию"
            echo "3) Перезапустить Запрет"
            echo "4) Посмотреть статус Запрета"
            if [[ $ZAPRET_ENABLED == false ]]; then echo "5) Добавить в автозагрузку"; fi
            if [[ $ZAPRET_ACTIVE == false ]]; then echo "6) Включить Запрет"; fi
            if [[ $ZAPRET_ENABLED == true ]]; then echo "7) Убрать из автозагрузки"; fi
            if [[ $ZAPRET_ACTIVE == true ]]; then echo "8) Выключить Запрет"; fi
            echo "9) Удалить Запрет"
            echo "10) Выйти"
            read -p "Выберите действие: " CHOICE
            case "$CHOICE" in
                1) update_zapret;;
                2) configure_zapret;;
                3) manage_service restart;;
                4) manage_service status; bash -c 'read -p "Нажмите Enter для продолжения..."';;
                5) manage_autostart enable;;
                6) manage_service start;;
                7) manage_autostart disable;;
                8) manage_service stop;;
                9) uninstall_zapret;;
                10) exit 0;;
                *) echo "Неверный ввод!"; sleep 2;;
            esac
        else
            echo "1) Установить Запрет"
            echo "2) Выйти"
            read -p "Выберите действие: " CHOICE
            case "$CHOICE" in
                1) install_zapret; main_menu;;
                2) exit 0;;
                *) echo "Неверный ввод!"; sleep 2;;
            esac
        fi
    done
}


install_zapret() {
    install_dependencies

    echo "Клонирую репозиторий..."
    if ! git clone https://github.com/bol-van/zapret /opt/zapret ; then
         echo "Ошибка: нестабильноe/слабое подключение к интернету."
    exit 1
    fi
    echo "Клонирование успешно завершено."

    echo "Клонирую репозиторий..."
        if ! git clone https://github.com/Snowy-Fluffy/zapret.cfgs /opt/zapret/zapret.cfgs ; then
    echo "Ошибка: нестабильноe/слабое подключение к интернету."
    exit 1
    fi
    echo "Клонирование успешно завершено."
    

    if [[ ! -d /tmp/zapret.binaries ]]; then
        echo "Клонирую релиз запрета..."
        mkdir -p /tmp/zapret.binaries
        if ! wget -P /tmp/zapret.binaries/zapret.tar. https://github.com/bol-van/zapret/releases/download/v70.4/zapret-v70.4.tar.gz; then
            echo "Ошибка: не удалось получить релиз запрета."
            exit 1
        fi
        echo "Получение запрета завершено."
        tar -xzf zapret-v70.4.tar.gz -C /tmp/zapret.binaries/zapret
        cp -r /tmp/zapret.binaries/zapret/binaries /opt/zapret/binaries

    fi
    
    cd /opt/zapret
    yes "" | ./install_easy.sh
    configure_zapret
}


update_zapret() {
    if [[ -d /opt/zapret ]]; then
        cd /opt/zapret && git pull
    fi
    if [[ -d /opt/zapret/zapret.cfgs ]]; then
        cd /opt/zapret/zapret.cfgs && git pull
    fi
    systemctl restart zapret
}

# Настройка конфигурации
configure_zapret() {
    rm -rf /opt/zapret/zapret.cfgs/
    if [[ ! -d /opt/zapret/zapret.cfgs ]]; then
        echo "Клонирую репозиторий..."
        if ! git clone https://github.com/Snowy-Fluffy/zapret.cfgs /opt/zapret/zapret.cfgs ; then
            echo "Ошибка: нестабильноe/слабое подключение к интернету."
            exit 1
        fi
         echo "Клонирование успешно завершено." 
    fi
    cp /opt/zapret/zapret.cfgs/lists/* /opt/zapret/ipset/
    cp /opt/zapret/zapret.cfgs/binaries/* /opt/zapret/files/fake/
    
    echo "Выберите конфигурацию:" 
    select CONF in /opt/zapret/zapret.cfgs/configurations/*; do
        rm -f /opt/zapret/config
        cp "$CONF" /opt/zapret/config
        break
    done

    # Проверка firewall
    if grep -q "nftables" /proc/modules; then
        sed -i '11s/.*/FWTYPE=nftables/' /opt/zapret/config
    fi

    systemctl restart zapret
}


uninstall_zapret() {
    if [[ -f /opt/zapret/uninstall_easy.sh ]]; then
        cd /opt/zapret
        yes "" | ./uninstall_easy.sh
    fi
    rm -rf /opt/zapret
}

# Запуск главного меню

detect_init
main_menu
