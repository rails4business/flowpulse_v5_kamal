# Costruire l'immagine sul server (builder remoto di Kamal)

## Il problema

Con il builder locale ogni `kamal deploy`:

1. costruisce l'immagine sul Mac (arm64) per il server (amd64), quindi **in emulazione**, lentamente;
2. carica l'immagine (centinaia di MB) su `ghcr.io` **dalla connessione di casa**: circa 15 minuti;
3. il server la scarica da `ghcr.io` e la avvia.

Se la connessione cade durante il caricamento il deploy fallisce, ad esempio:

```
failed to push ghcr.io/rails4business/flowpulse_v5_kamal:…: broken pipe
failed to fetch oauth token: … lookup ghcr.io: no such host
```

## La soluzione: builder remoto

Il Mac manda via SSH solo il codice (il "build context", circa 6 MB); il server Hetzner
costruisce l'immagine nativamente (amd64), la carica su `ghcr.io` dal datacenter in pochi
secondi e la avvia senza doverla riscaricare.

In `config/deploy.yml`:

```yaml
builder:
  arch: amd64
  context: .
  remote: ssh://root@178.105.106.247
```

Il comando resta `kamal deploy`. Il codice parte sempre dalla cartella locale
(`context: .`), comprese le modifiche non committate.

## Requisiti

- Accesso SSH come `root` al server (lo stesso che Kamal usa già per il deploy).
- Docker sul server (installato da Kamal).
- Memoria libera per la build (gem e asset): 2–4 GB. Verifica:

  ```
  bin/kamal server exec "free -h"
  ```

  Al 23/11/2026: 3,7 GB totali, 2,6 GB disponibili, nessuno swap.

## Cose da sapere

- **Primo deploy più lento**: la cache di build sul server parte vuota; dal secondo è veloce.
- **Carico sul server**: per qualche minuto, durante la build, il sito può essere un po' più lento.
- **Spazio su disco**: la cache di build cresce; ogni tanto si può pulire:

  ```
  bin/kamal server exec "docker builder prune -f"
  ```

- **Se Kamal segnala che il builder non corrisponde** alla configurazione:

  ```
  bin/kamal build remove
  kamal deploy
  ```

## Swap consigliato

Il server non ha swap: se la build esaurisce la RAM il sistema può chiudere un processo
(anche il database). Uno swap da 2 GB fa da paracadute (una volta sola):

```
bin/kamal server exec "fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile && echo '/swapfile none swap sw 0 0' >> /etc/fstab"
```

## Tornare al builder locale

Togliere la riga `remote:` da `config/deploy.yml` (e, se serve, `bin/kamal build remove`).

## Alternativa: build con GitHub Actions

La repository è su GitHub: si può far costruire e caricare l'immagine da GitHub Actions a
ogni push sul ramo principale, lasciando a Kamal solo l'avvio della nuova versione.
È più automatico ma richiede più configurazione (segreti nel workflow, `kamal deploy --skip-push`).
