#!/bin/sh
# Script para verificar la configuración antes de iniciar los servicios

# Verificar conectividad de red
echo "Verificando conectividad de red con app-dev..."
getent hosts app-dev || echo "No se puede resolver app-dev"

# Verificar que Apache pueda iniciar
echo "Verificando configuración de Apache..."
httpd -t || echo "Error en la configuración de Apache"

# Ejecutar el script de configuración de red primero
echo "Ejecutando configuración de red..."
/bin/sh /apache-wrapper.sh

echo "=== Iniciando supervisord ==="
exec /usr/bin/supervisord -c /etc/supervisord.conf