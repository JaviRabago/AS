#!/bin/sh
set -e

# Configurar la ruta predeterminada
echo "Configurando ruta predeterminada via 172.40.0.2..."
ip route del default 2>/dev/null || true
ip route add default via 172.40.0.2 2>/dev/null || true

# Mostrar tabla de rutas para verificar
echo "Tabla de enrutamiento actualizada:"
ip route

# Ejecutar el entrypoint original de Docker para MySQL
exec docker-entrypoint.sh "$@"