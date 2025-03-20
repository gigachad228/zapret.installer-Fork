#!/bin/bash
if [ ! -d /tmp/zapret.installer/ ]; then
    cd /tmp || exit 
    git clone https://github.com/Snowy-Fluffy/zapret.installer.git
fi
cd /tmp/zapret.installer || exit
chmod +x zapret-control.sh
bash /tmp/zapret.installer/zapret-control.sh

