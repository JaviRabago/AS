#!/bin/bash
set -e

echo "Configurando ruta por defecto..."

ip route del default
ip route add default via 172.30.0.150


cat > /etc/msmtprc <<EOF
defaults
auth           off
tls            off
logfile        /var/log/msmtp.log

account        local
host           prod-postfix
port           25
from           root@empresa.local

account default : local
EOF

ln -sf /usr/bin/msmtp /usr/sbin/sendmail

echo "Contenedor postfix-tester listo y configurado."

tail -f /dev/null