# Administración de Servidores

Este documento describe la configuración de los diferentes servicios utilizados en el entorno, las redes y los volúmenes asociados.

---

## **docker-compose.yml**

### **Servicios**

#### **Router**
- **Build:** `./router`
- **Nombre del contenedor:** `router`
- **Redes:**
  - Producción: `172.30.0.150`
  - Desarrollo: `172.40.0.150`
  - Servicio: `172.20.0.150`
  - VPN: `172.10.0.150`
- **Puertos:**
  - `80:80`
  - `8080:8080`
  - `1194:1194/udp`
- **Configuraciones:**
  - Capacidad adicional: `NET_ADMIN`
  - Sysctl: `net.ipv4.ip_forward=1`
  - Reinicio: `unless-stopped`
- **Dependencias:** `dns_server`, `app-prod`, `nginx`, `postgres`, `app-dev`, `mysql`, `apache`

#### **Aplicación en Producción (app-prod)**
- **Build Context:** `.`
- **Dockerfile:** `Dockerfile.prod`
- **Nombre del contenedor:** `prod-app`
- **Entorno:** Producción
  - Variables de entorno: `NODE_ENV`, `PORT=3000`, `DB_HOST`, etc.
- **Red:** Producción
- **Volúmenes:**
  - `./app/app-prod-wrapper.sh:/app-wrapper.sh`
  - `./app/supervisord.conf:/etc/supervisord.conf`
- **Salud:** Dependencia con `postgres` mediante condición `healthy`.

#### **Nginx**
- **Build Context:** `./nginx`
- **Dockerfile:** `Dockerfile.nginx`
- **Nombre del contenedor:** `prod-nginx`
- **Red:** Producción
- **Volúmenes:**
  - Configuraciones de producción
  - Archivos de inicialización

#### **PostgreSQL**
- **Imagen:** `postgres:14-alpine`
- **Nombre del contenedor:** `prod-postgres`
- **Variables de entorno:** Configuración para conexión
- **Volúmenes:**
  - `postgres_data:/var/lib/postgresql/data`
  - Scripts personalizados
- **Salud:** `pg_isready -U john`

#### **Aplicación en Desarrollo (app-dev)**
- **Build Context:** `.`
- **Dockerfile:** `Dockerfile.dev`
- **Red:** Desarrollo
- **Volúmenes:** Código fuente, `node_modules`, scripts de inicialización.

#### **MySQL (Desarrollo)**
- **Build Context:** `./mysql`
- **Dockerfile:** `Dockerfile.mysql`
- **Nombre del contenedor:** `dev-mysql`
- **Volumen:** `mysql_data`

#### **Apache**
- **Configuración de Apache con supervisores**
- Archivos principales y directorios configurados.

#### **DNS + NAS**
- **Build:** `./dns_debian`
- **Red:** Servicio (`172.20.0.100`)

#### **VPN**
- **Imagen:** `kylemanna/openvpn`
- **Red:** VPN (`172.10.0.3`)

---

##  OpenVPN

### **Descripción y Funcionalidad**

El script configura un servidor OpenVPN y gestiona su entorno. A continuación, se describe su funcionalidad:

1. **Ruta predeterminada:**
   - Se elimina la ruta actual del sistema.
   - Se configura `172.10.0.150` como nueva puerta de enlace predeterminada.

2. **Inicialización del servidor:**
   - Configura OpenVPN, genera claves y certificados iniciales, y define rutas específicas para redes internas (`development`, `production`, `service`).

3. **Directorio de configuración de cliente (`ccd`):**
   - Permite asignar reglas específicas para cada cliente.
   - Se añaden rutas personalizadas basadas en los privilegios de cada usuario.

4. **Gestión de usuarios:**
   - Crea certificados y configuraciones `.ovpn`:
     - `dev_user`: Acceso solo a `development`.
     - `svc_prod_user`: Acceso a redes de producción y servicio.

5. **Confirmación de configuraciones:**
   - Lista reglas generadas para cada usuario y sus rutas específicas.

6. **Inicio de OpenVPN:**
   - Ejecuta el servidor utilizando `ovpn_run`.

## **Apache**

### **Descripción**

Apache es utilizado como servidor HTTP y está configurado con varios archivos esenciales, divididos en `Dockerfile`, configuraciones (`.conf`) y scripts (`.sh`).

---

### **Dockerfile**

El archivo `Dockerfile.apache` define la imagen y configuración básica para el contenedor Apache. Principales características:

- **Dependencias instaladas:** OpenSSH, iproute2, supervisor, procps, curl y net-tools.

- **Configuración SSH:**
  - Se habilita el acceso SSH con inicio de sesión permitido para el usuario root y un usuario adicional `john`.

- **Directorios creados:**
  - `/var/run/sshd`, `/etc/supervisor.d`, `/var/log/apache`, `/var/log/supervisor`.

- **Modificaciones en Apache:**
  - Verificación de módulos disponibles.
  - Permisos en configuraciones esenciales.

- **Puertos expuestos:** `22` para SSH y `80` para Apache.

- **Script de arranque:** `start-services.sh` utilizado para iniciar Apache y otros servicios dependientes.

---

### **Archivos de configuración (`.conf`)**

#### **httpd.conf**
Configuración principal de Apache:
- **Módulos habilitados:** `proxy`, `proxy_http`, `headers`, entre otros.
- **DocumentRoot** y permisos de acceso configurados.
- **Logs de errores** y registros almacenados en `/proc/self/fd/`.
- Incluye configuraciones adicionales de Virtual Hosts.

---

#### **dev.conf**
Configuración de Virtual Host para entorno de desarrollo:
- Proxy habilitado para redirigir tráfico a `http://app-dev:3000/`.
- Logs personalizados para errores y tráfico estándar.

---

#### **supervisord.conf**
Configuración para supervisores:
- **[supervisord]:** Permite ejecución en segundo plano con logs específicos.
- **[program:sshd]:** Configura el servicio SSHD.
- **[program:configure_network]:** Configura redes mediante `apache-wrapper.sh`.
- **[program:apache]:** Permite el arranque de Apache con prioridad sobre otros servicios.

---

#### **apache-ssh-supervisor.conf**
Configuración específica para supervisar servicios como SSH, redes y Apache:
- Servicios independientes configurados con logs personalizados.

---

## **Scripts (`.sh`)**

### **apache-wrapper.sh**
- Script encargado de configurar variables de entorno y preparar redes para Apache.

---

### **start-services.sh**
- Automatiza el inicio de servicios dependientes, incluyendo supervisores y configuraciones adicionales para garantizar el correcto funcionamiento del contenedor.
