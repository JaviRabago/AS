#!/bin/bash

echo 'Router interfaces:'
ip addr

echo 'Setting up routing between networks...'
# Reglas existentes para enmascaramiento
iptables -t nat -A POSTROUTING -s 172.30.0.0/24 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 172.40.0.0/24 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 172.20.0.0/24 -j MASQUERADE
# Nueva regla para enmascaramiento de la red VPN
iptables -t nat -A POSTROUTING -s 172.10.0.0/24 -j MASQUERADE
# Enmascaramiento para clientes conectados a la VPN
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j MASQUERADE

# Reglas de reenvío existentes
iptables -A FORWARD -i eth0 -o eth1 -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -j ACCEPT
# Nueva regla para incluir la interfaz de la red VPN (eth3)
iptables -A FORWARD -i eth3 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth3 -o eth1 -j ACCEPT
iptables -A FORWARD -i eth3 -o eth2 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth3 -j ACCEPT
iptables -A FORWARD -i eth1 -o eth3 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth3 -j ACCEPT

# --- Configuración para control de acceso VPN ---
# Control para dev_user: solo acceso a red development (172.40.0.0/24)
echo "Configurando reglas para clientes VPN..."
iptables -A FORWARD -s 10.8.0.0/24 -d 172.40.0.0/24 -m comment --comment "dev_user VPN access" -j ACCEPT

# Control para svc_prod_user: acceso a redes production (172.30.0.0/24) y service (172.20.0.0/24)
iptables -A FORWARD -s 10.8.0.0/24 -d 172.30.0.0/24 -m comment --comment "svc_prod_user VPN access to production" -j ACCEPT
iptables -A FORWARD -s 10.8.0.0/24 -d 172.20.0.0/24 -m comment --comment "svc_prod_user VPN access to service" -j ACCEPT

# Denegar explícitamente el acceso no autorizado desde VPN a otras redes
iptables -A FORWARD -s 10.8.0.0/24 -j DROP

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

# --- Redirección del puerto 1194/UDP para OpenVPN ---
# Esperar a que el contenedor OpenVPN esté disponible
echo "Esperando a que OpenVPN esté disponible..."
until ping -c 1 openvpn > /dev/null 2>&1; do
    echo "Esperando a OpenVPN..."
    sleep 2
done

# Obtener la IP del contenedor OpenVPN
OPENVPN_IP=$(getent hosts openvpn | awk '{ print $1 }')
echo "IP de OpenVPN detectada: $OPENVPN_IP"

# Configurar redirección del puerto 1194/UDP al OpenVPN
echo "Configurando redirección de UDP (puerto 1194) al OpenVPN ($OPENVPN_IP)..."
iptables -t nat -A PREROUTING -p udp --dport 1194 -j DNAT --to-destination $OPENVPN_IP:1194

# Permitir el tráfico reenviado al puerto 1194 de OpenVPN
iptables -A FORWARD -p udp -d $OPENVPN_IP --dport 1194 -j ACCEPT

# Permitir conexiones SSH desde clientes VPN al router
iptables -A INPUT -p tcp -s 10.8.0.0/24 --dport 22 -j ACCEPT
# Permitir conexiones SSH al router desde cualquier red
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

echo 'IP forwarding status:'
cat /proc/sys/net/ipv4/ip_forward

echo 'Iptables rules:'
iptables -L -v -n

echo 'NAT rules:'
iptables -t nat -L -v -n

echo "Iniciando servicio SSH..."
/usr/sbin/sshd -D &

tail -f /dev/null