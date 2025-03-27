#!/bin/sh
# Script para configurar la ruta predeterminada y luego ejecutar PostgreSQL

# Verificar si la herramienta IP está disponible
if ! command -v ip > /dev/null 2>&1; then
    echo "Instalando iproute2..."
    apk add --no-cache iproute2
fi

# Configurar la ruta predeterminada para la red de producción
echo "Configurando ruta predeterminada via 172.30.0.150..."
ip route del default 2>/dev/null || true
ip route add default via 172.30.0.150

# Ejecutar PostgreSQL
echo "Iniciando PostgreSQL..."
exec docker-entrypoint.sh postgres