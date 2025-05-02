#!/usr/bin/env python3
"""
Script que actúa como proxy entre SFTP y FTP
Sincroniza periódicamente los archivos desde el servidor FTP anónimo
hacia el directorio de acceso SFTP seguro
"""

import os
import sys
import time
import subprocess
import logging
from datetime import datetime

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger('ftp-proxy')

# Configuración
FTP_SERVER = "172.40.0.10"
FTP_PORT = "21"
SFTP_DIR = "/home/sftpuser/docs"
INTERVAL = 300  # 5 minutos entre sincronizaciones

def sync_ftp_to_sftp():
    """Sincroniza los archivos desde el servidor FTP anónimo hacia el directorio SFTP"""
    logger.info("Iniciando sincronización FTP -> SFTP")
    
    # Verificar si el servidor FTP está accesible con más tiempo de espera y más intentos
    retry_count = 0
    max_retries = 3
    
    while retry_count < max_retries:
        try:
            logger.info(f"Intento {retry_count+1}/{max_retries} de conectar a {FTP_SERVER}:{FTP_PORT}")
            
            # Primero comprobamos con ping que hay conectividad a nivel de red
            ping_result = subprocess.run(
                ["ping", "-c", "1", "-w", "5", FTP_SERVER],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            logger.info(f"Resultado de ping: {ping_result.returncode}")
            logger.info(f"Ping output: {ping_result.stdout}")
            
            # Ahora comprobamos el puerto FTP
            result = subprocess.run(
                ["nc", "-z", "-v", "-w", "10", FTP_SERVER, FTP_PORT],
                stdout=subprocess.PIPE, 
                stderr=subprocess.PIPE,
                text=True
            )
            
            logger.info(f"Servidor FTP en {FTP_SERVER}:{FTP_PORT} accesible")
            break  # Si llegamos aquí, la conexión fue exitosa
            
        except subprocess.CalledProcessError as e:
            retry_count += 1
            logger.warning(f"Intento {retry_count}/{max_retries} fallido: {str(e)}")
            logger.warning(f"STDERR: {e.stderr if hasattr(e, 'stderr') else 'N/A'}")
            
            if retry_count >= max_retries:
                logger.error(f"No se puede conectar al servidor FTP en {FTP_SERVER}:{FTP_PORT} después de {max_retries} intentos")
                return
            
            # Esperar antes de reintentar
            time.sleep(5)
    
    # Primero, intentemos listar el directorio raíz del FTP para ver qué hay disponible
    logger.info("Verificando contenido del servidor FTP...")
    try:
        list_cmd = ["lftp", "-c", f"open -u anonymous, ftp://{FTP_SERVER}; ls -la"]
        logger.info(f"Ejecutando: {' '.join(list_cmd)}")
        
        list_result = subprocess.run(
            list_cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=30
        )
        
        logger.info(f"Salida del comando ls: {list_result.stdout}")
        if list_result.stderr:
            logger.warning(f"Errores del comando ls: {list_result.stderr}")
    
    except subprocess.TimeoutExpired:
        logger.error("Tiempo de espera agotado al listar el directorio FTP")
    except Exception as e:
        logger.error(f"Error al listar el directorio FTP: {str(e)}")
    
    # Intentemos sincronizar cada directorio SW individualmente
    for sw_num in range(1, 6):
        sw_dir = f"SW{sw_num}"
        
        # Asegurar que el directorio existe
        os.makedirs(f"{SFTP_DIR}/{sw_dir}", exist_ok=True)
        
        # Comando para sincronizar usando lftp con opciones más seguras y timeout
        cmd = [
            "lftp", 
            "-c", 
            f"set net:timeout 10; set net:max-retries 3; open -u anonymous, ftp://{FTP_SERVER}; " \
            f"set ftp:passive-mode true; " \
            f"set net:reconnect-interval-base 5; " \
            f"mirror --delete --verbose --use-cache --allow-suid --allow-chown --script=- {sw_dir} {SFTP_DIR}/{sw_dir}"
        ]
        
        try:
            logger.info(f"Sincronizando {sw_dir}...")
            logger.info(f"Comando: {' '.join(cmd)}")
            
            # Usar un timeout más largo para el comando mirror
            result = subprocess.run(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                timeout=60  # 60 segundos de timeout
            )
            
            logger.info(f"Sincronización de {sw_dir} completada")
            logger.info(f"STDOUT: {result.stdout}")
            
            if result.stderr:
                logger.warning(f"STDERR: {result.stderr}")
            
            # Corregir permisos
            subprocess.run(
                ["chown", "-R", "sftpuser:sftpuser", f"{SFTP_DIR}/{sw_dir}"],
                check=True
            )
            subprocess.run(
                ["chmod", "-R", "755", f"{SFTP_DIR}/{sw_dir}"],
                check=True
            )
            
        except subprocess.TimeoutExpired:
            logger.error(f"Tiempo de espera agotado al sincronizar {sw_dir}")
        except subprocess.CalledProcessError as e:
            logger.error(f"Error al sincronizar {sw_dir}: {e}")
            logger.error(f"STDOUT: {e.stdout if hasattr(e, 'stdout') else 'N/A'}")
            logger.error(f"STDERR: {e.stderr if hasattr(e, 'stderr') else 'N/A'}")
        except Exception as e:
            logger.error(f"Error inesperado al sincronizar {sw_dir}: {str(e)}")
        
        # Añadir un pequeño retraso entre directorios para evitar sobrecarga
        time.sleep(2)
    
    for sw_num in range(1, 6):
        sw_dir = f"SW{sw_num}"
        
        # Asegurar que el directorio existe
        os.makedirs(f"{SFTP_DIR}/{sw_dir}", exist_ok=True)
        
        # Comando para sincronizar usando lftp
        cmd = [
            "lftp", 
            "-c", 
            f"open -u anonymous, ftp://{FTP_SERVER}; " \
            f"mirror --delete --verbose {sw_dir} {SFTP_DIR}/{sw_dir}"
        ]
        
        try:
            logger.info(f"Sincronizando {sw_dir}...")
            result = subprocess.run(
                cmd,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            logger.info(f"Sincronización de {sw_dir} completada")
            
            # Corregir permisos
            subprocess.run(
                ["chown", "-R", "sftpuser:sftpuser", f"{SFTP_DIR}/{sw_dir}"],
                check=True
            )
            subprocess.run(
                ["chmod", "-R", "755", f"{SFTP_DIR}/{sw_dir}"],
                check=True
            )
            
        except subprocess.CalledProcessError as e:
            logger.error(f"Error al sincronizar {sw_dir}: {e}")
            logger.error(f"STDOUT: {e.stdout}")
            logger.error(f"STDERR: {e.stderr}")

def main():
    """Función principal"""
    logger.info("Iniciando servicio de proxy FTP-SFTP")
    
    while True:
        try:
            sync_ftp_to_sftp()
            logger.info(f"Próxima sincronización en {INTERVAL} segundos")
            time.sleep(INTERVAL)
        except Exception as e:
            logger.error(f"Error inesperado: {e}")
            time.sleep(60)  # Esperar 1 minuto en caso de error

if __name__ == "__main__":
    main()