#!/bin/bash
set -e

# echo "Configurando ruta por defecto..."

ip route del default
ip route add default via 172.30.0.150

touch /var/log/mail.log
chmod 644 /var/log/mail.log

# service rsyslog start

tail -F /var/log/mail.log &

echo "Ruta configurada. Ejecutando proceso principal: $@"
exec "$@"
