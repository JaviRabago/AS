FROM debian:latest

RUN mkdir -p /etc/docker-gen/templates /backups/mysql /backups/postgres

# Instalar dependencias básicas y NAS
RUN apt-get update && \
    apt-get install -y dnsmasq wget ca-certificates net-tools iproute2 \
    rsync cron openssh-server postgresql-client nano && \
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

# Configurar permisos
RUN chmod +x /start.sh /backup.sh && \
    mkdir -p /var/run/sshd && \
    chmod 0755 /var/run/sshd && \
    echo "root:password" | chpasswd

# Agregar crontab para backups automáticos
RUN (crontab -l 2>/dev/null; echo "0 2 * * * /backup.sh") | crontab -

# Exponer puertos necesarios
EXPOSE 53/tcp 53/udp

CMD ["/start.sh"]


