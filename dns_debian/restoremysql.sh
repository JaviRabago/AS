#!/bin/bash

# Configuración de variables
MYSQL_BACKUP_DIR="/backups/mysql"
LOG_FILE="/var/log/restore.log"
MYSQL_IP=$(grep "dev-mysql" /etc/dnsmasq.hosts | awk '{print $1}')

# Función para log
log_message() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> $LOG_FILE
}

log_message "Iniciando proceso de restauración de MySQL"

# Verificar que existan backups
if [ ! -d "$MYSQL_BACKUP_DIR" ] || [ -z "$(ls -A $MYSQL_BACKUP_DIR)" ]; then
    log_message "Error: No se encontraron backups de MySQL en $MYSQL_BACKUP_DIR"
    echo "Error: No se encontraron backups de MySQL"
    exit 1
fi

# Encontrar el backup más reciente
LATEST_BACKUP=$(ls -t $MYSQL_BACKUP_DIR/mysql_all_*.sql.gz 2>/dev/null | head -1)

if [ -z "$LATEST_BACKUP" ]; then
    log_message "Error: No se encontraron archivos de backup válidos en $MYSQL_BACKUP_DIR"
    echo "Error: No se encontraron archivos de backup válidos"
    exit 1
fi

log_message "Backup más reciente encontrado: $LATEST_BACKUP"
echo "Se restaurará el backup: $LATEST_BACKUP"

# Descomprimir el backup
UNCOMPRESSED_FILE="${LATEST_BACKUP%.gz}"
log_message "Descomprimiendo backup..."
gunzip -c "$LATEST_BACKUP" > "$UNCOMPRESSED_FILE"

if [ $? -ne 0 ]; then
    log_message "Error al descomprimir el archivo $LATEST_BACKUP"
    echo "Error al descomprimir el archivo de backup"
    exit 1
fi

# Restaurar la base de datos
log_message "Iniciando restauración de MySQL desde $UNCOMPRESSED_FILE"
echo "Restaurando MySQL... Esto puede tomar varios minutos."

mysql -h $MYSQL_IP -u john -pmysql < "$UNCOMPRESSED_FILE"

if [ $? -eq 0 ]; then
    log_message "Restauración de MySQL completada exitosamente"
    echo "Restauración de MySQL completada exitosamente"
else
    log_message "Error en la restauración de MySQL"
    echo "Error en la restauración de MySQL"
    exit 1
fi

# Eliminar archivo descomprimido temporal
rm "$UNCOMPRESSED_FILE"
log_message "Archivo temporal eliminado"

log_message "Proceso de restauración de MySQL finalizado"
echo "Proceso de restauración de MySQL finalizado"