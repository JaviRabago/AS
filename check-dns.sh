#!/bin/bash
# Guardar este script como check-dns.sh y ejecutarlo para verificar el DNS

echo "=== Verificando estado de los contenedores ==="
docker ps 

echo -e "\n=== Logs del servidor DNS ==="
docker logs dns-server | tail -20

echo -e "\n=== Verificación de configuración DNS en prod_container ==="
docker exec prod_container cat /etc/resolv.conf
docker exec prod_container dig +short dev-container.service @172.20.0.100

echo -e "\n=== Verificación de configuración DNS en dev_container ==="
docker exec dev_container cat /etc/resolv.conf
docker exec dev_container dig +short prod-container.service @172.20.0.100

echo -e "\n=== Prueba de ping entre contenedores por IP ==="
docker exec prod_container ping -c 1 172.40.0.3
docker exec dev_container ping -c 1 172.30.0.3

echo -e "\n=== Prueba de ping entre contenedores por nombre ==="
docker exec prod_container ping -c 1 dev-container.service
docker exec dev_container ping -c 1 prod-container.service