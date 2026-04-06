*🌍 Leer esto en [Español](network-architecture.md)*

# 🌐 Docker Network Architecture

This document explains how the services are connected to each other through internal Docker networks.

---

## Networks

### `n8n-net` — Main AI Network

The primary communication bus where all AI services communicate with one another.

| Service | Container | Internal Port |
|----------|-----------|----------------|
| n8n | `n8n` | 5678 |
| Postgres RAG | `Postgres_RAG` | 5432 (Exposed: 5434) |
| Postgres Vector | `Postgres_Vector` | 5432 (Exposed: 5433) |
| Qdrant | `qdrant` | 6333 |
| Whisper API | `whisper-api` | 5001 |
| LocalAI | `localai` | 8080 (Exposed: 8081) |

**Internal Communication Examples**:
- n8n connects to Whisper: `http://whisper-api:5001/transcribe`
- n8n connects to LocalAI: `http://localai:8080/v1/embeddings`
- n8n connects to Postgres RAG: `Postgres_RAG:5432`

> Services use the `container_name` as their DNS hostname inside the Docker network.

---

### `db` — Database Visualization Network

Network that allows NocoDB to automatically detect and connect to PostgreSQL databases.

| Service | Container |
|----------|-----------|
| NocoDB | `nocodb` |
| Postgres RAG | `Postgres_RAG` |
| Postgres Vector | `Postgres_Vector` |

> NocoDB auto-detects the databases because they share the same network. You only need to add the connection from NocoDB's web GUI.

---

### `internal` — Isolated n8n Network

Secondary network for n8n. Provides an additional layer of isolation.

| Service | Container |
|----------|-----------|
| n8n | `n8n` |

---

### `portainer_default` — Management Network

Independent Portainer network for Docker orchestration management.

| Service | Container |
|----------|-----------|
| Portainer | `portainer` |

---

## Creating the networks

Before bringing up any service, create the external networks manually (unless using the install script):

```bash
docker network create n8n-net
docker network create db
```

> The `internal` and `portainer_default` networks are created automatically by their respective `docker-compose up` commands.

---

## Verifying networks

```bash
# List all networks
docker network ls

# Inspect which containers are connected to which network
docker network inspect n8n-net --format '{{.Name}}: {{range .Containers}}{{.Name}} {{end}}'
docker network inspect db --format '{{.Name}}: {{range .Containers}}{{.Name}} {{end}}'
```

---

## Connectivity Diagram

```text
              ┌─────────────────────────────────────┐
              │           n8n-net                   │
              │                                     │
              │  n8n ←→ Postgres_RAG                │
              │   ↕       ↕                         │
              │  Whisper  Postgres_Vector           │
              │   ↕       ↕                         │
              │  LocalAI  Qdrant                    │
              └─────────────────────────────────────┘
                          ↕ (Postgres_RAG + Postgres_Vector shared)
              ┌─────────────────────────────────────┐
              │            db                       │
              │                                     │
              │  NocoDB ←→ Postgres_RAG             │
              │         ←→ Postgres_Vector          │
              └─────────────────────────────────────┘
```
