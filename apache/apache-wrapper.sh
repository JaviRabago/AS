#!/bin/sh
# Script para configurar la ruta predeterminada y luego ejecutar Apache

# Verificar si la herramienta IP está disponible
if ! command -v ip > /dev/null 2>&1; then
    echo "Instalando iproute2..."
    apk add --no-cache iproute2
fi

# Configurar la ruta predeterminada para la red de desarrollo
echo "Configurando ruta predeterminada via 172.40.0.2..."
ip route del default 2>/dev/null || true
ip route add default via 172.40.0.2

# Ejecutar Apache
echo "Iniciando Apache..."
exec httpd-foreground