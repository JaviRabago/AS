#!/bin/bash

# Crear directorios necesarios para vsftpd
mkdir -p /var/run/vsftpd/empty

# Asegurar permisos correctos
echo "Verificando y asegurando permisos..."

# Para cada programa, verificar permisos
for i in $(seq 1 5); do
    echo "Configurando permisos para SW$i"
    
    # Desarrollo: empleadoX tiene control total
    chmod 770 /var/doc_server/desarrollo/SW$i
    chown -R empleado$i:empleado$i /var/doc_server/desarrollo/SW$i
    
    # Revisión: empleadoX puede escribir, revisor tiene control total
    chmod 770 /var/doc_server/revision/SW$i
    chown revisor:revisor /var/doc_server/revision/SW$i
    setfacl -m u:empleado$i:rwx /var/doc_server/revision/SW$i
    
    # Público: sólo revisor puede escribir, todos pueden leer
    chmod 755 /var/doc_server/publico/SW$i
    chown revisor:revisor /var/doc_server/publico/SW$i
done

# Configurar permisos para FTP anónimo
chown -R nobody:nogroup /var/doc_server/publico
chmod -R 755 /var/doc_server/publico

# Iniciar servicios
echo "Iniciando servicios Samba y FTP..."

# Iniciar Samba
service smbd start
service nmbd start

# Iniciar VSFTPD
service vsftpd start

# Imprimir información de servicio
echo "Servidor Samba iniciado en puertos 139, 445"
echo "Servidor FTP iniciado en puerto 21 (control) y 20 (datos)"
echo "Puertos pasivos FTP: 30000-30020"

echo "Usuarios configurados:"
for i in $(seq 1 5); do
    echo "empleado$i - password$i (acceso a desarrollo/SW$i y revision/SW$i)"
done
echo "revisor - revisorpass (acceso total a todos los directorios)"
echo "anonymous - sin contraseña (acceso de solo lectura a publico)"

# Mantener el contenedor funcionando
tail -f /dev/null