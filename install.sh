#!/bin/bash

# ============================================================
# selfhosted-n8n-ai-stack — Deployment Script
# ============================================================

set -e

echo "Starting selfhosted-n8n-ai-stack deployment..."
echo "====================================================="

# Require root privileges for system package installation
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or using sudo"
  exit 1
fi

# -----------------------------------------------------------
# 1. OS Detection and Dependency Resolution
# -----------------------------------------------------------
echo "[1/7] Resolving system dependencies..."

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION_ID=$VERSION_ID
else
    echo "Error: Operating system cannot be reliably determined. Proceeding with caution."
    OS="unknown"
fi

install_dependencies_apt() {
    apt-get update -y
    apt-get install -y curl git apt-transport-https ca-certificates gnupg lsb-release
}

install_dependencies_dnf() {
    dnf check-update || true
    dnf install -y curl git dnf-plugins-core
}

install_dependencies_pacman() {
    pacman -Sy --noconfirm
    pacman -S --noconfirm curl git
}

case $OS in
    ubuntu|debian|linuxmint)
        echo "Detected Debian/Ubuntu-based OS."
        install_dependencies_apt
        ;;
    fedora|centos|rhel)
        echo "Detected Fedora/RHEL-based OS."
        install_dependencies_dnf
        ;;
    arch|manjaro)
        echo "Detected Arch-based OS."
        install_dependencies_pacman
        ;;
    *)
        echo "Unsupported OS or unable to resolve package manager. Ensure curl and git are installed manually."
        ;;
esac

# -----------------------------------------------------------
# 2. Docker & Docker Compose Verification
# -----------------------------------------------------------
echo "[2/7] Verifying container execution environment..."

if ! command -v docker &> /dev/null; then
    echo "Docker not found. Deploying Docker environment..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl enable --now docker
    rm get-docker.sh
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "Docker Compose plugin not found. Installing..."
    case $OS in
        ubuntu|debian|linuxmint)
            apt-get install -y docker-compose-plugin
            ;;
        fedora|centos|rhel)
            dnf install -y docker-compose-plugin
            ;;
        arch|manjaro)
            pacman -S --noconfirm docker-compose
            ;;
    esac
fi

# -----------------------------------------------------------
# 3. Tailscale Installation
# -----------------------------------------------------------
echo "[3/7] Verifying Tailscale installation..."

if ! command -v tailscale &> /dev/null; then
    echo "Tailscale not found. Deploying..."
    curl -fsSL https://tailscale.com/install.sh | sh
    echo "Tailscale installed successfully. Run 'sudo tailscale up' later to authenticate."
fi

# Fix for WSL DNS compatibility with Tailscale
if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
    echo "WSL detected. Applying Tailscale DNS compatibility fix..."
    if [ ! -f "/etc/wsl.conf" ] || ! grep -q "generateResolvConf = false" /etc/wsl.conf; then
        echo -e "\n[network]\ngenerateResolvConf = false" >> /etc/wsl.conf
        rm -f /etc/resolv.conf
        echo "nameserver 8.8.8.8" > /etc/resolv.conf
        echo "WSL DNS configuration updated to prevent conflicts with Tailscale."
    fi
fi

# -----------------------------------------------------------
# 4. Network Provisioning
# -----------------------------------------------------------
echo "[4/7] Provisioning Docker networks..."

docker network create n8n-net 2>/dev/null || echo "Network 'n8n-net' already allocated."
docker network create db 2>/dev/null || echo "Network 'db' already allocated."

# -----------------------------------------------------------
# 5. Environment Configuration
# -----------------------------------------------------------
echo "[5/7] Establishing environment variables..."

SERVICES_WITH_ENV=("n8n" "postgres-rag" "postgres-vector")

for SERVICE in "${SERVICES_WITH_ENV[@]}"; do
    if [ ! -f "services/$SERVICE/.env" ]; then
        cp "services/$SERVICE/.env.example" "services/$SERVICE/.env"
        echo "Created template variable file at services/$SERVICE/.env"
        # Chown back to the caller if running as root via sudo
        if [ -n "$SUDO_USER" ]; then
            chown "$SUDO_USER" "services/$SERVICE/.env"
        fi
    fi
