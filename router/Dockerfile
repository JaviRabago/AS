FROM debian:latest

RUN apt-get update && \
    apt-get install -y iptables iproute2 iputils-ping dnsutils dnsmasq tcpdump openssh-server && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    useradd -m john && \
    echo "john:password" | chpasswd && \
    # Configurar SSH correctamente
    mkdir -p /run/sshd && \
    # Permitir login con contraseña
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    # Asegurar que UsePAM está configurado
    sed -i 's/#UsePAM yes/UsePAM yes/' /etc/ssh/sshd_config

COPY entrypoint-router.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]