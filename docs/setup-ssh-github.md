*🌍 Read this in [English](setup-ssh-github_EN.md)*

# 🔐 Configurar Github SSH para el Repositorio

Si es una cuenta nueva de GitHub y tu repositorio original no estaba conectado usando SSH, o si quieres usar SSH para que no te pida contraseña al hacer `git push`, sigue esta guía paso a paso.

---

## 1. Generar nueva clave SSH

Abre tu terminal y ejecuta el siguiente comando, sustituyendo el correo por el tuyo de GitHub:

```bash
ssh-keygen -t ed25519 -C "tu-email@ejemplo.com"
```

1. Te preguntará dónde guardar la clave `Enter a file in which to save the key`. Presiona **Enter** para usar la ruta por defecto (`/home/tu_usuario/.ssh/id_ed25519`).
2. Te pedirá una contraseña (`passphrase`). Puedes ponerla para más seguridad o dejarla en blanco dándole a **Enter** dos veces.

## 2. Iniciar el agente SSH

Ejecuta el agente SSH en el fondo:

```bash
eval "$(ssh-agent -s)"
```

Añade la clave que acabamos de crear al agente:

```bash
ssh-add ~/.ssh/id_ed25519
```

## 3. Añadir la clave pública a GitHub

Necesitamos copiar el contenido de la clave pública para dárselo a GitHub.

Muestra la clave en pantalla para copiarla:

```bash
cat ~/.ssh/id_ed25519.pub
```

Copia todo el resultado que sale (empieza por `ssh-ed25519...`).

**En Github:**
1. Ve a **Settings** (Ajustes de cuenta, arriba a la derecha).
2. Haz clic en **SSH and GPG keys** en el menú izquierdo.
3. Clic en el botón verde **New SSH key**.
4. Ponle un título, por ejemplo "Mi Servidor Local".
5. Pega lo que has copiado en el campo "Key" y dale a **Add SSH key**.

## 4. Comprobar que funciona

Ejecuta este comando para probar la conexión con GitHub:

```bash
ssh -T git@github.com
```

Te preguntará algo como `Are you sure you want to continue connecting (yes/no/[fingerprint])?`. Escribe **yes** y pulsa Enter.

Te debería salir un mensaje que dice: `Hi TUSUARIO! You've successfully authenticated...`

---

## 5. Subir nuestro Proyecto (`selfhosted-n8n-ai-stack`)

Ahora que el SSH ya está, vamos a iniciar Git en el proyecto y subirlo.

Entra en la carpeta del repositorio si no estás dentro:

```bash
cd /ruta/a/selfhosted-n8n-ai-stack
```

Inicializa Git:

```bash
git init
```

Añade los archivos y haz el primer commit:

```bash
git add .
git commit -m "🚀 Initial commit: Self-hosted n8n AI stack full configuration"
```

Añade tu repositorio de GitHub como remote origin (cambia el link por tu repositorio):

```bash
git remote add origin git@github.com:TU_USUARIO/selfhosted-n8n-ai-stack.git
```

Renombra la rama principal a `main`:

```bash
git branch -M main
```

¡Sube todo a GitHub!

```bash
git push -u origin main
```

¡Y listos! Con esto ya tendrás todo el stack subido de forma segura a GitHub usando SSH.
