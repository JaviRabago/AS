#!/bin/bash
set -e

# Configurar 172.10.0.2 como ruta predeterminada para todo el tráfico
ip route del default
ip route add default via 172.10.0.2


# Variables
OVPN_DATA="/etc/openvpn"
EASYRSA_DIR="/usr/share/easy-rsa"
SERVER_CN="vpnserver"
CLIENT_DEV="dev_user"
CLIENT_PROD="svc_prod_user"
CLIENTS_DIR="${OVPN_DATA}/clients"

# Crear directorio de clientes si no existe
mkdir -p ${CLIENTS_DIR}

# Verificar si ya está inicializado
if [ ! -f "$OVPN_DATA/openvpn.conf" ]; then
    echo "Inicializando OpenVPN..."
    
    # Generar configuración inicial con DNS
    ovpn_genconfig -u udp://vpnserver -s 10.8.0.0/24 \
      -p "route 172.40.0.0 255.255.255.0" \
      -p "route 172.30.0.0 255.255.255.0" \
      -p "route 172.20.0.0 255.255.255.0" \
      -p "dhcp-option DNS 172.20.0.100"
    
    # Iniciar PKI y crear CA no interactivamente
    echo "Generando PKI y CA..."
    EASYRSA_BATCH=1 EASYRSA_REQ_CN="$SERVER_CN CA" ovpn_initpki nopass

    # Crear archivos CCD (client-config-dir) para control de acceso por usuario
    echo "Configurando directorio CCD..."
    mkdir -p ${OVPN_DATA}/ccd
    
    # Modificar configuración del servidor para usar CCD
    echo "client-config-dir ccd" >> ${OVPN_DATA}/openvpn.conf
else
    # Si ya existe la configuración, asegurarse de que tenga la configuración DNS
    if ! grep -q "dhcp-option DNS 172.20.0.100" ${OVPN_DATA}/openvpn.conf; then
        echo "Añadiendo configuración DNS al servidor..."
        echo 'push "dhcp-option DNS 172.20.0.100"' >> ${OVPN_DATA}/openvpn.conf
    fi
fi

# Verificar y crear certificado para dev_user si no existe
if [ ! -f "${OVPN_DATA}/pki/issued/${CLIENT_DEV}.crt" ]; then
    echo "Creando usuario dev_user (acceso solo a red development)..."
    EASYRSA_BATCH=1 easyrsa build-client-full ${CLIENT_DEV} nopass
    
    # Configuración para dev_user - solo acceso a red development
    echo "iroute 172.40.0.0 255.255.255.0" > ${OVPN_DATA}/ccd/${CLIENT_DEV}
fi

# Verificar y crear configuración para dev_user si no existe
if [ ! -f "${CLIENTS_DIR}/${CLIENT_DEV}.ovpn" ]; then
    echo "Generando configuración para dev_user..."
    ovpn_getclient ${CLIENT_DEV} > ${CLIENTS_DIR}/${CLIENT_DEV}.ovpn
    
    # Modificar configuración para dev_user (solo acceso a red development)
    sed -i '/^redirect-gateway/d' ${CLIENTS_DIR}/${CLIENT_DEV}.ovpn
    echo "route 172.40.0.0 255.255.255.0" >> ${CLIENTS_DIR}/${CLIENT_DEV}.ovpn
fi

# Verificar y crear certificado para svc_prod_user si no existe
if [ ! -f "${OVPN_DATA}/pki/issued/${CLIENT_PROD}.crt" ]; then
    echo "Creando usuario svc_prod_user (acceso a redes production y service)..."
    EASYRSA_BATCH=1 easyrsa build-client-full ${CLIENT_PROD} nopass
    
    # Configuración para svc_prod_user - acceso a production y service
    echo "iroute 172.30.0.0 255.255.255.0" > ${OVPN_DATA}/ccd/${CLIENT_PROD}
    echo "iroute 172.20.0.0 255.255.255.0" >> ${OVPN_DATA}/ccd/${CLIENT_PROD}
fi

# Verificar y crear configuración para svc_prod_user si no existe
if [ ! -f "${CLIENTS_DIR}/${CLIENT_PROD}.ovpn" ]; then
    echo "Generando configuración para svc_prod_user..."
    ovpn_getclient ${CLIENT_PROD} > ${CLIENTS_DIR}/${CLIENT_PROD}.ovpn
    
    # Modificar configuración para svc_prod_user (acceso a production y service)
    sed -i '/^redirect-gateway/d' ${CLIENTS_DIR}/${CLIENT_PROD}.ovpn
    echo "route 172.30.0.0 255.255.255.0" >> ${CLIENTS_DIR}/${CLIENT_PROD}.ovpn
    echo "route 172.20.0.0 255.255.255.0" >> ${CLIENTS_DIR}/${CLIENT_PROD}.ovpn
fi

# Mostrar confirmación
echo "Configuración de usuarios VPN:"
ls -la ${CLIENTS_DIR}
echo "Configuración de reglas de acceso:"
ls -la ${OVPN_DATA}/ccd

# Iniciar OpenVPN
echo "Iniciando servidor OpenVPN..."
exec ovpn_run