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

ping:
	docker exec -it dev-apache ping -c 2 prod-postgres
	docker exec -it prod-app ping -c 2 dev-app
	docker exec -it dev-apache traceroute prod-postgres

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

copia:
	docker exec dns_server /backup.sh