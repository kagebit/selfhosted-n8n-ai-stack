*🌍 Read this in [English](README.md)*

# selfhosted-n8n-ai-stack

Stack completo de automatización con IA, 100% self-hosted, configurado con Docker y redes internas aisladas.

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![n8n](https://img.shields.io/badge/n8n-Automation-FA6800?logo=n8n&logoColor=white)](https://n8n.io/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Vector_RAG-336791?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Tailscale](https://img.shields.io/badge/Tailscale-Funnel_Secure-black?logo=tailscale&logoColor=white)](https://tailscale.com/)

---

## Resumen

Este repositorio contiene la configuración necesaria para desplegar un entorno de automatización de IA en un servidor local. Utiliza Docker para orquestar los siguientes contenedores:

- **n8n**: Orquestador de flujos de trabajo (workflows) y agentes de IA.
- **PostgreSQL**: Base de datos relacional estándar para almacenamiento de datos RAG (Retrieval-Augmented Generation).
- **PostgreSQL (pgvector)**: Base de datos vectorial para búsqueda semántica y almacenamiento de embeddings.
- **Qdrant**: Base de datos vectorial de alto rendimiento alternativa.
- **LocalAI**: Generador local de embeddings usando el modelo `all-MiniLM-L6-v2`.
- **Whisper**: API local de voz a texto basada en el modelo Whisper de OpenAI.
- **NocoDB**: Interfaz visual web para gestionar las bases de datos.
- **Portainer**: Gestión visual de contenedores Docker.
- **Tailscale Funnel**: Exposición segura mediante HTTPS (necesario para configurar webhooks externos como Telegram).

La arquitectura usa redes internas de Docker para garantizar una comunicación segura entre componentes sin tener que exponer puertos al exterior de forma innecesaria.

> **Nota**: Este repositorio aporta los archivos de configuración y orquestación. Todo el código fuente real ejecutado pertenece a sus respectivos repositorios oficiales (referenciados al final de este documento).

---

## Showcase

> **[🖼️ Placeholder de Contenido Multimedia]** 
> *Reemplaza este bloque con un pantallazo de tu arquitectura, tu panel de NocoDB, o un corto GIF de tu n8n respondiendo en Telegram.*
> `![Stack Overview](src/images/screenshot.png)`

---

## Arquitectura

```text
┌────────────────────────────────────────────────────────────────────────┐
│                          TAILSCALE FUNNEL                              │
│                    (HTTPS → localhost:5678)                            │
│           Acceso remoto seguro y endpoint público de webhooks          │
└──────────────────────────────┬─────────────────────────────────────────┘
                               │
┌──────────────────────────────▼─────────────────────────────────────────┐
│                           RED: n8n-net                                 │
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
│                            RED: db                                     │
│                                                                        │
│  ┌──────────┐  ┌──────────────┐  ┌───────────────┐                     │
│  │  NocoDB  │  │ Postgres RAG │  │Postgres Vector│                     │
│  │  :9093   │  │  (compartido)│  │ (compartido)  │                     │
│  └──────────┘  └──────────────┘  └───────────────┘                     │
│                                                                        │
│  NocoDB autodetecta las bases de datos al compartir la misma red.      │
└────────────────────────────────────────────────────────────────────────┘

┌─────────────┐
│  Portainer  │  ← Panel de gestión Docker
│   :9000     │
└─────────────┘
```

### Topología de Redes

| Red | Servicios asignados | Propósito |
|-----|-----------|-----------|
| `n8n-net` | n8n, Postgres RAG, Postgres Vector, Qdrant, Whisper, LocalAI | Capa principal de comunicación entre servicios de IA y n8n. |
| `db` | NocoDB, Postgres RAG, Postgres Vector | Red de visualización y gestión para las bases de datos. |
| `internal` | n8n | Red secundaria aislada exclusiva de n8n. |
| `portainer_default` | Portainer | Red de administración para Docker. |

---

## Guía de Instalación

### 1. Prerrequisitos

El stack requiere un sistema host basado en Linux. El script de instalación automatizado es compatible con Debian, Ubuntu, Fedora, CentOS y Arch Linux.

> 🪟 **Usuarios de Windows**: Puedes montar este stack de forma nativa utilizando **Windows Subsystem for Linux (WSL)**. Te recomendamos firmemente instalar la distribución de **Debian** en lugar de Ubuntu, ya que consume muchísimos menos recursos (RAM y CPU) en segundo plano.
> Para instalar Debian desde Windows WSL, introduce: `wsl --install -d Debian` (Consulta [la guía oficial de Debian en WSL](https://wiki.debian.org/InstallingDebianOn/Microsoft/Windows/SubsystemForLinux) para más detalles).

### 2. Configuración Automatizada

Clona el repositorio y ejecuta el script automatizado. El script resolverá las dependencias necesarias, creará las redes, generará los archivos `.env` y desplegará el stack.

#### Para Distribuciones Linux

```bash
git clone https://github.com/Hamza-Cloud-DevOPS/selfhosted-n8n-ai-stack.git
cd selfhosted-n8n-ai-stack
chmod +x install.sh
sudo ./install.sh
```

#### Para Dispositivos macOS

```bash
git clone https://github.com/Hamza-Cloud-DevOPS/selfhosted-n8n-ai-stack.git
cd selfhosted-n8n-ai-stack
chmod +x mac_install.sh
./mac_install.sh
```

Durante la ejecución, el script se pausará para permitirte editar manualmente tus variables seguras `.env` presentes en `services/n8n/`, `services/postgres-rag/` y `services/postgres-vector/`.

### 3. Configuración de Tailscale Funnel (Recomendado)

Para que n8n pueda recibir webhooks seguros por HTTPS (imprescindible para Telegram y otras integraciones), debes configurar Tailscale Funnel. Ejecuta el configurador automático desde la raíz del repositorio:

```bash
chmod +x tailscale_config.sh
sudo ./tailscale_config.sh
```

Este script verificará tu autenticación de Tailscale, expondrá n8n vía HTTPS en el puerto 5678 y actualizará automáticamente tu `.env` con las URLs de webhook correctas. Para instrucciones manuales paso a paso, consulta [docs/tailscale-setup.md](docs/tailscale-setup.md).

---

## Detalle de los Servicios

### n8n (Orquestador de Workflows)
- **Puerto**: `5678`
- **Uso**: Creación de lógicas, flujos de trabajo, automatizaciones y agentes de inteligencia artificial.

### PostgreSQL RAG
- **Puerto**: `5434`
- **Imagen**: `postgres:16`
- **Uso**: Almacenamiento persistente para contextos RAG y ajustes del orquestador.

### PostgreSQL Vector
- **Puerto**: `5433`
- **Imagen**: `ankane/pgvector:latest`
- **Uso**: Almacenamiento vectorizado para búsquedas semánticas profundas. *Nota: Requiere ejecutar un `CREATE EXTENSION IF NOT EXISTS vector;` post-instalación (el script lo intenta automáticamente).*

### Qdrant
- **Puerto**: `6333`
- **Imagen**: `qdrant/qdrant`
- **Uso**: Motor de base de datos vectorial enfocado a alto rendimiento de red.

### Whisper API
- **Puerto**: `5001`
- **Build**: Wrapper personalizado para API basándose en [openai/whisper](https://github.com/openai/whisper).
- **Uso**: Inferencia de voz-a-texto manejando peticiones HTTP generadas desde n8n. Por defecto usa el modelo `small` para hardware humilde, pero puedes cambiarlo (`medium`, `large-v3`, etc.) en el propio Dockerfile si tu servidor es más potente.

### LocalAI
- **Puerto**: `8081`
- **Build**: Entorno LocalAI.
- **Uso**: Emula un endpoint estándar para calcular embeddings locales a través del modelo `all-MiniLM-L6-v2`. Al exponer el puerto `8081` de forma host, tienes un acceso GUI Nativo web entrando en `http://localhost:8081`. Desde allí puedes descargar o gestionar los modelos directamente en el navegador según te permita tu hardware.

### NocoDB
- **Puerto**: `9093`
- **Imagen**: `nocodb/nocodb:latest`
- **Uso**: Interfaz en formato hoja de cálculo dinámica (estilo Airtable) apuntando a las bases de datos PostgreSQL.

### Portainer
- **Puerto**: `9000`
- **Imagen**: `portainer/portainer-ce:latest`
- **Uso**: Actúa como la alternativa ligera web al pesado Docker Desktop. Da interfaz visual y monitorización en tiempo real sobre recursos, redes y registros a lo largo de todo el stack de forma eficientísima.

---

## Nodos y Flujos

Incluido en la carpeta `n8n-nodes/` está configurado el **nodo HTTP Request** listo para llamar al endpoint de la Whisper API de forma nativa. Simplemente:
1. Abre n8n y crea un flujo en blanco.
2. Clica botón derecho o ve al menú para seleccionar **Import from file**.
3. Selecciona `n8n-nodes/http-request-whisper.json`.

---

## Principios de la Arquitectura

- **Eficiencia Limitada de Redursos**: Mantener los baremos de los modelos bajo el ratio Whisper `small` y LocalAI `all-MiniLM-L6-v2` permite trabajar consistentemente sin sobrecargar gráficamente el ordenador personal.
- **Segregación de Datos**: Las redes internas capadas por Docker previenen que el tráfico sea accesible de manera pública.
- **Simplificación Herramientas Dev**: Usamos las redes cruzadas para conectar automáticamente NocoDB al resto eludiendo los comandos de SQL tediosos desde consola.
- **Acceso Remoto con Tailscale**: Al montarse y asegurarse sobre criptografía **WireGuard**, Tailscale Funnel proporciona una encriptación y soporte **persistente y permanente** superando con creces la duración e inconvenientes temporales clásicos como túneles Ngrok gratuitos o TryCloudflare.

---

## Referencias Oficiales (Upstream)

| Componente | Fuente Original | Licencia |
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

## Licencia

Este clúster de conocimiento e infraestructura de arquitectura está respaldado y publicado bajo la variante de licencia **Apache License 2.0**. Puedes verificar la confirmación legal en el documento [LICENSE](LICENSE). Obviamente todo el software secundario de terceros que orquesta tiene sus propias variantes expuestas de licencias originales.
