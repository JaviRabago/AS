#!/bin/sh

# Configurar la ruta predeterminada para la red de desarrollo
echo "Configurando ruta predeterminada via 172.40.0.150..."
ip route del default 2>/dev/null || true
ip route add default via 172.40.0.150

# Verificar que las rutas estén configuradas correctamente
echo "Tabla de enrutamiento configurada:"
ip route

# Verificar conectividad con app-dev
echo "Verificando conectividad con app-dev:"
ping -c 2 app-dev || echo "No se puede hacer ping a app-dev"

# Crear directorios de logs si no existen
mkdir -p /var/log/apache

# Salir con éxito
exit 0