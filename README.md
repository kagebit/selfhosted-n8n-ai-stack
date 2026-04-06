*🌍 Leer esto en [Español (Spanish)](README_ES.md)*

# selfhosted-n8n-ai-stack

Self-hosted AI automation stack orchestrated via Docker and isolated internal networks.

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![n8n](https://img.shields.io/badge/n8n-Automation-FA6800?logo=n8n&logoColor=white)](https://n8n.io/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Vector_RAG-336791?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Tailscale](https://img.shields.io/badge/Tailscale-Funnel_Secure-black?logo=tailscale&logoColor=white)](https://tailscale.com/)

---

## Overview

This repository contains the configuration needed to deploy a locally hosted AI automation environment. It utilizes Docker to containerize and orchestrate the following services:

- **n8n**: Workflow automation and AI agent orchestration.
- **PostgreSQL**: Standard relational database for RAG (Retrieval-Augmented Generation) data storage.
- **PostgreSQL (pgvector)**: Vector database for semantic search and embeddings storage.
- **Qdrant**: Alternative high-performance vector database.
- **LocalAI**: Local embedding generation utilizing the `all-MiniLM-L6-v2` model.
- **Whisper**: Local speech-to-text API wrapping OpenAI's Whisper model.
- **NocoDB**: Web-based visual interface for database management.
- **Portainer**: Web-based Docker container management.
- **Tailscale Funnel**: Secure exposure of local services via HTTPS (required for external webhooks like Telegram).

The architecture relies on isolated Docker networks to ensure secure communication between internal components without unnecessarily exposing ports to the host system.

> **Note**: This repository provides orchestration and configuration files only. All source code executed belongs to their respective third-party upstream repositories (referenced at the end of this document).

---

## Showcase

> **[🖼️ Media Placeholder]** 
> *Replace this block with a screenshot of your architecture, NocoDB dashboard, or a short GIF of an n8n workflow responding via Telegram.*
> `![Stack Overview](src/images/screenshot.png)`

---

## Architecture

```text
┌────────────────────────────────────────────────────────────────────────┐
│                          TAILSCALE FUNNEL                              │
│                    (HTTPS → localhost:5678)                            │
│           Secure remote access and public webhook endpoint             │
└──────────────────────────────┬─────────────────────────────────────────┘
                               │
┌──────────────────────────────▼─────────────────────────────────────────┐
│                           NETWORK: n8n-net                             │
│                                                                        │
│  ┌──────────┐  ┌──────────────┐  ┌───────────────┐  ┌──────────────┐   │
│  │   n8n    │  │ Postgres RAG │  │Postgres Vector│  │   Qdrant     │   │
│  │  :5678   │  │    :5434     │  │    :5433      │  │   :6333      │   │
│  └────┬─────┘  └──────────────┘  └───────────────┘  └──────────────┘   │
│       │                                                                │
│  ┌────▼─────┐  ┌──────────────┐                                        │
│  │ Whisper  │  │   LocalAI    │                                        │
│  │  :5001   │  │    :8081     │                                        │
│  └──────────┘  │ (embeddings) │                                        │
│                └──────────────┘                                        │
└────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────┐
│                            NETWORK: db                                 │
│                                                                        │
│  ┌──────────┐  ┌──────────────┐  ┌───────────────┐                     │
│  │  NocoDB  │  │ Postgres RAG │  │Postgres Vector│                     │
│  │  :9093   │  │   (shared)   │  │   (shared)    │                     │
│  └──────────┘  └──────────────┘  └───────────────┘                     │
│                                                                        │
│  NocoDB auto-detects associated databases via shared network context.  │
└────────────────────────────────────────────────────────────────────────┘

┌─────────────┐
│  Portainer  │  ← Container Management GUI
│   :9000     │
└─────────────┘
```

### Network Topology

| Network | Bound Services | Purpose |
|-----|-----------|-----------|
| `n8n-net` | n8n, Postgres RAG, Postgres Vector, Qdrant, Whisper, LocalAI | Core communication layer between AI services and the orchestrator. |
| `db` | NocoDB, Postgres RAG, Postgres Vector | Visualization and management network layer for relational databases. |
| `internal` | n8n | Isolated secondary network for n8n. |
| `portainer_default` | Portainer | Management network for Docker administration. |

---

## Installation Guide

### 1. Prerequisites

The stack requires a Linux-based host environment. The automated installation script is compatible with Debian, Ubuntu, Fedora, CentOS, and Arch Linux.

> 🪟 **Windows Users**: You can deploy this stack natively using the **Windows Subsystem for Linux (WSL)**. We highly recommend installing a **Debian** WSL distribution rather than Ubuntu, as Debian consumes considerably fewer background CPU and RAM resources, making it ideal for a persistent AI stack.
> To install Debian on Windows WSL, run: `wsl --install -d Debian` (See [official Debian WSL guide](https://wiki.debian.org/InstallingDebianOn/Microsoft/Windows/SubsystemForLinux) for details).

### 2. Automated Setup

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

### 3. Tailscale Funnel Configuration (Recommended)

For integrations that require valid HTTPS endpoints (e.g., Telegram Webhooks), you must configure Tailscale Funnel. Run the automated configurator from the repository root:

```bash
chmod +x tailscale_config.sh
sudo ./tailscale_config.sh
```

This script verifies your Tailscale authentication, exposes n8n via HTTPS on port 5678, and automatically updates your `.env` with the correct webhook URLs. For manual step-by-step instructions, refer to [docs/tailscale-setup.md](docs/tailscale-setup.md).

---

## Services Detail

### n8n (Workflow Orchestrator)
- **Port**: `5678`
- **Application**: Workflows, AI agents, and API integrations.

### PostgreSQL RAG
- **Port**: `5434`
- **Base Image**: `postgres:16`
- **Application**: Persistent storage for RAG pipeline context and n8n workflows.

### PostgreSQL Vector
- **Port**: `5433`
- **Base Image**: `ankane/pgvector:latest`
- **Application**: Vectorized embeddings storage for semantic search. *Note: Requires `CREATE EXTENSION IF NOT EXISTS vector;` post-deployment.*

### Qdrant
- **Port**: `6333`
- **Base Image**: `qdrant/qdrant`
- **Application**: High-performance semantic vector search engine.

### Whisper API
- **Port**: `5001`
- **Build**: Custom wrapped API around [openai/whisper](https://github.com/openai/whisper).
- **Application**: Local Speech-to-Text inference handling HTTP requests from n8n. By default, it uses the `small` parameter model for optimal performance on consumer hardware. You can easily switch to more powerful models (`medium`, `large-v3`, etc.) in the Dockerfile if your server hardware permits.

### LocalAI
- **Port**: `8081`
- **Build**: LocalAI image deployment.
- **Application**: Emulates standard API endpoints to generate embeddings locally utilizing `all-MiniLM-L6-v2`. Because port `8081` is exposed to the host system, you can directly access the Native Web GUI at `http://localhost:8081` to manage, download, or dynamically swap other AI models through your browser (subject to local hardware constraints).

### NocoDB
- **Port**: `9093`
- **Base Image**: `nocodb/nocodb:latest`
- **Application**: Smart spreadsheet interface overlaying the PostgreSQL databases.

### Portainer
- **Port**: `9000`
- **Base Image**: `portainer/portainer-ce:latest`
- **Application**: System orchestration and container health monitoring. Acts as a lightweight, web-based alternative to Docker Desktop. It provides a complete visual interface for managing containers, inspecting live logs, and monitoring resource usage across the stack without the heavy memory footprint of traditional desktop GUI tools.

---

## Node Configuration

Included in `n8n-nodes/` is a predefined **HTTP Request** node template pointing to the local Whisper API endpoint. To import it:
1. Open an n8n workflow.
2. Select **Import from file**.
3. Point to `n8n-nodes/http-request-whisper.json`.

---

## Infrastructure Design Principles

- **Resource Efficiency**: Usage of the `small` Whisper model and `all-MiniLM-L6-v2` embeddings ensures viability on resource-constrained hardware.
- **Data Segregation**: Internal networks prevent external access to unencrypted database traffic.
- **Development Tooling**: NocoDB replaces repetitive CLI database queries with a robust GUI layer automatically mapped via the `db` network.
- **Secure Ingress**: Tailscale Funnel provides uncompromising endpoint encryption via TLS without opening router ports or paying for static IPs. Built on top of the highly secure **WireGuard** protocol, it allows **persistent, permanent exposure** of n8n for production use, completely bypassing the time limits or temporary constraints typically found in services like ngrok or local Cloudflare tunnels.

---

## Upstream Project References

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

---

## License

This architecture repository is released under the **Apache License 2.0**. Reference the [LICENSE](LICENSE) file for conditions. All third-party software remains subject to its respective governing licenses.
