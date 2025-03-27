#!/bin/sh
set -e

# Configurar la ruta predeterminada
echo "Configurando ruta predeterminada via 172.40.0.150..."
ip route del default 2>/dev/null || true
ip route add default via 172.40.0.150 2>/dev/null || true

# Mostrar tabla de rutas para verificar
echo "Tabla de enrutamiento actualizada:"
ip route

# Crear un script SQL para conceder privilegios que se ejecutará después de la inicialización
cat > /docker-entrypoint-initdb.d/grant_privileges.sql << EOF
GRANT PROCESS ON *.* TO 'john'@'%';
FLUSH PRIVILEGES;
EOF

# Ejecutar el entrypoint original de Docker para MySQL
exec docker-entrypoint.sh "$@"