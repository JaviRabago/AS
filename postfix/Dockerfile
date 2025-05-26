FROM debian:latest

# Instala herramientas necesarias
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y postfix iproute2 iputils-ping procps bsdutils maildrop rsyslog && \
    apt-get clean

RUN maildirmake /root/Maildir && \
chown -R root:root /root/Maildir

# Copiar el main.cf personalizado
COPY main.cf /etc/postfix/main.cf
RUN chmod o-w,g-w /etc/postfix/main.cf

# Copia el script de red
COPY set-default-route.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/set-default-route.sh

EXPOSE 25 587

ENTRYPOINT ["/usr/local/bin/set-default-route.sh"]
CMD ["postfix", "start-fg"]