*🌍 Read this in [Spanish (Español)](README_ES.md)*

# selfhosted-n8n-ai-stack

Self-hosted AI automation stack orchestrated via Docker and isolated internal networks.

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![n8n](https://img.shields.io/badge/n8n-Automation-FA6800?logo=n8n&logoColor=white)](https://n8n.io/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Vector_RAG-336791?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Tailscale](https://img.shields.io/badge/Tailscale-Funnel_Secure-black?logo=tailscale&logoColor=white)](https://tailscale.com/)

---

## Features

- **Local AI Workflows**: Complete n8n automation paired with local embeddings. Full LLMs can also run locally without external API costs if your hardware has the capacity. You can verify what AI models your device supports at [canirun.ai](https://canirun.ai/).
- **RAG & Vector Search**: Integrated PostgreSQL with pgvector and Qdrant for high-performance semantic search.
- **Secure Integration**: Built-in Tailscale Funnel script for secure public HTTPS endpoints (ideal for webhook ingestion like Telegram).
- **Resource Efficiency**: Uses lightweight model combinations (`small` Whisper and `all-MiniLM-L6-v2`) suitable for modest hardware.
- **Visual Data Management**: Centralized database visibility via NocoDB.
- **Secure Networking**: Isolated inner Docker networks ensure restricted communication among core components.

## Agent Example

![n8n Agent Workflow](src/images/n8n_agent_flow.gif)

## Prerequisites

The stack requires a Linux-based host environment. The automated installation script is compatible with Debian, Ubuntu, Fedora, CentOS, and Arch Linux.

| Requirement | 🔹 Minimum | 🔹 Recommended |
| :--- | :--- | :--- |
| **CPU** | 3 cores | 6–8 cores |
| **RAM** | 4 GB | 16 GB or more |
| **Storage** | 50 GB (SSD recommended) | SSD NVMe |
| **GPU** | Not required | Compatible (Local AI/Whisper) |
| **System** | Windows 10+, macOS 12+, Linux | Linux or MacOS |
| **Note** | *With 4 GB, Whisper may be tight.* | *Ideal for smooth usage.* |

> 🪟 **Windows Users**: You can deploy this stack natively using the **Windows Subsystem for Linux (WSL)**. We highly recommend installing a **Debian** WSL distribution rather than Ubuntu, as Debian consumes considerably fewer background CPU and RAM resources, making it ideal for a persistent AI stack.
> To install Debian on Windows WSL, run: `wsl --install -d Debian` (See [official Debian WSL guide](https://wiki.debian.org/InstallingDebianOn/Microsoft/Windows/SubsystemForLinux) for details).

## Installation

### 1. Automated Setup

Clone the repository and run the setup script. The script resolves dependencies, configures internal Docker networks, templates environment variables, and orchestrates the deployment.

#### For Linux Distributions

```bash
git clone https://github.com/Hamza-Cloud-DevOPS/selfhosted-n8n-ai-stack.git
cd selfhosted-n8n-ai-stack
chmod +x install.sh
sudo ./install.sh
```

#### For macOS Devices

```bash
git clone https://github.com/Hamza-Cloud-DevOPS/selfhosted-n8n-ai-stack.git
cd selfhosted-n8n-ai-stack
chmod +x mac_install.sh
./mac_install.sh
```

During the execution, the script will pause to allow manual configuration of the `.env` credentials in `services/n8n/`, `services/postgres-rag/`, and `services/postgres-vector/`.

### 2. Tailscale Funnel Configuration (Recommended)

For integrations that require valid HTTPS endpoints (e.g., Telegram Webhooks), you must configure Tailscale Funnel. Run the automated configurator from the repository root:

```bash
chmod +x tailscale_config.sh
sudo ./tailscale_config.sh
```

This script verifies your Tailscale authentication, exposes n8n via HTTPS on port 5678, and automatically updates your `.env` with the correct webhook URLs. For manual step-by-step instructions, refer to [docs/tailscale-setup.md](docs/tailscale-setup.md).

## Usage

Once installed, the entire orchestration layer starts automatically. You can access the services, observe the structural topology, and begin creating workflows.

### Accessing the Interfaces

- **n8n**: `http://localhost:5678` (Workflow Orchestrator)
- **LocalAI**: `http://localhost:8081` (Native GUI to download/manage models)
- **NocoDB**: `http://localhost:9093` (Relational & vector PostgreSQL visualization)
- **Portainer**: `http://localhost:9000` (Lightweight container/log management)

### Local API Service Endpoints (Internal Docker Network)

- **PostgreSQL RAG**: `postgres-rag:5434`
- **PostgreSQL Vector**: `postgres-vector:5433` (Requires `CREATE EXTENSION IF NOT EXISTS vector;`)
- **Qdrant**: `qdrant:6333`
- **Whisper**: `whisper:5001` (Speech-to-Text inference wrapper)
- **LocalAI**: `localai:8081` (Local LLMs and embeddings)

### Architecture Topology

For a detailed diagram of the Docker network topology and inter-service connectivity, see → [docs/network-architecture_EN.md](docs/network-architecture_EN.md)

### Node Configuration

Included in `n8n-nodes/` is a predefined **HTTP Request** node template pointing to the local Whisper API endpoint. To use it in a workflow:
1. Open an n8n workflow.
2. Select **Import from file**.
3. Point to `n8n-nodes/http-request-whisper.json`.

## Acknowledgments

This architecture uses and wraps the following third-party technologies:

| Component | Source | License |
|----------|-------------|----------|
| n8n | [github.com/n8n-io/n8n](https://github.com/n8n-io/n8n) | Sustainable Use / Apache 2.0 |
| Whisper | [github.com/openai/whisper](https://github.com/openai/whisper) | MIT |
| Local Whisper | [github.com/jaypetersdotdev/local-whisper](https://github.com/jaypetersdotdev/local-whisper) | MIT |
| LocalAI | [github.com/mudler/LocalAI](https://github.com/mudler/LocalAI) | MIT |
| NocoDB | [github.com/nocodb/nocodb](https://github.com/nocodb/nocodb) | AGPL-3.0 |
| Qdrant | [github.com/qdrant/qdrant](https://github.com/qdrant/qdrant) | Apache 2.0 |
| pgvector | [github.com/pgvector/pgvector](https://github.com/pgvector/pgvector) | PostgreSQL License |
| PostgreSQL | [postgresql.org](https://www.postgresql.org/) | PostgreSQL License |
| Portainer | [github.com/portainer/portainer](https://github.com/portainer/portainer) | Zlib |
| Tailscale | [github.com/tailscale/tailscale](https://github.com/tailscale/tailscale) | BSD-3-Clause |

## License

This architecture repository is released under the **Apache License 2.0**. Refer to the [LICENSE](LICENSE) file for conditions. All third-party software remains subject to its respective governing licenses.
