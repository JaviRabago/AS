#!/bin/sh
# Script para verificar la configuración antes de iniciar los servicios

echo "=== Verificando configuración ==="

# Verificar que los archivos de configuración de Apache existan
echo "Verificando archivos de configuración de Apache..."
if [ -f /usr/local/apache2/conf/httpd.conf ]; then
    echo "✓ httpd.conf encontrado"
else
    echo "✗ httpd.conf no encontrado!"
fi

if [ -f /usr/local/apache2/conf/extra/httpd-vhosts.conf ]; then
    echo "✓ httpd-vhosts.conf encontrado"
else
    echo "✗ httpd-vhosts.conf no encontrado!"
fi

# Verificar configuración de supervisor
echo "Verificando archivos de configuración de supervisor..."
if [ -f /etc/supervisord.conf ]; then
    echo "✓ supervisord.conf encontrado"
else
    echo "✗ supervisord.conf no encontrado!"
fi

if [ -f /etc/supervisor.d/apache-ssh-supervisor.conf ]; then
    echo "✓ apache-ssh-supervisor.conf encontrado"
else
    echo "✗ apache-ssh-supervisor.conf no encontrado!"
fi

# Verificar script de configuración de red
echo "Verificando script de configuración de red..."
if [ -f /apache-wrapper.sh ]; then
    echo "✓ apache-wrapper.sh encontrado"
    chmod +x /apache-wrapper.sh
else
    echo "✗ apache-wrapper.sh no encontrado!"
fi

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