# 2️⃣ Preparazione del server Hetzner

Accedi al server e configura l’ambiente:

```bash
ssh root@IP_DEL_SERVER

# Aggiorna pacchetti
apt update && apt upgrade -y

# Installa Docker e Docker Compose
apt install -y docker.io docker-compose git curl
systemctl enable --now docker

# Crea utente deploy
adduser deploy
usermod -aG sudo deploy
```
