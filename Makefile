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

logmysql:
	docker logs dev-mysql

ping:
	./pruebasping.sh

dns:
	./pruebadns.sh

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

tcp:
	docker exec -it router tcpdump -i eth0 -n

copia:
	docker exec dns_server /backup.sh

restmysql:
	docker exec dns_server /restoremysql.sh

restpostgres:
	docker exec dns_server /restorepostgres.sh

extraer:
	docker exec -it openvpn bash -c "ovpn_getclient dev_user > /etc/openvpn/clients/dev_user.ovpn"
	docker exec -it openvpn bash -c "ovpn_getclient svc_prod_user > /etc/openvpn/clients/svc_prod_user.ovpn"
	docker cp openvpn:/etc/openvpn/clients/dev_user.ovpn ./dev_user.ovpn
	docker cp openvpn:/etc/openvpn/clients/svc_prod_user.ovpn ./svc_prod_user.ovpn

condev:
	sudo openvpn --config dev_user.ovpn

conprod:
	sudo openvpn --config svc_prod_user.ovpn

conmysql:
	mysql -h 172.40.0.2 -u john -pmysql tasksdb

conpostgres:
	psql -h 172.30.0.2 -U john -d tasksdb -W

push:
	git add .
	git commit -m "usuario john en router + openvpn mejorado"
	git push

borrarhosts:
	ssh-keygen -f '/home/javi/.ssh/known_hosts' -R '172.40.0.5'
