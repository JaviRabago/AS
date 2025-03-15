#!/bin/bash

# Configurar 172.40.0.2 como ruta predeterminada para todo el tráfico
ip route del default
ip route add default via 172.40.0.2

# Mantener el contenedor ejecutándose
tail -f /dev/null