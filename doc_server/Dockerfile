FROM debian:latest

# Instalación de paquetes necesarios
RUN apt-get update && apt-get install -y \
    samba \
    smbclient \
    vsftpd \
    supervisor \
    iptables \
    iproute2 \
    iputils-ping \
    procps \
    acl \
    nano \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Crear estructura de directorios
RUN mkdir -p /var/doc_server/{desarrollo,revision,publico}

# Crear subdirectorios para cada SW
RUN for dir in desarrollo revision publico; do \
    for i in $(seq 1 5); do \
        mkdir -p /var/doc_server/$dir/SW$i; \
    done; \
done

# Crear usuarios
RUN for i in $(seq 1 5); do \
    useradd -m -s /usr/sbin/nologin empleado$i; \
    echo "empleado$i:password$i" | chpasswd; \
    (echo "password$i"; echo "password$i") | smbpasswd -a empleado$i; \
done

# Crear usuario revisor
RUN useradd -m -s /usr/sbin/nologin revisor; \
    echo "revisor:revisorpass" | chpasswd; \
    (echo "revisorpass"; echo "revisorpass") | smbpasswd -a revisor

# Crear el usuario ftp
RUN useradd -m -s /usr/sbin/nologin ftpuser; \
    echo "ftpuser:ftppass" | chpasswd; \
    chown -R ftpuser:ftpuser /var/doc_server/publico

# Configurar permisos
RUN chmod -R 770 /var/doc_server/desarrollo
RUN chmod -R 750 /var/doc_server/revision
RUN chmod -R 755 /var/doc_server/publico

# Para cada programa, establecer permisos específicos
RUN for i in $(seq 1 5); do \
    chown -R empleado$i:empleado$i /var/doc_server/desarrollo/SW$i; \
    chown -R revisor:revisor /var/doc_server/revision/SW$i; \
    chmod 750 /var/doc_server/revision/SW$i; \
    chown -R revisor:revisor /var/doc_server/publico/SW$i; \
done

# Copiar archivos de configuración
COPY smb.conf /etc/samba/smb.conf
COPY vsftpd.conf /etc/vsftpd.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh

# Make entrypoint executable
RUN chmod +x /entrypoint.sh

# Puerto para Samba
EXPOSE 139 445
# Puertos para FTP
EXPOSE 21 20
# Puertos pasivos de FTP
EXPOSE 30000-30020

# Comando de inicio
ENTRYPOINT ["/entrypoint.sh"]