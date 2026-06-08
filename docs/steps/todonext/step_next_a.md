# Step 0005 - Protezione leggera da scanner automatici

## Obiettivo

Aggiungere una protezione minima contro traffico automatico e scansioni comuni, senza rendere il sistema rigido o difficile da debuggare.

Questo step non e urgente rispetto a domini, deploy e pagine pubbliche, ma diventa utile quando Flowpulse resta esposto stabilmente su piu domini.

## Perche

Nei log di produzione compaiono richieste automatiche verso path non usati dall'app, per esempio:

- `/telescope/requests`
- `/info.php`
- `/actuator/env`
- `/swagger-ui.html`
- `/swagger.json`
- `/.vscode/sftp.json`
- `/?rest_route=/wp/v2/users/`

La app risponde correttamente con 404 nella maggior parte dei casi. Il problema principale e ridurre rumore nei log e impedire che traffico palesemente inutile arrivi fino ai controller Rails.

## Soluzione proposta

Valutare `rack-attack` con configurazione piccola e prudente.

Regole iniziali:

- bloccare path scanner ovvi:
  - `/.env`
  - `/.git`
  - `/.vscode`
  - `/wp-admin`
  - `/wp-login.php`
  - `/xmlrpc.php`
  - `/info.php`
  - `/telescope`
  - `/actuator`
  - `/swagger`
  - `/webjars/swagger`
  - `/api-docs`
  - `/debug`
- bloccare query WordPress sulla root:
  - `?rest_route=/wp/v2/users/`
- aggiungere rate limit leggero per IP.
- valutare rate limit piu stretto su login/admin.

## Cosa evitare per ora

- Non bloccare user-agent specifici come prima regola.
- Non creare una blacklist troppo lunga.
- Non trasformare questo step in una configurazione security complessa.
- Non bloccare path o query che potrebbero servire a Flowpulse in futuro senza controllo.

## Criteri di completamento

- `rack-attack` aggiunto al Gemfile.
- Middleware abilitato.
- Initializer con poche regole leggibili.
- Risposta ai path bloccati con 404 semplice.
- Rate limit base verificato.
- Nessun impatto su:
  - root domini pubblici
  - `/admin`
  - login
  - `/up`
  - asset pubblici

## Comandi di verifica futuri

```bash
curl -I https://flowpulse.net/info.php
curl -I "https://flowpulse.net/?rest_route=/wp/v2/users/"
curl -I https://flowpulse.net/up
```

Risultato atteso:

- scanner path: 404 leggero
- healthcheck `/up`: 200
- pagine pubbliche reali: 200 o redirect atteso
