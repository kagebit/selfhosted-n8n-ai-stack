#!/bin/bash

# ============================================================
# selfhosted-n8n-ai-stack — Tailscale Funnel Configurator
# ============================================================
# Automates the SSL/TLS secure exposure of the n8n orchestrator
# ============================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "======================================================"
echo "  🔒 Tailscale Funnel — Configuración para n8n"
echo "======================================================"
echo -e "${NC}"

# 1. Comprobar si Tailscale está instalado
if ! command -v tailscale &> /dev/null; then
    echo -e "${RED}❌ Error: Tailscale no está instalado en el sistema.${NC}"
    echo -e "${YELLOW}Por favor, ejecuta ./install.sh primero para instalar las dependencias.${NC}"
    exit 1
fi

# 2. Comprobar si el servicio systemd está corriendo
if ! systemctl is-active --quiet tailscaled; then
    echo -e "${YELLOW}Iniciando el servicio de Tailscale...${NC}"
    sudo systemctl enable --now tailscaled
fi

# 3. Comprobar el estado de autenticación (Login)
echo -e "${BLUE}[1/3] Comprobando autenticación de Tailscale...${NC}"
if ! tailscale status &> /dev/null; then
    echo -e "${YELLOW}⚠️ Tailscale no está autenticado en tu cuenta.${NC}"
    echo -e "Por favor, ejecuta el siguiente comando para iniciar sesión:"
    echo -e "  ${GREEN}sudo tailscale up${NC}"
    echo -e "Abre el link en tu navegador, inicia sesión y vuelve a ejecutar este script."
    exit 0
fi
echo -e "${GREEN}✅ Autenticado correctamente.${NC}"

# 4. Configurar Funnel para el puerto 5678 (n8n)
echo -e "${BLUE}[2/3] Configurando Tailscale Funnel en el puerto 5678...${NC}"
# El comando --bg permite que se ejecute en el fondo (background) de manera persistente
if sudo tailscale funnel --bg 5678; then
    echo -e "${GREEN}✅ Funnel iniciado con éxito.${NC}"
    echo -e "${YELLOW}Provisionando certificado SSL de Let's Encrypt...${NC}"
    TS_DOMAIN=$(tailscale funnel status | grep -o 'https://[^ ]*' | head -n 1 | sed 's|https://||')
    if [ -n "$TS_DOMAIN" ]; then
        sudo tailscale cert "$TS_DOMAIN" || true
    fi
else
    echo -e "${RED}❌ Error al iniciar el Funnel. ¿Tienes activado HTTPS y Funnel en tu panel de control de Tailscale (login.tailscale.com/admin)?${NC}"
    exit 1
fi

# 5. Resumen y siguientes pasos
echo -e "${BLUE}[3/3] Resumen...${NC}"
echo ""
echo -e "${GREEN}======================================================"
echo "  🎉 Tailscale Funnel Expuesto Exitosamente"
echo "======================================================${NC}"
echo ""
echo -e "Tu n8n ahora es accesible desde internet mediante HTTPS seguro."
echo ""
echo -e "${YELLOW}▶️ COMPRUEBA TU URL OFICIAL EJECUTANDO:${NC}"
echo -e "  ${BLUE}tailscale funnel status${NC}"
echo ""
TS_URL=$(tailscale funnel status | grep -o 'https://[^ ]*' | head -n 1)
ENV_FILE="services/n8n/.env"

if [ -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}Actualizando automáticamente $ENV_FILE...${NC}"
    sed -i "s|^WEBHOOK_URL=.*|WEBHOOK_URL=$TS_URL|" "$ENV_FILE"
    sed -i "s|^WEBHOOK_TUNNEL_URL=.*|WEBHOOK_TUNNEL_URL=$TS_URL|" "$ENV_FILE"
    echo -e "${GREEN}✅ .env actualizado con $TS_URL${NC}"
    echo -e "${YELLOW}Reiniciando n8n para aplicar cambios...${NC}"
    DOCKER_CMD="docker-compose"
    if docker compose version &> /dev/null; then
        DOCKER_CMD="docker compose"
    fi
    (cd services/n8n && $DOCKER_CMD restart) || echo -e "${RED}⚠️ No se pudo reiniciar n8n automáticamente.${NC}"
else
    echo -e "${RED}⚠️ PASO FINAL OBLIGATORIO:${NC}"
    echo "No se encontró $ENV_FILE (¿has movido los archivos?)."
    echo "1. Edita manualmente tu archivo de variables de entorno de n8n."
    echo "2. Cambia WEBHOOK_URL y WEBHOOK_TUNNEL_URL por tu URL: $TS_URL"
    echo "3. Reinicia n8n."
fi
echo ""