done

echo ""
echo "CRITICAL: The deployed .env files utilize placeholder credentials."
read -p "Have you manually edited the .env files securely? (y/n): " ENV_READY
if [[ "$ENV_READY" != "y" && "$ENV_READY" != "Y" ]]; then
    echo "Execution halted to allow variable configuration. Execute this script again afterward."
    exit 0
fi

# Drop privileges if running via sudo to start processes as user
DOCKER_CMD="docker-compose"
if docker compose version &> /dev/null; then
  DOCKER_CMD="docker compose"
fi

if [ -n "$SUDO_USER" ] && groups "$SUDO_USER" | grep -q '\bdocker\b'; then
    RUN_AS="sudo -u $SUDO_USER"
else
    RUN_AS=""
fi

# -----------------------------------------------------------
# 6. Service Deployment
# -----------------------------------------------------------
echo "[6/7] Initializing container orchestration..."

echo "Starting Postgres RAG persistence layer..."
cd services/postgres-rag && $RUN_AS $DOCKER_CMD up -d && cd ../..

echo "Starting Postgres Vector persistence layer..."
cd services/postgres-vector && $RUN_AS $DOCKER_CMD up -d && cd ../..

echo "Starting Qdrant vector store..."
cd services/qdrant && $RUN_AS $DOCKER_CMD up -d && cd ../..

echo "Waiting for PostgreSQL containers to be ready..."
for CONTAINER in Postgres_RAG Postgres_Vector; do
    RETRIES=0
    until docker exec "$CONTAINER" pg_isready -q 2>/dev/null; do
        RETRIES=$((RETRIES + 1))
        if [ "$RETRIES" -ge 30 ]; then
            echo "Warning: $CONTAINER did not become ready within 60 seconds. Proceeding anyway."
            break
        fi
        sleep 2
    done
    echo "$CONTAINER is ready."
done

echo "Starting Whisper API transcription service (Build may take several minutes)..."
cd services/whisper && $RUN_AS $DOCKER_CMD up -d --build && cd ../..

echo "Starting LocalAI embeddings service (Build may take several minutes)..."
cd services/embeddings && $RUN_AS $DOCKER_CMD up -d --build && cd ../..

echo "Starting n8n orchestrator..."
mkdir -p services/n8n/n8n-data
chown -R 1000:1000 services/n8n/n8n-data
cd services/n8n && $RUN_AS $DOCKER_CMD up -d && cd ../..

echo "Starting NocoDB visualization toolkit..."
cd services/nocodb && $RUN_AS $DOCKER_CMD up -d && cd ../..

echo "Starting Portainer administrative interface..."
cd services/portainer && $RUN_AS $DOCKER_CMD up -d && cd ../..

# -----------------------------------------------------------
# 7. Post-Deployment Extensions
# -----------------------------------------------------------
echo "[7/7] Executing post-deployment extension initialization..."

source services/postgres-vector/.env
if docker exec Postgres_Vector psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE EXTENSION IF NOT EXISTS vector;" 2>/dev/null; then
    echo "pgvector extension activated successfully."
else
    echo "Warning: Automated activation of pgvector failed. Proceed with manual execution:"
    echo "  docker exec -it Postgres_Vector psql -U <user> -d <db> -c \"CREATE EXTENSION IF NOT EXISTS vector;\""
fi

echo ""
echo "====================================================="
echo "Deployment successful."
echo "====================================================="
echo ""
echo "Service Endpoints:"
echo "  n8n              -> http://localhost:5678"
echo "  NocoDB           -> http://localhost:9093"
echo "  Portainer        -> http://localhost:9000"
echo "  Whisper API      -> http://localhost:5001"
echo "  LocalAI          -> http://localhost:8081"
echo "  Qdrant           -> http://localhost:6333"
echo "  Postgres RAG     -> localhost:5434"
echo "  Postgres Vector  -> localhost:5433"
echo ""
echo "Routine operational instructions and Tailscale Funnel setup can be found in docs/tailscale-setup.md."
