#!/bin/bash

set -e  

if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" "$@"
fi


check_zapret_status() {
    systemctl is-active --quiet zapret && ZAPRET_ACTIVE=true || ZAPRET_ACTIVE=false
    systemctl is-enabled --quiet zapret && ZAPRET_ENABLED=true || ZAPRET_ENABLED=false
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
                3) systemctl restart zapret;;
                4) systemctl status zapret; read -p "Нажмите Enter для продолжения...";;
                5) systemctl enable zapret;;
                6) systemctl start zapret;;
                7) systemctl disable zapret;;
                8) systemctl stop zapret;;
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
    git clone https://github.com/Snowy-Fluffy/zapret.cfgs /opt/zapret/zapret.cfgs || true
    cp -r /opt/zapret/zapret.cfgs/binaries/binaries /opt/zapret/binaries/
    # Бинарники скомпилированные чтобы избежать лишних проблем у новичков, если боишься что с ними что то не так, сотри эту строчку и запусти скрипт еще раз, зависимости для компиляции устанавливаются 
    git clone https://github.com/bol-van/zapret /opt/zapret
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
main_menu

