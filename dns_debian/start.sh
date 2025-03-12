#!/bin/bash

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

# Usar trap para manejar la finalización correctamente
trap "kill $DNSMASQ_PID" SIGTERM SIGINT

# Mantener el contenedor en ejecución
wait $DNSMASQ_PID