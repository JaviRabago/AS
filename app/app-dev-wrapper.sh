#!/bin/sh
# Script para configurar la ruta predeterminada y luego ejecutar la aplicación Node.js en desarrollo

# Configurar la ruta predeterminada para la red de desarrollo
echo "Configurando ruta predeterminada via 172.40.0.150..."
ip route del default 2>/dev/null || true
ip route add default via 172.40.0.150

# Ejecutar la aplicación Node.js en modo desarrollo
echo "Iniciando aplicación Node.js en modo desarrollo..."
exec npm run dev