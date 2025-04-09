FROM debian:latest

RUN mkdir -p /etc/docker-gen/templates /backups/mysql /backups/postgres

# Instalar dependencias básicas y NAS
RUN apt-get update && \
    apt-get install -y dnsmasq wget ca-certificates net-tools iproute2 \
    rsync cron openssh-server postgresql-client nano default-mysql-client iputils-ping net-tools && \
    rm -rf /var/lib/apt/lists/*

# Configurar Docker Gen
RUN wget -O /tmp/docker-gen.tar.gz https://github.com/jwilder/docker-gen/releases/download/0.7.4/docker-gen-linux-amd64-0.7.4.tar.gz && \
    tar -C /usr/local/bin -xzvf /tmp/docker-gen.tar.gz && \
    rm /tmp/docker-gen.tar.gz && \
    chmod +x /usr/local/bin/docker-gen

# Copiar archivos de configuración
COPY dnsmasq.conf /etc/dnsmasq.conf
COPY dnsmasq.tmpl /etc/docker-gen/templates/dnsmasq.tmpl
COPY start.sh /start.sh
COPY backup.sh /backup.sh
COPY restoremysql.sh /restoremysql.sh
COPY restorepostgres.sh /restorepostgres.sh

# Crear el directorio .ssh primero con los permisos correctos
RUN mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh

# Copiar el archivo de clave pública directamente al destino dentro de la imagen
# Docker buscará 'authorized_keys.pub' en el directorio './dns_debian' durante la construcción
COPY authorized_keys.pub /root/.ssh/authorized_keys

# Configurar permisos del archivo copiado y ajustar configuración de sshd
RUN chmod 600 /root/.ssh/authorized_keys && \
    # Configurar sshd para permitir claves y deshabilitar contraseñas
    sed -i 's/^#?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/^#?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config && \
    sed -i 's/^#?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config && \
    # Crear directorio para el socket de sshd (puede que ya exista, -p lo maneja)
    mkdir -p /var/run/sshd && \
    chmod 0755 /var/run/sshd


# Configurar permisos para scripts y cron
RUN chmod +x /start.sh /backup.sh /restoremysql.sh /restorepostgres.sh

# Agregar crontab para backups automáticos
RUN (crontab -l 2>/dev/null; echo "0 2 * * * /backup.sh") | crontab -

# Exponer puertos necesarios
EXPOSE 53/tcp 53/udp

CMD ["/start.sh"]


