*🌍 Read this in [English](tailscale-setup_EN.md)*

# 🔒 Configuración de Tailscale Funnel

Tailscale Funnel permite exponer un servicio local a internet con HTTPS, sin necesidad de abrir puertos en el router ni comprar un dominio.

Esto es **necesario** para que n8n pueda recibir webhooks de Telegram, ya que Telegram requiere HTTPS (TLS/SSL) obligatoriamente.

> **💡 Atajo rápido**: Puedes automatizar los pasos 4 y 5 de esta guía ejecutando `sudo ./tailscale_config.sh` desde la raíz del repositorio.

---

## ¿Por qué Tailscale?

| Alternativa | Problema |
|-------------|----------|
| Abrir puertos en el router | Inseguro, expone el servidor |
| ngrok | Limitado en versión gratuita, URL cambia |
| Cloudflare Tunnel | Más complejo de configurar |
| **Tailscale Funnel** | ✅ Gratis, HTTPS automático, URL fija, sin abrir puertos |

---

## Instalación

### 1. Instalar Tailscale

```bash
# Debian / Ubuntu
curl -fsSL https://tailscale.com/install.sh | sh

# Arch Linux
sudo pacman -S tailscale
```

### 2. Conectar a tu cuenta

```bash
sudo tailscale up
```

Esto abrirá un enlace para autenticar tu máquina en [login.tailscale.com](https://login.tailscale.com).

### 3. Habilitar Funnel

En el panel de admin de Tailscale ([login.tailscale.com/admin](https://login.tailscale.com/admin)):

1. Ve a **DNS** y asegúrate de tener HTTPS habilitado
2. Ve a **Access Controls** y añade los permisos de Funnel

### 4. Exponer n8n con Funnel

```bash
# Expone el puerto 5678 de n8n con HTTPS
sudo tailscale funnel 5678
```

Esto te dará una URL como: `https://tu-maquina.tail-net.ts.net`

### 5. Configurar n8n

En el archivo `.env` de n8n, configura las URLs de webhook:

```env
WEBHOOK_URL=https://tu-maquina.tail-net.ts.net
WEBHOOK_TUNNEL_URL=https://tu-maquina.tail-net.ts.net
```

Reinicia n8n:

```bash
cd services/n8n && docker-compose restart
```

### 6. Configurar el trigger de Telegram en n8n

1. En n8n, crea un nodo **Telegram Trigger**
2. Configura tu Bot Token
3. n8n registrará automáticamente el webhook con Telegram usando la URL HTTPS de Tailscale

---

## Verificar que funciona

```bash
# Ver el estado de Tailscale
tailscale status

# Ver el estado del Funnel
tailscale funnel status
```

También puedes visitar `https://tu-maquina.tail-net.ts.net` desde cualquier navegador para verificar que n8n responde por HTTPS.

---

## Persistencia

Para que el Funnel arranque automáticamente al reiniciar el servidor:

```bash
# Habilitar el servicio de Tailscale
sudo systemctl enable tailscaled

# El funnel se configura de forma persistente
sudo tailscale funnel --bg 5678
```

---

## Notas

- Tailscale Funnel se ejecuta a **nivel de sistema**, no dentro de un contenedor Docker
- La URL de Tailscale es fija mientras mantengas tu cuenta configurada
- El certificado TLS se renueva automáticamente
- Funciona desde cualquier dispositivo conectado a tu red Tailscale
