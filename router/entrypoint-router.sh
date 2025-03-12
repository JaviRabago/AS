#!/bin/bash

echo 'Router interfaces:'
ip addr

echo 'Setting up routing between networks...'
iptables -t nat -A POSTROUTING -s 172.30.0.0/24 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 172.40.0.0/24 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 172.20.0.0/24 -j MASQUERADE
iptables -A FORWARD -i eth0 -o eth1 -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -j ACCEPT

echo 'IP forwarding status:'
cat /proc/sys/net/ipv4/ip_forward

echo 'Iptables rules:'
iptables -L -v -n

echo 'NAT rules:'
iptables -t nat -L -v -n

tail -f /dev/null
