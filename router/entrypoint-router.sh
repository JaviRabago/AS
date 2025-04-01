#!/bin/bash

echo 'Router interfaces:'
ip addr

echo "Setting up routing between networks..."

# --- CONFIGURACIÓN INICIAL ---
# Identificar las redes
PROD_NET="172.30.0.0/24"
DEV_NET="172.40.0.0/24"
SERVICE_NET="172.20.0.0/24"
VPN_NET="172.10.0.0/24"
VPN_CLIENTS="10.8.0.0/24"

# IP del DNS server
DNS_IP="172.20.0.100"
echo "IP del DNS server: $DNS_IP"

# --- BLOQUEAR TODO EL ACCESO PRIMERO ---
# Establecer política por defecto para FORWARD a DROP
echo "Bloqueando todo el tráfico por defecto..."
iptables -P FORWARD DROP
echo "Política DROP establecida para cadena FORWARD"

# --- REGLAS DE MASCARADA ---
echo "Configurando reglas de mascarada (NAT)..."
iptables -t nat -A POSTROUTING -s $PROD_NET -j MASQUERADE
iptables -t nat -A POSTROUTING -s $DEV_NET -j MASQUERADE
iptables -t nat -A POSTROUTING -s $SERVICE_NET -j MASQUERADE
iptables -t nat -A POSTROUTING -s $VPN_NET -j MASQUERADE
iptables -t nat -A POSTROUTING -s $VPN_CLIENTS -j MASQUERADE

# --- PERMITIR TRÁFICO INTERNO ---
echo "Permitiendo tráfico interno específico..."

# 1. COMUNICACIÓN DENTRO DE LAS MISMAS REDES
echo "Permitiendo comunicación dentro de cada red..."
iptables -A FORWARD -s $PROD_NET -d $PROD_NET -j ACCEPT
iptables -A FORWARD -s $DEV_NET -d $DEV_NET -j ACCEPT
iptables -A FORWARD -s $SERVICE_NET -d $SERVICE_NET -j ACCEPT
iptables -A FORWARD -s $VPN_NET -d $VPN_NET -j ACCEPT
iptables -A FORWARD -s $VPN_CLIENTS -d $VPN_CLIENTS -j ACCEPT

# 2. PERMITIR SERVICE-DEVELOPMENT
echo "Permitiendo comunicación entre service y development..."
iptables -A FORWARD -s $SERVICE_NET -d $DEV_NET -j ACCEPT
iptables -A FORWARD -s $DEV_NET -d $SERVICE_NET -j ACCEPT

# 3. CONFIGURACIÓN DE POSTGRES (EXCEPCIÓN)
echo "Configurando excepción para postgres..."
POSTGRES_IP=$(getent hosts prod-postgres | awk '{ print $1 }')
# if [ -z "$POSTGRES_IP" ]; then
#     echo "No se pudo obtener la IP de postgres, usando valor estático"
#     POSTGRES_IP="172.30.0.2" 
# fi
echo "IP de postgres detectada: $POSTGRES_IP"

# Permitir comunicación entre postgres y DNS
echo "Permitiendo comunicación específica postgres -> dns..."
iptables -A FORWARD -s $POSTGRES_IP -d $DNS_IP -j ACCEPT
iptables -A FORWARD -d $POSTGRES_IP -s $DNS_IP -j ACCEPT

echo "Configurando acceso al DNS..."
# Permitir que todos se comuniquen con el DNS
for net in "$PROD_NET" "$DEV_NET" "$SERVICE_NET" "$VPN_NET"; do
    iptables -A FORWARD -s $net -d $DNS_IP -p udp --dport 53 -j ACCEPT
    iptables -A FORWARD -s $DNS_IP -d $net -p udp --sport 53 -j ACCEPT
    iptables -A FORWARD -s $net -d $DNS_IP -p tcp --dport 53 -j ACCEPT
    iptables -A FORWARD -s $DNS_IP -d $net -p tcp --sport 53 -j ACCEPT
done

# --- CONFIGURACIÓN NGINX (PORT 80) ---
echo "Configurando nginx (puerto 80)..."
NGINX_IP=$(getent hosts prod-nginx | awk '{ print $1 }')
if [ -z "$NGINX_IP" ]; then
    echo "No se pudo obtener la IP de nginx, usando valor estático"
    NGINX_IP="172.30.0.4"  # IP estática según logs
fi
echo "IP de nginx detectada: $NGINX_IP"

# Redirección del puerto 80 hacia nginx
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination $NGINX_IP:80

# Permitir el tráfico hacia nginx
iptables -A FORWARD -d $NGINX_IP -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -s $NGINX_IP -p tcp --sport 80 -j ACCEPT

# Obtener IP de app-prod
APP_PROD_IP=$(getent hosts prod-app | awk '{ print $1 }')
if [ -z "$APP_PROD_IP" ]; then
    echo "No se pudo obtener la IP de app-prod, usando valor estático"
    APP_PROD_IP="172.30.0.3"  # IP estática según logs
fi
echo "IP de app-prod detectada: $APP_PROD_IP"

# Permitir comunicación entre nginx y app-prod
iptables -A FORWARD -s $NGINX_IP -d $APP_PROD_IP -j ACCEPT
iptables -A FORWARD -s $APP_PROD_IP -d $NGINX_IP -j ACCEPT

