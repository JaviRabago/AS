#!/bin/bash

# Configurar 172.40.0.2 como ruta predeterminada para todo el tráfico
ip route del default
ip route add default via 172.40.0.2

# Asegurarse de que dnsmasq no esté corriendo
killall dnsmasq 2>/dev/null || true

# Crear el archivo de hosts si no existe
touch /etc/dnsmasq.hosts

# Iniciar dnsmasq en modo no-daemon (foreground) con opciones explícitas
dnsmasq --no-daemon --log-queries --keep-in-foreground --log-facility=- --no-resolv --server=8.8.8.8 &
DNSMASQ_PID=$!

# Dar permisos correctos al archivo de hosts
chmod 644 /etc/dnsmasq.hosts

# Esperar a que dnsmasq esté completamente iniciado
sleep 2

# Iniciar docker-gen con el PID correcto
docker-gen -watch -notify "kill -HUP $DNSMASQ_PID" /etc/docker-gen/templates/dnsmasq.tmpl /etc/dnsmasq.hosts &

# Instalar herramientas necesarias para backup si no están instaladas
if ! command -v mysql > /dev/null || ! command -v mysqldump > /dev/null; then
  apt-get update && apt-get install -y default-mysql-client
fi

if ! command -v psql > /dev/null || ! command -v pg_dump > /dev/null; then
  apt-get update && apt-get install -y postgresql-client
fi

# Iniciar servicios de NAS
echo "Iniciando servicios de NAS..."

# Iniciar SSH para acceso remoto
/usr/sbin/sshd

# Iniciar Samba para compartir archivos
service smbd start
service nmbd start

# Iniciar cron para backups programados
service cron start

echo "Servicios NAS iniciados correctamente"

# Usar trap para manejar la finalización correctamente
trap "kill $DNSMASQ_PID; service smbd stop; service nmbd stop; service cron stop; service ssh stop" SIGTERM SIGINT

# Mantener el contenedor en ejecución
wait $DNSMASQ_PID