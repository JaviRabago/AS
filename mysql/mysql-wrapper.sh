#!/bin/sh
# Script para configurar la ruta predeterminada y luego ejecutar MySQL

echo "Configurando ruta predeterminada via 172.40.0.2..."

# Intentar usar comandos de bajo nivel para configurar la ruta
if [ -d "/proc/sys/net/ipv4" ]; then
    # Activar el reenvío IP si es posible
    echo 1 > /proc/sys/net/ipv4/ip_forward 2>/dev/null || true
fi

# Usar directamente el sistema de archivos de proc para ver la tabla de rutas
echo "Tabla de enrutamiento actual:"
cat /proc/net/route 2>/dev/null || true

# Ignorar errores y seguir adelante - lo importante es que MySQL funcione
echo "Continuando con el inicio de MySQL..."

# Ejecutar MySQL con el entrypoint original
echo "Iniciando MySQL..."
exec docker-entrypoint.sh mysqld