# --- CONFIGURACIÓN APACHE (PORT 8080) ---
echo "Configurando apache (puerto 8080)..."
APACHE_IP=$(getent hosts dev-apache | awk '{ print $1 }')
if [ -z "$APACHE_IP" ]; then
    echo "No se pudo obtener la IP de apache, usando valor estático"
    APACHE_IP="172.40.0.4"  # IP estática según logs
fi
echo "IP de apache detectada: $APACHE_IP"

# Redirección del puerto 8080 hacia apache
iptables -t nat -A PREROUTING -p tcp --dport 8080 -j DNAT --to-destination $APACHE_IP:80

# Permitir el tráfico hacia apache
iptables -A FORWARD -d $APACHE_IP -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -s $APACHE_IP -p tcp --sport 80 -j ACCEPT

# Obtener IP de app-dev
APP_DEV_IP=$(getent hosts dev-app | awk '{ print $1 }')
if [ -z "$APP_DEV_IP" ]; then
    echo "No se pudo obtener la IP de app-dev, usando valor estático"
    APP_DEV_IP="172.40.0.3"  # IP estática según logs
fi
echo "IP de app-dev detectada: $APP_DEV_IP"

# Permitir comunicación entre apache y app-dev
iptables -A FORWARD -s $APACHE_IP -d $APP_DEV_IP -j ACCEPT
iptables -A FORWARD -s $APP_DEV_IP -d $APACHE_IP -j ACCEPT

# --- CONFIGURACIÓN OPENVPN (PORT 1194/UDP) ---
echo "Configurando OpenVPN (puerto 1194/UDP)..."
OPENVPN_IP=$(getent hosts openvpn | awk '{ print $1 }')
if [ -z "$OPENVPN_IP" ]; then
    echo "No se pudo obtener la IP de OpenVPN, usando valor estático"
    OPENVPN_IP="172.10.0.3" 
fi
echo "IP de OpenVPN detectada: $OPENVPN_IP"

# Redirección del puerto 1194/UDP hacia OpenVPN
iptables -t nat -A PREROUTING -p udp --dport 1194 -j DNAT --to-destination $OPENVPN_IP:1194

# Permitir el tráfico hacia OpenVPN
iptables -A FORWARD -d $OPENVPN_IP -p udp --dport 1194 -j ACCEPT
iptables -A FORWARD -s $OPENVPN_IP -p udp --sport 1194 -j ACCEPT

# --- CONTROL DE ACCESO VPN ---
echo "Configurando acceso para clientes VPN..."
# Control para dev_user: solo acceso a red development
iptables -A FORWARD -s $VPN_CLIENTS -d $DEV_NET -m comment --comment "dev_user VPN access" -j ACCEPT

# Control para svc_prod_user: acceso a redes production y service
iptables -A FORWARD -s $VPN_CLIENTS -d $PROD_NET -m comment --comment "svc_prod_user VPN access to production" -j ACCEPT
iptables -A FORWARD -s $VPN_CLIENTS -d $SERVICE_NET -m comment --comment "svc_prod_user VPN access to service" -j ACCEPT

# Permitir respuestas a clientes VPN
iptables -A FORWARD -d $VPN_CLIENTS -m state --state ESTABLISHED,RELATED -j ACCEPT

# --- BLOQUEO EXPLÍCITO DE INTERNET ---
echo "Bloqueando explícitamente acceso a Internet..."
# Bloquear explícitamente el acceso a Google DNS (para redundancia)
for net in "$PROD_NET" "$DEV_NET" "$SERVICE_NET" "$VPN_NET" "$DNS_IP"; do
    iptables -A FORWARD -s $net -d 8.8.8.8 -j DROP
    iptables -A FORWARD -s $net -d 8.8.4.4 -j DROP
    iptables -A FORWARD -s $net -d 1.1.1.1 -j DROP
    iptables -A FORWARD -s $net -d 9.9.9.9 -j DROP
done

# --- BLOQUEO DE TRÁFICO SALIENTE A INTERNET ---
echo "Aplicando bloqueo adicional para acceso a Internet..."
# Bloquear todo el tráfico que sale al exterior
for net in "$PROD_NET" "$DEV_NET" "$SERVICE_NET" "$VPN_NET"; do
    iptables -A FORWARD -s $net ! -d 10.0.0.0/8 ! -d 172.16.0.0/12 ! -d 192.168.0.0/16 -j DROP
done

# --- CONFIGURACIÓN SSH ---
echo "Configurando acceso SSH..."
# Permitir SSH desde clientes VPN y todas las redes internas
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# --- LOGGING PARA DEPURACIÓN ---
echo "Configurando logs para depuración..."
iptables -A FORWARD -j LOG --log-prefix "IPTables-Dropped: " --log-level 4

# --- VERIFICACIÓN FINAL ---
echo "Verificando configuración..."
echo "IP forwarding status:"
cat /proc/sys/net/ipv4/ip_forward

echo "Iptables rules:"
iptables -L -v -n

echo "NAT rules:"
iptables -t nat -L -v -n

echo "Iniciando servicio SSH..."
/usr/sbin/sshd -D &

tail -f /dev/null