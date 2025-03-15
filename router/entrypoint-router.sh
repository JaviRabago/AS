#!/bin/bash

echo 'Router interfaces:'
ip addr

echo 'Setting up routing between networks...'
# Reglas existentes para enmascaramiento
iptables -t nat -A POSTROUTING -s 172.30.0.0/24 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 172.40.0.0/24 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 172.20.0.0/24 -j MASQUERADE

# Reglas de reenvío existentes
iptables -A FORWARD -i eth0 -o eth1 -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -j ACCEPT

# --- Configuración para la red de producción (puerto 80) ---
# Esperar a que el contenedor nginx esté disponible
echo "Esperando a que nginx esté disponible..."
until ping -c 1 prod-nginx > /dev/null 2>&1; do
    echo "Esperando a nginx..."
    sleep 2
done

# Obtener la IP del contenedor nginx
NGINX_IP=$(getent hosts prod-nginx | awk '{ print $1 }')
echo "IP de nginx detectada: $NGINX_IP"

# Configurar redirección del puerto 80 al nginx
echo "Configurando redirección de HTTP al nginx ($NGINX_IP)..."
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination $NGINX_IP:80

# Permitir el tráfico reenviado al puerto 80 de nginx
iptables -A FORWARD -p tcp -d $NGINX_IP --dport 80 -j ACCEPT

# --- Configuración para la red de desarrollo (puerto 8080) ---
# Esperar a que el contenedor apache esté disponible
echo "Esperando a que apache esté disponible..."
until ping -c 1 dev-apache > /dev/null 2>&1; do
    echo "Esperando a apache..."
    sleep 2
done

# Obtener la IP del contenedor apache
APACHE_IP=$(getent hosts dev-apache | awk '{ print $1 }')
echo "IP de apache detectada: $APACHE_IP"

# Configurar redirección del puerto 8080 al apache
echo "Configurando redirección de HTTP (puerto 8080) al apache ($APACHE_IP)..."
iptables -t nat -A PREROUTING -p tcp --dport 8080 -j DNAT --to-destination $APACHE_IP:80

# Permitir el tráfico reenviado al puerto 80 de apache
iptables -A FORWARD -p tcp -d $APACHE_IP --dport 80 -j ACCEPT

echo 'IP forwarding status:'
cat /proc/sys/net/ipv4/ip_forward

echo 'Iptables rules:'
iptables -L -v -n

echo 'NAT rules:'
iptables -t nat -L -v -n

tail -f /dev/null