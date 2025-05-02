#!/bin/bash

#Configurar 172.30.0.150 como ruta predeterminada para todo el tráfico
ip route del default
ip route add default via 172.30.0.150

# Configurar entorno SSH
mkdir -p /home/sftpuser/.ssh
cp /authorized_keys /home/sftpuser/.ssh/authorized_keys || echo "No se encontró el archivo authorized_keys"

# Configurar permisos adecuados - CRÍTICO para SFTP chroot
echo "Configurando estructura de directorio chroot..."
chown root:root /home/sftpuser
chmod 755 /home/sftpuser
chown -R sftpuser:sftpuser /home/sftpuser/docs
chmod -R 755 /home/sftpuser/docs
chmod 700 /home/sftpuser/.ssh
chmod 600 /home/sftpuser/.ssh/authorized_keys
chown -R sftpuser:sftpuser /home/sftpuser/.ssh

# Crear estructura de directorios para el proxy si no existe
for i in $(seq 1 5); do
    mkdir -p /home/sftpuser/docs/SW$i
    # Crear archivos de ejemplo en caso de que la sincronización falle
    echo "Archivo de ejemplo para SW$i" > /home/sftpuser/docs/SW$i/ejemplo.txt
    echo "Readme para programa SW$i" > /home/sftpuser/docs/SW$i/readme.txt
done
chown -R sftpuser:sftpuser /home/sftpuser/docs

# Verificar conectividad a la red
echo "Verificando conectividad de red..."
ip addr
ip route
echo "Prueba de ping al router:"
ping -c 2 172.30.0.150 || echo "No se pudo hacer ping al router"

# Verificar acceso al servidor FTP con reintento
echo "Verificando acceso al servidor FTP..."
ping_count=0
max_attempts=5

until ping -c 1 -w 2 172.40.0.10 > /dev/null 2>&1
do
    ping_count=$((ping_count+1))
    if [ $ping_count -ge $max_attempts ]; then
        echo "No se pudo conectar al servidor FTP después de $max_attempts intentos"
        echo "Continuando de todos modos, el script de proxy seguirá intentando..."
        break
    fi
    echo "Intento $ping_count de $max_attempts - Esperando que el servidor FTP sea accesible..."
    sleep 5
done

# Asegurar que las claves SSH estén generadas
ssh-keygen -A

# Iniciar el servicio SSH con depuración
echo "Iniciando servicio SSH..."
/usr/sbin/sshd -e -D &

# Verificar configuración de SSH
echo "Validando configuración SSH:"
/usr/sbin/sshd -t && echo "Configuración SSH válida" || echo "Configuración SSH inválida"

# Mostrar estado actual
echo "Estado actual del directorio SFTP:"
ls -la /home/sftpuser/
ls -la /home/sftpuser/docs/

# Iniciar el script de proxy FTP
echo "Iniciando proxy FTP..."
python3 /opt/scripts/ftp-proxy.py &

# Mostrar información del servicio
echo "Proxy SFTP iniciado en puerto 22"
echo "Mapeando acceso al servidor FTP anónimo en 172.40.0.10"

# Mantener el contenedor funcionando
tail -f /dev/null