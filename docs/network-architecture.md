*🌍 Read this in [English](network-architecture_EN.md)*

# 🌐 Arquitectura de redes Docker

Este documento explica cómo están conectados los servicios a través de las redes Docker.

---

## Redes

### `n8n-net` — Red principal

Red donde todos los servicios de IA se comunican entre sí.

| Servicio | Container | Puerto interno |
|----------|-----------|----------------|
| n8n | `n8n` | 5678 |
| Postgres RAG | `Postgres_RAG` | 5432 (expuesto: 5434) |
| Postgres Vector | `Postgres_Vector` | 5432 (expuesto: 5433) |
| Qdrant | `qdrant` | 6333 |
| Whisper API | `whisper-api` | 5001 |
| LocalAI | `localai` | 8080 (expuesto: 8081) |

**Ejemplo de comunicación interna**:
- n8n llama a Whisper: `http://whisper-api:5001/transcribe`
- n8n llama a LocalAI: `http://localai:8080/v1/embeddings`
- n8n conecta a Postgres RAG: `Postgres_RAG:5432`

> Los servicios usan el `container_name` como hostname dentro de la red Docker.

---

### `db` — Red de visualización de bases de datos

Red que permite a NocoDB detectar y conectar automáticamente a las bases de datos PostgreSQL.

| Servicio | Container |
|----------|-----------|
| NocoDB | `nocodb` |
| Postgres RAG | `Postgres_RAG` |
| Postgres Vector | `Postgres_Vector` |

> NocoDB detecta las bases de datos al estar en la misma red. Solo hay que añadir la conexión desde la interfaz web de NocoDB.

---

### `internal` — Red interna de n8n

Red aislada para n8n. Proporciona una capa adicional de aislamiento.

| Servicio | Container |
|----------|-----------|
| n8n | `n8n` |

---

### `portainer_default` — Red de gestión

Red independiente de Portainer para la gestión de Docker.

| Servicio | Container |
|----------|-----------|
| Portainer | `portainer` |

---

## Crear las redes

Antes de levantar cualquier servicio, crear las redes externas:

```bash
docker network create n8n-net
docker network create db
```

> Las redes `internal` y `portainer_default` se crean automáticamente con sus respectivos `docker-compose up`.

---

## Verificar las redes

```bash
# Ver todas las redes
docker network ls

# Ver qué contenedores están en cada red
docker network inspect n8n-net --format '{{.Name}}: {{range .Containers}}{{.Name}} {{end}}'
docker network inspect db --format '{{.Name}}: {{range .Containers}}{{.Name}} {{end}}'
```

---

## Diagrama de conectividad

```
              ┌─────────────────────────────────────┐
              │           n8n-net                   │
              │                                     │
              │  n8n ←→ Postgres_RAG                │
              │   ↕       ↕                         │
              │  Whisper  Postgres_Vector           │
              │   ↕       ↕                         │
              │  LocalAI  Qdrant                    │
              └─────────────────────────────────────┘
                          ↕ (Postgres_RAG + Postgres_Vector comparten)
              ┌─────────────────────────────────────┐
              │            db                       │
              │                                     │
              │  NocoDB ←→ Postgres_RAG             │
              │         ←→ Postgres_Vector          │
              └─────────────────────────────────────┘
```
