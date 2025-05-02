FROM debian:bookworm

# Instalar paquetes necesarios
RUN apt-get update && apt-get install -y \
    openssh-server \
    lftp \
    netcat-openbsd \
    inetutils-ping \
    iptables \
    iproute2 \
    curl \
    supervisor \
    python3 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*



# Crear directorio para el socket de SSH
RUN mkdir -p /run/sshd

# Crear directorio para los scripts
RUN mkdir -p /opt/scripts

# Crear usuario para SFTP
RUN useradd -m -d /home/sftpuser -s /bin/bash sftpuser \
    && echo "sftpuser:sftppassword" | chpasswd \
    && mkdir -p /home/sftpuser/docs \
    && chown root:root /home/sftpuser \
    && chmod 755 /home/sftpuser \
    && chown -R sftpuser:sftpuser /home/sftpuser/docs \
    && chmod -R 755 /home/sftpuser/docs

# Crear estructura de directorios para el acceso SFTP
RUN mkdir -p /home/sftpuser/docs \
    && chown sftpuser:sftpuser /home/sftpuser/docs

# Copiar script de proxy para acceder al FTP
COPY ftp-proxy.py /opt/scripts/ftp-proxy.py
RUN chmod +x /opt/scripts/ftp-proxy.py

# Copiar configuración de SSH
COPY sshd_config /etc/ssh/sshd_config

# Copiar script para la configuración del servicio
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Configurar authorized_keys
COPY authorized_keys /home/sftpuser/.ssh/
RUN chown -R sftpuser:sftpuser /home/sftpuser/.ssh/ \
    && chmod 700 /home/sftpuser/.ssh/ \
    && chmod 600 /home/sftpuser/.ssh/authorized_keys

# Copiar configuración de supervisord
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# # Exponer puerto SSH
# EXPOSE 22

# Iniciar servicio
ENTRYPOINT ["/entrypoint.sh"]