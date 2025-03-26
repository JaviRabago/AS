#!/bin/bash

# Colores para mejor visualización
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== ANÁLISIS DE CONFIGURACIÓN DNS ===${NC}"

# Función para mostrar configuración DNS
show_dns_config() {
    local container=$1
    
    echo -e "${BLUE}=== Configuración DNS para: ${container} ===${NC}"
    
    echo -e "${YELLOW}Contenido de /etc/resolv.conf:${NC}"
    docker exec ${container} cat /etc/resolv.conf 2>/dev/null || echo -e "${RED}No se pudo leer /etc/resolv.conf${NC}"
    
    echo -e "\n${YELLOW}Variables de entorno relacionadas con DNS:${NC}"
    docker exec ${container} env | grep -i dns || echo "No se encontraron variables de entorno DNS"
    
    echo -e "\n${YELLOW}Probando resolución de nombres:${NC}"
    
    # Probar resolución de nombres comunes dentro del entorno docker
    for target in "prod-app" "dev-app" "dns_server" "router"; do
        if [ "$container" != "$target" ]; then
            echo -n "Resolviendo $target: "
            ip=$(docker exec ${container} getent hosts ${target} 2>/dev/null | awk '{ print $1 }')
            if [ -n "$ip" ]; then
                echo -e "${GREEN}OK - $ip${NC}"
            else
                echo -e "${RED}FALLIDO${NC}"
            fi
        fi
    done
    
    echo ""
}

# Verificar que el servidor DNS está funcionando correctamente
echo -e "${YELLOW}Verificando servidor DNS (dns_server):${NC}"
if docker ps | grep -q dns_server; then
    echo -e "${GREEN}Contenedor dns_server está ejecutándose${NC}"
    
    # Verificar si bind9 está ejecutándose
    if docker exec dns_server ps aux | grep -q "[n]amed"; then
        echo -e "${GREEN}Servicio DNS (named) está ejecutándose${NC}"
    else
        echo -e "${RED}¡ALERTA! Servicio DNS (named) NO está ejecutándose${NC}"
        echo -e "Intentando iniciar el servicio:"
        docker exec dns_server service bind9 start || docker exec dns_server service named start
    fi
    
    # Verificar si el puerto 53 está escuchando
    if docker exec dns_server netstat -tuln | grep -q ":53"; then
        echo -e "${GREEN}Servidor DNS está escuchando en el puerto 53${NC}"
    else
        echo -e "${RED}¡ALERTA! Puerto DNS (53) NO está escuchando${NC}"
    fi
else
    echo -e "${RED}¡ALERTA! Contenedor dns_server NO está ejecutándose${NC}"
fi

echo ""

# Obtener la IP del servidor DNS
DNS_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' dns_server)
echo -e "IP del servidor DNS: ${DNS_IP}"

# Mostrar configuración DNS para varios contenedores
for container in "prod-postgres" "prod-app" "dev-app" "dev-mysql"; do
    show_dns_config ${container}
done

# Verificar conectividad directa con el servidor DNS usando ping a la IP
echo -e "${YELLOW}=== Verificando conectividad directa con el servidor DNS ===${NC}"
for container in "prod-postgres" "prod-app" "dev-app" "dev-mysql"; do
    echo -n "Ping de ${container} a servidor DNS (${DNS_IP}): "
    if docker exec ${container} ping -c 1 -W 1 ${DNS_IP} > /dev/null 2>&1; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FALLIDO${NC}"
    fi
done

echo -e "\n${YELLOW}=== Sugerencias para solucionar problemas DNS ===${NC}"
echo -e "1. Asegúrese de que el contenedor dns_server tenga la dirección IP estática 172.20.0.100"
echo -e "2. Verifique que todos los contenedores tengan 172.20.0.100 configurado como su servidor DNS"
echo -e "3. Confirme que las reglas de iptables permiten tráfico TCP/UDP al puerto 53 del servidor DNS"
echo -e "4. Si es necesario, actualice el archivo /etc/resolv.conf en cada contenedor para usar el DNS correcto"

echo -e "\n${YELLOW}=== ANÁLISIS FINALIZADO ===${NC}"