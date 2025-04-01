#!/bin/bash

# Configuración de variables
POSTGRES_BACKUP_DIR="/backups/postgres"
LOG_FILE="/var/log/restore.log"
POSTGRES_IP=$(grep "prod-postgres" /etc/dnsmasq.hosts | awk '{print $1}')

# Función para log
log_message() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> $LOG_FILE
}

log_message "Iniciando proceso de restauración de PostgreSQL"

# Verificar que existan backups
if [ ! -d "$POSTGRES_BACKUP_DIR" ] || [ -z "$(ls -A $POSTGRES_BACKUP_DIR)" ]; then
    log_message "Error: No se encontraron backups de PostgreSQL en $POSTGRES_BACKUP_DIR"
    echo "Error: No se encontraron backups de PostgreSQL"
    exit 1
fi

# Encontrar el backup más reciente
LATEST_BACKUP=$(ls -t $POSTGRES_BACKUP_DIR/postgres_tasksdb_*.sql.gz 2>/dev/null | head -1)

if [ -z "$LATEST_BACKUP" ]; then
    log_message "Error: No se encontraron archivos de backup válidos en $POSTGRES_BACKUP_DIR"
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
log_message "Iniciando restauración de PostgreSQL desde $UNCOMPRESSED_FILE"
echo "Restaurando PostgreSQL... Esto puede tomar varios minutos."

# Primero forzamos la desconexión de usuarios y luego recreamos la base de datos
PGPASSWORD=postgres psql -h $POSTGRES_IP -U john -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='tasksdb';"
PGPASSWORD=postgres psql -h $POSTGRES_IP -U john -d postgres -c "DROP DATABASE IF EXISTS tasksdb;"
PGPASSWORD=postgres psql -h $POSTGRES_IP -U john -d postgres -c "CREATE DATABASE tasksdb;"

if [ $? -ne 0 ]; then
    log_message "Error al recrear la base de datos tasksdb"
    echo "Error al recrear la base de datos"
    rm "$UNCOMPRESSED_FILE"
    exit 1
fi

# Ahora restauramos el contenido
PGPASSWORD=postgres psql -h $POSTGRES_IP -U john -d tasksdb < "$UNCOMPRESSED_FILE"

if [ $? -eq 0 ]; then
    log_message "Restauración de PostgreSQL completada exitosamente"
    echo "Restauración de PostgreSQL completada exitosamente"
else
    log_message "Error en la restauración de PostgreSQL"
    echo "Error en la restauración de PostgreSQL"
    rm "$UNCOMPRESSED_FILE"
    exit 1
fi

# Eliminar archivo descomprimido temporal
rm "$UNCOMPRESSED_FILE"
log_message "Archivo temporal eliminado"

log_message "Proceso de restauración de PostgreSQL finalizado"
echo "Proceso de restauración de PostgreSQL finalizado"