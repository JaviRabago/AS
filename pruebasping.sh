#!/bin/bash

# Colores para mejor visualización
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para probar ping y mostrar resultado
test_ping() {
    local source=$1
    local target=$2
    local description=$3
    
    echo -e "${YELLOW}Probando ${description}: ${source} -> ${target}${NC}"
    
    # Ejecutar el comando ping dentro del contenedor origen
    if docker exec ${source} ping -c 2 -W 2 ${target} > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Conexión EXITOSA: ${source} puede alcanzar a ${target}${NC}"
        return 0
    else
        echo -e "${RED}✗ Conexión FALLIDA: ${source} NO puede alcanzar a ${target}${NC}"
        return 1
    fi
}

echo -e "${YELLOW}=== INICIANDO PRUEBAS DE CONECTIVIDAD ===${NC}"
echo ""

# Lista de contenedores a probar
PRODUCTION_CONTAINERS=("prod-app" "prod-nginx" "prod-postgres")
DEVELOPMENT_CONTAINERS=("dev-app" "dev-apache" "dev-mysql")
SERVICE_CONTAINERS=("dns_server")
# Añadir router y openvpn si son necesarios en las pruebas
OTHER_CONTAINERS=("router" "openvpn")

echo -e "${YELLOW}=== Prueba 1: Conectividad de Service a Development (Debería funcionar) ===${NC}"
for service in "${SERVICE_CONTAINERS[@]}"; do
    for dev in "${DEVELOPMENT_CONTAINERS[@]}"; do
        test_ping $service $dev "Service -> Development"
    done
done
echo ""

echo -e "${YELLOW}=== Prueba 2: Conectividad de Production a Service (NO debería funcionar) ===${NC}"
for prod in "${PRODUCTION_CONTAINERS[@]}"; do
    for service in "${SERVICE_CONTAINERS[@]}"; do
        test_ping $prod $service "Production -> Service"
    done
done
echo ""

echo -e "${YELLOW}=== Prueba 3: Conectividad de Production a Development (NO debería funcionar) ===${NC}"
for prod in "${PRODUCTION_CONTAINERS[@]}"; do
    for dev in "${DEVELOPMENT_CONTAINERS[@]}"; do
        test_ping $prod $dev "Production -> Development"
    done
done
echo ""

echo -e "${YELLOW}=== Prueba 4: Excepción - PostgreSQL a NAS/DNS (Debería funcionar) ===${NC}"
test_ping "prod-postgres" "dns_server" "Excepción PostgreSQL -> NAS/DNS"
echo ""

echo -e "${YELLOW}=== Prueba 5: Conectividad de Development a Service (Debería funcionar) ===${NC}"
for dev in "${DEVELOPMENT_CONTAINERS[@]}"; do
    for service in "${SERVICE_CONTAINERS[@]}"; do
        test_ping $dev $service "Development -> Service"
    done
done
echo ""

echo -e "${YELLOW}=== Prueba 6: Conectividad al Router (Debería funcionar para todos) ===${NC}"
ALL_CONTAINERS=(${PRODUCTION_CONTAINERS[@]} ${DEVELOPMENT_CONTAINERS[@]} ${SERVICE_CONTAINERS[@]})
for container in "${ALL_CONTAINERS[@]}"; do
    test_ping $container "router" "Acceso al Router"
done
echo ""

# Prueba de conectividad a Internet (usando el DNS de Google como referencia)
echo -e "${YELLOW}=== Prueba 7: Conectividad a Internet (No debe funcionar) ===${NC}"
for container in "${ALL_CONTAINERS[@]}"; do
    echo -e "${YELLOW}Probando acceso a Internet desde: ${container}${NC}"
    if docker exec ${container} ping -c 2 -W 2 8.8.8.8 > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Conexión EXITOSA: ${container} puede acceder a Internet${NC}"
    else
        echo -e "${RED}✗ Conexión FALLIDA: ${container} NO puede acceder a Internet${NC}"
    fi
done
echo ""


echo -e "\n${YELLOW}=== PRUEBAS FINALIZADAS ===${NC}"