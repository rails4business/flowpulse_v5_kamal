# Deployment Flowpulse V5 - Hetzner + Kamal + Traefik + Let's Encrypt

## Panoramica Setup Produzione (senza Hatchbox)

Setup end-to-end per deployare Flowpulse V5 in produzione senza usare Hatchbox, usando:
- **Hetzner Cloud** - hosting server
- **Kamal** - orchestrazione deploy e container management
- **Traefik** - reverse proxy e SSL termination
- **Let's Encrypt** - certificati SSL gratuiti

---

## STEP 1: Preparazione Server Hetzner

### 1.1 Creare Server su Hetzner

1. Accedi a [console.hetzner.cloud](https://console.hetzner.cloud)
2. Crea nuovo server:
   - **Immagine**: Ubuntu 24.04 LTS (o latest LTS)
   - **Tipo**: CPX21 (minimo per produzione: 2 vCPU, 4GB RAM, 40GB SSD)
   - **Data Center**: Scegli quello più vicino ai tuoi utenti
   - **SSH Key**: Carica la tua public key (o crea nuova)
   - **Volume aggiuntivo** (opzionale): Se usi SQLite, considera volume esterno per backup
   - **Nome**: es. `flowpulse-prod-1`

### 1.2 Configurazione SSH

```bash
# Salva IP pubblico
HETZNER_IP=<IP_DEL_SERVER>

# Testa connessione SSH
ssh -i ~/.ssh/your-key root@$HETZNER_IP

# Primo login: aggiorna sistema
ssh -i ~/.ssh/your-key root@$HETZNER_IP << 'EOF'
apt-get update
apt-get upgrade -y
apt-get install -y curl wget git jq
EOF
```

### 1.3 Installa Docker

```bash
ssh -i ~/.ssh/your-key root@$HETZNER_IP << 'EOF'
# Aggiungi repository Docker ufficiale
apt-get remove -y docker.io docker-doc docker-compose
apt-get install -y ca-certificates curl gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Installa Docker
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Avvia Docker
systemctl enable docker
systemctl start docker

# Verifica installazione
docker --version
EOF
```

### 1.4 Prepara le directories per persistenza

```bash
ssh -i ~/.ssh/your-key root@$HETZNER_IP << 'EOF'
# Crea directory per dati persistenti
mkdir -p /mnt/flowpulse/storage
mkdir -p /mnt/flowpulse/traefik
mkdir -p /mnt/flowpulse/letsencrypt

# Crea file di configurazione vuoto per Traefik (necessario)
touch /mnt/flowpulse/traefik/traefik.yml

# Crea file per certificati Let's Encrypt
touch /mnt/flowpulse/letsencrypt/acme.json
chmod 600 /mnt/flowpulse/letsencrypt/acme.json

# Dai permessi Docker
chown -R 0:0 /mnt/flowpulse
EOF
```

---

## STEP 2: Preparazione Registry Docker Locale (Registry Accessibile)

Per Kamal hai 2 opzioni:
- **Opzione A**: Usare registry esterno (GHCR, DockerHub, etc.)
- **Opzione B**: Registry locale su Hetzner

### Opzione A: GitHub Container Registry (Consigliato - Più semplice)

```bash
# 1. Crea Personal Access Token su GitHub
# Settings > Developer settings > Personal access tokens > Tokens (classic)
# Scopes necessari: write:packages, read:packages, delete:packages

# 2. Salva token in ~/.kamal/secrets (Kamal lo usa automaticamente)
echo "KAMAL_REGISTRY_PASSWORD=<YOUR_GITHUB_TOKEN>" >> ~/.kamal/secrets

# 3. In config/deploy.yml usa GHCR:
# registry:
#   server: ghcr.io
#   username: your-github-username
```

---

## STEP 3: Configurazione Kamal per Traefik + Let's Encrypt

**Kamal v3 ha due opzioni:**

### Opzione A: Proxy Built-in Kamal (Raccomandato - Semplice)

Usa il proxy SSL nativo di Kamal (che usa Traefik internamente):

```yaml
# config/deploy.yml

service: flowpulse_v_5
image: flowpulse_v_5

# Deploy a server Hetzner
servers:
  web:
    - <HETZNER_IP>

# Registry con autenticazione
registry:
  server: ghcr.io
  username: <your-github-username>
  password:
    - KAMAL_REGISTRY_PASSWORD

# ✅ PROXY KAMAL BUILT-IN CON SSL/TRAEFIK AUTO
proxy:
  ssl: true
  host: your-domain.com

env:
  secret:
    - RAILS_MASTER_KEY
  clear:
    SOLID_QUEUE_IN_PUMA: true

# Volume per storage
volumes:
  - "flowpulse_v_5_storage:/rails/storage"

asset_path: /rails/public/assets

builder:
  arch: amd64
```

**⚠️ QUANDO USI PROXY CON SSL:**
- Devi abilitare `config.force_ssl = true` e `config.assume_ssl = true` in `config/environments/production.rb`
- Kamal gestisce automaticamente il certificato Let's Encrypt
- NON aggiungere labels Traefik specifiche

---

### Opzione B: Traefik Esplicito (Più controllo)

Se vuoi più controllo su Traefik (dashboard, configurazione fine, etc.):

```yaml
# config/deploy.yml

service: flowpulse_v_5
image: flowpulse_v_5

servers:
  web:
    - <HETZNER_IP>

registry:
  server: ghcr.io
  username: <your-github-username>
  password:
    - KAMAL_REGISTRY_PASSWORD

# ✅ TRAEFIK COME ACCESSORY SERVICE (non built-in proxy)
# Questo ti dà pieno controllo su Traefik
accessories:
  traefik:
    image: traefik:v3.1
    host: <HETZNER_IP>
    options:
      publish:
        - "80:80"
        - "443:443"
      cap_add:
        - NET_BIND_SERVICE
      volumes:
        - /var/run/docker.sock:/var/run/docker.sock
        - /mnt/flowpulse/traefik/traefik.yml:/traefik.yml:ro
        - /mnt/flowpulse/letsencrypt:/letsencrypt
    directories:
      - letsencrypt:/letsencrypt
    env:
      clear:
        TRAEFIK_API_DASHBOARD: "true"
        TRAEFIK_PROVIDERS_DOCKER: "true"
        TRAEFIK_PROVIDERS_DOCKER_EXPOSEDBYDEFAULT: "false"

# App labels per routing Traefik
labels:
  traefik.enable: "true"
  traefik.http.routers.flowpulse.rule: "Host(`your-domain.com`, `www.your-domain.com`)"
  traefik.http.routers.flowpulse.entrypoints: "websecure"
  traefik.http.routers.flowpulse.tls: "true"
  traefik.http.routers.flowpulse.tls.certresolver: "letsencrypt"
  traefik.http.services.flowpulse.loadbalancer.server.port: "80"

env:
  secret:
    - RAILS_MASTER_KEY
  clear:
    SOLID_QUEUE_IN_PUMA: true

volumes:
  - "flowpulse_v_5_storage:/rails/storage"

asset_path: /rails/public/assets

builder:
  arch: amd64
```

**File di configurazione Traefik:**

Crea `/mnt/flowpulse/traefik/traefik.yml` sul server:

```yaml
# traefik.yml

api:
  dashboard: true
  insecure: false

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entrypoint:
          web:
            to: websecure
            scheme: https
  websecure:
    address: ":443"

certificatesResolvers:
  letsencrypt:
    acme:
      email: your-email@example.com
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web

providers:
  docker:
    endpoint: unix:///var/run/docker.sock
    exposedByDefault: false
    network: default

  file:
    filename: /traefik.yml
    watch: true
```

---

## Confronto Opzioni

| Aspetto | Opzione A (Built-in) | Opzione B (Esplicito) |
|--------|:-----------:|:-----------:|
| **Semplicità** | ⭐⭐⭐ | ⭐ |
| **Controllo** | ⭐ | ⭐⭐⭐ |
| **SSL/LE** | Automatico | Automatico |
| **Dashboard** | No | Sì |
| **Setup** | 2 righe | Più file config |
| **Troubleshooting** | Facile | Complesso |

**✅ Per il tuo progetto consiglio OPZIONE A (Built-in)**

---

## STEP 4: Preparazione DNS

### 4.1 Registra Dominio e Punta a Hetzner

1. Registra il dominio su registrar (Namecheap, GoDaddy, etc.)
2. Aggiorna nameserver o A record per puntare a Hetzner IP:

```
A record: @ → <HETZNER_IP>
A record: www → <HETZNER_IP>
```

3. Verifica propagazione DNS:
```bash
nslookup your-domain.com
# Dovrebbe mostrare HETZNER_IP
```

---

## STEP 5: Rails Configuration per HTTPS

Quando usi il proxy built-in di Kamal (Opzione A), devi configurare Rails:

### 5.1 Aggiorna `config/environments/production.rb`

```ruby
# config/environments/production.rb

# ✅ QUESTE DUE RIGHE SONO ESSENZIALI CON PROXY SSL
config.force_ssl = true
config.assume_ssl = true

# HSTS headers (facoltativo, ma consigliato)
config.ssl_options = { hsts: { subdomains: true } }
```

---

## STEP 6: Setup Secrets Localmente

### 6.1 Crea `~/.kamal/secrets`

```bash
mkdir -p ~/.kamal

# Crea file secrets
cat > ~/.kamal/secrets << 'EOF'
# Rails master key (copia da config/master.key)
RAILS_MASTER_KEY=<content_of_config/master.key>

# GitHub Container Registry
KAMAL_REGISTRY_PASSWORD=<your_github_pat_token>
EOF

# Proteggi file
chmod 600 ~/.kamal/secrets
```

### 6.2 Scopri il RAILS_MASTER_KEY

```bash
cat config/master.key
# Copia l'output nel file ~/.kamal/secrets
```

---

## STEP 7: Deploy Iniziale

### 7.1 Prepara Config Finale

Aggiorna `config/deploy.yml` con i tuoi valori:

```yaml
service: flowpulse_v_5
image: flowpulse_v_5

servers:
  web:
    - <HETZNER_IP_EFFETTIVO>

registry:
  server: ghcr.io
  username: <tuo-username-github>
  password:
    - KAMAL_REGISTRY_PASSWORD

# ✅ PROXY CON SSL
proxy:
  ssl: true
  host: your-domain.com

env:
  secret:
    - RAILS_MASTER_KEY
  clear:
    SOLID_QUEUE_IN_PUMA: true

volumes:
  - "flowpulse_v_5_storage:/rails/storage"

asset_path: /rails/public/assets

builder:
  arch: amd64
```

### 7.2 Valida Configurazione

```bash
# Verifica che deploy.yml sia valido
bin/kamal config cat

# Verifica connessione SSH
bin/kamal app exec "echo 'SSH OK'"
```

### 7.3 Deploy

```bash
# Build immagine Docker e push a GHCR
bin/kamal build

# Deploy su Hetzner
bin/kamal deploy

# Verifica status
bin/kamal status

# Leggi log
bin/kamal logs -f
```

### 7.4 Verifica SSL

```bash
# Dopo ~2-3 minuti, controlla HTTPS
curl -v https://your-domain.com

# Verifica certificato valido
openssl s_client -servername your-domain.com -connect your-domain.com:443 < /dev/null 2>/dev/null | openssl x509 -noout -dates
```

---

## STEP 8: Comandi Utili

```bash
# View app logs in real time
bin/kamal logs -f

# Shell interattivo sul container
bin/kamal app exec --interactive "bash"

# SSH sul server
bin/kamal app shell

# Console Rails
bin/kamal console

# Restart app (rileggi config, no rebuild)
bin/kamal app restart

# Stop
bin/kamal app stop

# Rollback a versione precedente
bin/kamal app rollback

# Accesso alle directory log
bin/kamal app ssh "tail -f /rails/log/production.log"
```

---

## Troubleshooting

### SSL Non Funziona / Certificato Scaduto

```bash
# Verifica che dominio sia raggiungibile via HTTP
curl -v http://your-domain.com

# Se vedi redirect a HTTPS, buon segno
# Se no, verifica DNS: nslookup your-domain.com

# Controlla log Kamal
bin/kamal logs -f | grep -i ssl
```

### App Non Raggiungibile

```bash
# Verifica che Traefik (proxy) stia girando
bin/kamal app exec "curl localhost:3000"

# Controlla port forward
ssh root@<HETZNER_IP> "netstat -tlnp | grep -E '80|443'"

# Controlla rete Docker
bin/kamal app exec "ip route"
```

### Database Connection Error

Se usi SQLite sul volume:
```bash
# Verifica che il volume sia montato
bin/kamal app exec "ls -lh /rails/storage"

# Se non vedi il file DB, probabile primo deploy
# Aspetta che le migrazioni completino: bin/kamal logs -f
```

### Secrets Non Caricati

```bash
# Verifica che ~/.kamal/secrets esista
ls -la ~/.kamal/secrets

# Verifica contenuto
cat ~/.kamal/secrets

# Verifica che RAILS_MASTER_KEY sia definito
bin/kamal config cat | grep RAILS_MASTER_KEY
```

---

## Checklist Finale

Deployment Hetzner + Kamal + SSL/Let's Encrypt:

- [ ] Server Hetzner creato (CPX21, Ubuntu 24.04 LTS)
- [ ] Docker installato e funzionante su server
- [ ] Dominio registrato e DNS puntato a Hetzner IP
- [ ] DNS propagato (verifica con `nslookup`)
- [ ] GitHub PAT token generato e salvato in `~/.kamal/secrets`
- [ ] RAILS_MASTER_KEY in `~/.kamal/secrets`
- [ ] `config/environments/production.rb` con `force_ssl` e `assume_ssl`
- [ ] `config/deploy.yml` completo con dominio e IP server
- [ ] `bin/kamal config cat` visualizza correttamente la config
- [ ] SSH a server funziona (`bin/kamal app exec "echo OK"`)
- [ ] Build immagine completato (`bin/kamal build`)
- [ ] Deploy completato (`bin/kamal deploy`)
- [ ] App raggiungibile via HTTPS (`curl https://your-domain.com`)
- [ ] Certificato SSL valido (verifica con openssl s_client)
- [ ] Assets caricano correttamente
- [ ] Log raggiungibili (`bin/kamal logs`)
- [ ] Rollback funziona (`bin/kamal app rollback`)

---

## Prossimi Step

Una volta che produzione gira stabile:

- [ ] Setup monitoring (Prometheus + Grafana su server o esterno)
- [ ] Backup database/storage (s3, backblaze, ssh backup)
- [ ] SSL certificate auto-renewal monitor
- [ ] Logging e syslog aggregation
- [ ] CDN con Cloudflare per static assets
- [ ] Performance monitoring (New Relic, DataDog)
- [ ] Uptime monitoring (Pingdom, Statuspage)
