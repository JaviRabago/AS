#!/bin/bash

# Configurar rutas
ip route add 172.30.0.0/24 via 172.40.0.2
ip route add 172.20.0.0/24 via 172.40.0.2

# Configurar DNS explícitamente
echo "nameserver 172.20.0.100" > /etc/resolv.conf

echo 'Dev container routing:'
ip route

echo 'DNS configuration:'
cat /etc/resolv.conf

# Probar DNS
echo 'Testing DNS resolution:'
dig +short prod-container.service @172.20.0.100 || echo "DNS query failed"

# Mantener el contenedor ejecutándose
tail -f /dev/null