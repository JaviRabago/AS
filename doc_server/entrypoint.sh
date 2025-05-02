#!/bin/bash

#Configurar 172.40.0.150 como ruta predeterminada para todo el tráfico
ip route del default
ip route add default via 172.40.0.150

# Crear directorios necesarios para vsftpd
mkdir -p /var/run/vsftpd/empty

# Asegurar que hay contenido en los directorios públicos
for i in $(seq 1 5); do
    echo "Creando archivos de ejemplo en el directorio público SW$i"
    mkdir -p /var/doc_server/publico/SW$i
    echo "Este es un archivo de ejemplo del programa SW$i" > /var/doc_server/publico/SW$i/leeme.txt
    echo "Contenido técnico de SW$i" > /var/doc_server/publico/SW$i/documentacion.txt
    echo "Manual de usuario de SW$i" > /var/doc_server/publico/SW$i/manual.txt
done

# Corregir permisos del archivo de configuración de vsftpd
cp /etc/vsftpd.conf /etc/vsftpd.conf.orig
chown root:root /etc/vsftpd.conf
chmod 600 /etc/vsftpd.conf

# Asegurar permisos correctos
echo "Verificando y asegurando permisos..."

# Permisos para el directorio principal
chmod 755 /var/doc_server
chmod 755 /var/doc_server/desarrollo
chmod 755 /var/doc_server/revision
chmod 755 /var/doc_server/publico

# Para cada programa, verificar permisos
for i in $(seq 1 5); do
    echo "Configurando permisos para SW$i"
    
    # Desarrollo: empleadoX tiene control total
    chmod 770 /var/doc_server/desarrollo/SW$i
    chown -R empleado$i:empleado$i /var/doc_server/desarrollo/SW$i
    # Asegurar que revisor pueda acceder
    setfacl -m u:revisor:rwx /var/doc_server/desarrollo/SW$i
    
    # Revisión: empleadoX puede escribir, revisor tiene control total
    chmod 770 /var/doc_server/revision/SW$i
    chown revisor:revisor /var/doc_server/revision/SW$i
    setfacl -m u:empleado$i:rwx /var/doc_server/revision/SW$i
    
    # Público: sólo revisor puede escribir, todos pueden leer
    chmod 755 /var/doc_server/publico/SW$i
    chown revisor:revisor /var/doc_server/publico/SW$i
done

# # Configurar permisos para FTP anónimo
# chown nobody:nogroup /var/doc_server/publico
# chmod 755 /var/doc_server/publico

# Iniciar servicios
echo "Iniciando servicios Samba y FTP..."

# Iniciar Samba
service smbd start
service nmbd start

# Verificar estado de Samba
echo "Estado del servicio Samba:"
service smbd status

# Iniciar VSFTPD con depuración
echo "Iniciando VSFTPD con depuración..."
vsftpd /etc/vsftpd.conf &

# Verificar estado de VSFTPD
echo "Verificando que VSFTPD esté en ejecución:"
ps aux | grep vsftpd
ss -tulpn | grep vsftpd

# Verificar que el puerto 21 esté escuchando
echo "Verificando puerto 21:"
ss -tulpn | grep ':21'

echo "Usuarios configurados:"
for i in $(seq 1 5); do
    echo "empleado$i - password$i (acceso a desarrollo/SW$i y revision/SW$i)"
done
echo "revisor - revisorpass (acceso total a todos los directorios)"
echo "anonymous - sin contraseña (acceso de solo lectura a publico)"

# Mantener el contenedor funcionando
tail -f /dev/null