FROM debian:latest

RUN mkdir -p /etc/docker-gen/templates

RUN apt-get update && \
    apt-get install -y dnsmasq wget ca-certificates net-tools iproute2 && \
    rm -rf /var/lib/apt/lists/*

RUN wget -O /tmp/docker-gen.tar.gz https://github.com/jwilder/docker-gen/releases/download/0.7.4/docker-gen-linux-amd64-0.7.4.tar.gz && \
    tar -C /usr/local/bin -xzvf /tmp/docker-gen.tar.gz && \
    rm /tmp/docker-gen.tar.gz && \
    chmod +x /usr/local/bin/docker-gen

COPY dnsmasq.conf /etc/dnsmasq.conf
COPY dnsmasq.tmpl /etc/docker-gen/templates/dnsmasq.tmpl
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 53/tcp 53/udp

CMD ["/start.sh"]



