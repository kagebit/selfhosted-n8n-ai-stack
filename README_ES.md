*🌍 Read this in [English](README.md)*

# selfhosted-n8n-ai-stack

Stack completo de automatización con IA, 100% self-hosted, configurado con Docker y redes internas aisladas.

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![n8n](https://img.shields.io/badge/n8n-Automation-FA6800?logo=n8n&logoColor=white)](https://n8n.io/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Vector_RAG-336791?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Tailscale](https://img.shields.io/badge/Tailscale-Funnel_Secure-black?logo=tailscale&logoColor=white)](https://tailscale.com/)

---

## Características

- **Workflows con IA Local**: Automatización completa en n8n. Por defecto corremos los embeddings en local. Además, la IA (LLMs) también se corre completamente en local si tu máquina tiene la capacidad, ahorrando costes de APIs externas. Puedes comprobar qué modelos soporta tu hardware entrando a [canirun.ai](https://canirun.ai/).
- **RAG y Búsquedas Vectoriales**: PostgreSQL integrado con la extensión pgvector y Qdrant para búsquedas semánticas de alto rendimiento.
- **Integración Segura**: Script para automatizar Tailscale Funnel que provee endpoints HTTPS públicos y seguros (ideal para recibir webhooks de Telegram).
- **Eficiencia de Recursos**: Uso de modelos optimizados y ligeros (`small` en Whisper y `all-MiniLM-L6-v2` para embeddings), aptos para hardware personal o modesto.
- **Gestión Visual de Datos**: Interfaz consolidada estilo hoja de cálculo para tus bases de datos cortesía de NocoDB.
- **Seguridad en Red**: Las redes internas de Docker creadas a medida aseguran que la comunicación de datos fundamentales permanezca aislada del exterior.

## Ejemplo de Agente

![Flujo de Agente en n8n](src/images/n8n_agent_flow.gif)

## Prerrequisitos

El stack requiere un sistema operativo anfitrión basado en Linux. El script de instalación automatizado ha sido probado y es compatible con Debian, Ubuntu, Fedora, CentOS y Arch Linux.

| Requisito | 🔹 Mínimo | 🔹 Recomendado |
| :--- | :--- | :--- |
| **CPU** | 3 núcleos | 6–8 núcleos |
| **RAM** | 4 GB | 16 GB o más |
| **Almacenamiento** | 50 GB (SSD recomendado) | SSD NVMe |
| **GPU** | No requerida | Compatible (IA Local/Whisper) |
| **Sistema** | Windows 10+, macOS 12+, Linux | Linux o MacOS |
| **Aviso** | *Con 4 GB, Whisper puede ir muy justo.* | *Ideal para uso fluido.* |

> 🪟 **Usuarios de Windows**: Puedes montar este stack de forma nativa utilizando el **Subsistema de Windows para Linux (WSL)**. Recomendamos firmemente instalar la distribución de **Debian** en lugar de Ubuntu, ya que consume muchísimos menos recursos en segundo plano, haciéndolo ideal para montar el stack de IA de forma estable.
> Para instalar Debian desde Windows WSL, introduce en tu consola: `wsl --install -d Debian` (Consulta la [guía oficial de Debian en WSL](https://wiki.debian.org/InstallingDebianOn/Microsoft/Windows/SubsystemForLinux) para más detalles).

## Instalación

### 1. Configuración Automatizada

Clona el repositorio y ejecuta el script de setup. Este script resolverá dependencias, creará la estructura de redes internas de Docker, rellenará las plantillas de variables de entorno y lanzará los contenedores.

#### Para Distribuciones de Linux

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

Durante la instalación, el script pausará temporalmente la ejecución para que tengas tiempo de configurar de forma manual (y privada) las plantillas `.env` presentes en `services/n8n/`, `services/postgres-rag/` y `services/postgres-vector/`.

### 2. Configurar Tailscale Funnel (Recomendado)

Para que n8n sea capaz de recibir peticiones desde internet bajo un dominio HTTPS válido (imprescindible para crear webhooks con Telegram u otros), necesitas configurar Tailscale Funnel. Lanza el configurador automático desde la raíz del mismo repositorio:

```bash
chmod +x tailscale_config.sh
sudo ./tailscale_config.sh
```

Este script verifica tu estado de autenticación en Tailscale, activa el servicio Funnel exponiendo el puerto 5678, y actualiza de inmediato tu `.env` con las URL mágicas de Webhook correctas. Tienes también instrucciones de configuración manual paso por paso en [docs/tailscale-setup.md](docs/tailscale-setup.md).

## Uso

Una vez completada la instalación, toda la capa de orquestación arrancará de forma automática al iniciar sesión e incluso en futuros reinicios. Ya puedes entrar a los servicios y construir automatizaciones.

### Acceso a las Interfaces

- **n8n**: `http://localhost:5678` (Orquestador principal de flujos de trabajo)
- **LocalAI**: `http://localhost:8081` (Interfaz web nativa para descargar y probar distintos LLM)
- **NocoDB**: `http://localhost:9093` (Visualización de PostgreSQL orientada al usuario)
- **Portainer**: `http://localhost:9000` (Panel superligero para administrar logs y contenedores de Docker)

### Endpoints de API Internos (Red Interna de Docker)

Estos endpoints no son accesibles desde fuera, pero puedes llamarlos desde n8n apuntando así:
- **PostgreSQL RAG**: `postgres-rag:5434`
- **PostgreSQL Vector**: `postgres-vector:5433` *(Requiere un `CREATE EXTENSION IF NOT EXISTS vector;` post-instalación)*
- **Qdrant**: `qdrant:6333`
- **Whisper**: `whisper:5001` (Contenedor que hace de Wrapper API para Whisper)
- **LocalAI**: `localai:8081` (LLMs y embeddings locales)

### Topología de la Arquitectura

Para un diagrama detallado de la topología de redes Docker y la conectividad entre servicios, consulta → [docs/network-architecture.md](docs/network-architecture.md)

### Nodos Importables (Configuración lista para usar)

Dentro de la carpeta `n8n-nodes/` encontrarás configurado y listo para funcionar un **nodo tipo HTTP Request** cuya llamada apunta directamente a tu endpoint local de la API de Whisper.
Para usarlo en un flujo cualquiera:
1. Abre tu interfaz de n8n.
2. Entra al menú lateral y haz clic en **Import from file...**
3. Carga el archivo ubicado en `n8n-nodes/http-request-whisper.json`.

## Agradecimientos

Se hace uso directo de las siguientes tecnologías de software libre de terceros:

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

## Licencia

Este clúster de conocimiento e infraestructura de arquitectura está respaldado y publicado bajo la variante de licencia **Apache License 2.0**. Puedes verificar la confirmación legal en el documento [LICENSE](LICENSE). Obviamente todo el software secundario de terceros que orquesta tiene sus propias variantes expuestas de licencias originales correspondientes.
