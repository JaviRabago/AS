FROM debian:latest

RUN apt-get update && \
    apt-get install -y iptables iproute2 iputils-ping dnsutils dnsmasq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint-router.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]