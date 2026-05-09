# 5️⃣ Configurazione Docker e Traefik

Esempio `docker-compose.production.yml`:

```yaml
services:
  traefik:
    image: traefik:v2.14
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.myresolver.acme.tlschallenge=true"
      - "--certificatesresolvers.myresolver.acme.email=tuo@email.com"
      - "--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json"
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "./letsencrypt:/letsencrypt"

  web:
    image: tuo_progetto:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.rails.rule=Host()"
      - "traefik.http.routers.rails.entrypoints=websecure"
      - "traefik.http.routers.rails.tls.certresolver=myresolver"
    depends_on:
      - db
      - redis
```
