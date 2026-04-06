#!/bin/bash

# ============================================================
# selfhosted-n8n-ai-stack — macOS Deployment Script
# ============================================================

set -e

echo "Starting selfhosted-n8n-ai-stack macOS deployment..."
echo "====================================================="

if [ "$(uname -s)" != "Darwin" ]; then
    echo "Error: This script is intended for macOS devices only."
    exit 1
fi

# -----------------------------------------------------------
# 1. Dependency Resolution via Homebrew
# -----------------------------------------------------------
echo "[1/7] Resolving system dependencies via Homebrew..."

if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Set up brew in PATH for the current session
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    echo "Homebrew is already installed."
    brew update
fi

brew install curl git

# -----------------------------------------------------------
# 2. Docker & Docker Compose Verification
# -----------------------------------------------------------
echo "[2/7] Verifying container execution environment..."

if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing Docker via Homebrew Cask..."
    brew install --cask docker
    echo "Please start Docker Desktop manually from your Applications folder."
    echo "Wait for the Docker engine to start, then re-run this script."
    exit 0
fi

# In macOS Docker Desktop, docker-compose is included by default.

# -----------------------------------------------------------
# 3. Tailscale Installation
# -----------------------------------------------------------
echo "[3/7] Verifying Tailscale installation..."

if ! command -v tailscale &> /dev/null && [ ! -d "/Applications/Tailscale.app" ]; then
    echo "Tailscale not found. Installing via Homebrew Cask..."
    brew install --cask tailscale
    echo "Tailscale installed. Please open it from Applications and authenticate."
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
    fi
done

echo ""
echo "CRITICAL: The deployed .env files utilize placeholder credentials."
read -p "Have you manually edited the .env files securely? (y/n): " ENV_READY
if [[ "$ENV_READY" != "y" && "$ENV_READY" != "Y" ]]; then
    echo "Execution halted to allow variable configuration. Execute this script again afterward."
    exit 0
fi

DOCKER_CMD="docker-compose"
if docker compose version &> /dev/null; then
  DOCKER_CMD="docker compose"
fi

# -----------------------------------------------------------
# 6. Service Deployment
# -----------------------------------------------------------
echo "[6/7] Initializing container orchestration..."

echo "Starting Postgres RAG persistence layer..."
cd services/postgres-rag && $DOCKER_CMD up -d && cd ../..

echo "Starting Postgres Vector persistence layer..."
cd services/postgres-vector && $DOCKER_CMD up -d && cd ../..

echo "Starting Qdrant vector store..."
cd services/qdrant && $DOCKER_CMD up -d && cd ../..

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
cd services/whisper && $DOCKER_CMD up -d --build && cd ../..

echo "Starting LocalAI embeddings service (Build may take several minutes)..."
cd services/embeddings && $DOCKER_CMD up -d --build && cd ../..

echo "Starting n8n orchestrator..."
mkdir -p services/n8n/n8n-data
cd services/n8n && $DOCKER_CMD up -d && cd ../..

echo "Starting NocoDB visualization toolkit..."
cd services/nocodb && $DOCKER_CMD up -d && cd ../..

echo "Starting Portainer administrative interface..."
cd services/portainer && $DOCKER_CMD up -d && cd ../..

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
