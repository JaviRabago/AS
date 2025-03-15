up:
	docker compose up -d --build

upnocache:
	docker compose build --no-cache
	docker compose up -d

down:
	docker compose down --volumes --remove-orphans
	docker network prune -f
	docker volume prune -f

restart:
	docker compose down
	docker compose up -d --build

logdns:
	docker logs dns_server

pruebas:
	docker exec -it dns_server cat /etc/dnsmasq.hosts
	docker exec -it dns_server nslookup prod_container
	docker exec -it prod_container ping dev_container

dnsbash:
	docker exec -it dns_server /bin/bash

testcontainer:
	docker run -d \
  --name test_container \
  --network aspruebas_development \
  --dns 172.40.0.2 \
  --label dns_hostname=test_container \
  --cap-add NET_ADMIN \
  alpine sleep infinity

testcontainerdown:
	docker rm -f test_container

tcp:
	docker exec -it router tcpdump -i eth0 -n