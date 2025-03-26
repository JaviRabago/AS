#!/bin/bash

MYSQL_IP=$(grep "dev-mysql" /etc/dnsmasq.hosts | awk '{print $1}')
POSTGRES_IP=$(grep "prod-postgres" /etc/dnsmasq.hosts | awk '{print $1}')

# Configuración de variables
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
MYSQL_BACKUP_DIR="/backups/mysql"
POSTGRES_BACKUP_DIR="/backups/postgres"
BACKUP_RETENTION_DAYS=7

# Función para log
log_message() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> /var/log/backup.log
}

log_message "Iniciando proceso de backup"

# Crear directorios de backup si no existen
mkdir -p $MYSQL_BACKUP_DIR $POSTGRES_BACKUP_DIR

# Backup de MySQL
log_message "Iniciando backup de MySQL"
# mysqldump -h dev-mysql -u john -pmysql --all-databases > $MYSQL_BACKUP_DIR/mysql_all_${TIMESTAMP}.sql
#  2>/dev/null
mysqldump -h $MYSQL_IP -u john -pmysql --all-databases > $MYSQL_BACKUP_DIR/mysql_all_${TIMESTAMP}.sql
if [ $? -eq 0 ]; then
    log_message "Backup de MySQL completado exitosamente"
    # Comprimir backup
    gzip $MYSQL_BACKUP_DIR/mysql_all_${TIMESTAMP}.sql
    log_message "Backup de MySQL comprimido"
else
    log_message "Error en backup de MySQL"
fi

# Backup de PostgreSQL
log_message "Iniciando backup de PostgreSQL"
# PGPASSWORD=postgres pg_dump -h prod-postgres -U john -d tasksdb > $POSTGRES_BACKUP_DIR/postgres_tasksdb_${TIMESTAMP}.sql
#  2>/dev/null
PGPASSWORD=postgres pg_dump -h $POSTGRES_IP -U john -d tasksdb > $POSTGRES_BACKUP_DIR/postgres_tasksdb_${TIMESTAMP}.sql
if [ $? -eq 0 ]; then
    log_message "Backup de PostgreSQL completado exitosamente"
    # Comprimir backup
    gzip $POSTGRES_BACKUP_DIR/postgres_tasksdb_${TIMESTAMP}.sql
    log_message "Backup de PostgreSQL comprimido"
else
    log_message "Error en backup de PostgreSQL"
fi

# Eliminar backups antiguos
log_message "Eliminando backups antiguos (más de $BACKUP_RETENTION_DAYS días)"
find $MYSQL_BACKUP_DIR -name "*.sql.gz" -type f -mtime +$BACKUP_RETENTION_DAYS -delete
find $POSTGRES_BACKUP_DIR -name "*.sql.gz" -type f -mtime +$BACKUP_RETENTION_DAYS -delete

log_message "Proceso de backup finalizado"