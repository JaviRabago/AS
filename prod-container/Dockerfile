FROM debian:latest

RUN apt-get update && \
    apt-get install -y iproute2 iputils-ping traceroute dnsutils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint-prod.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]