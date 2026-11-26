# FlowPulse

FlowPulse è una piattaforma per dare forma al proprio mondo attraverso Brand,
progetti, persone e strumenti, e collegarlo ai mondi costruiti dagli altri.

Una sola applicazione Rails serve più domini (FlowPulse, MarkPostura,
PosturaCorretta, …): ogni dominio è collegato a un Node e ha il proprio
contesto di autenticazione. La configurazione dei domini è in
`config/domains.yml`.

## Stack

- Ruby 4.0.9 (`.ruby-version`)
- Rails 8.1
- PostgreSQL
- Hotwire (Turbo, Stimulus) con import maps
- Tailwind CSS (`tailwindcss-rails`)
- Solid Cache, Solid Queue e Solid Cable
- Deploy con Kamal su server Hetzner

## Requisiti di sistema

- Ruby nella versione indicata in `.ruby-version`
- PostgreSQL in esecuzione in locale
- `libvips` per l'elaborazione delle immagini

## Configurazione locale

Il database si configura con variabili d'ambiente (vedi `config/database.yml`);
tutte hanno un valore predefinito per lo sviluppo:

| Variabile           | Predefinito                    |
|---------------------|--------------------------------|
| `DB_HOST`           | `localhost`                    |
| `DB_PORT`           | `5432`                         |
| `DB_NAME`           | `flowpulse_v_5_development`    |
| `DB_NAME_TEST`      | `flowpulse_v_5_test`           |
| `DB_USERNAME`       | utente corrente                |
| `POSTGRES_PASSWORD` | nessuna                        |

Installazione, preparazione del database e avvio:

```bash
bin/setup               # bundle install, db:prepare, pulizia log; poi avvia bin/dev
bin/setup --skip-server # come sopra, senza avviare il server
bin/dev                 # server Rails + watcher Tailwind (Procfile.dev)
```

Installa anche il hook Git del repository (vedi [CONTRIBUTING](CONTRIBUTING.md)):

```bash
git config core.hooksPath scripts
```

## Test

I test sono divisi in due gruppi (`lib/tasks/test_suites.rake`):

```bash
bin/rails db:test:prepare test:indispensabili  # quelli eseguiti in CI
bin/rails test:contenuti                       # test lenti di contenuti e cataloghi, a mano
bin/rails test:system                          # test di sistema, a mano
bin/rails test test/controllers/sessions_controller_test.rb  # un singolo file
```

I test `contenuti` reimportano i cataloghi YAML a ogni test: vanno lanciati
quando cambiano cataloghi, corsi, Node, linee o metro map.

Per eseguire in locale tutti i controlli della CI (Brakeman, bundler-audit,
importmap audit, RuboCop, test e test di sistema):

```bash
bin/ci_checks          # tutto
bin/ci_checks --quick  # solo scansioni e lint
```

## Integrazione continua

La CI (`.github/workflows/ci.yml`) gira su ogni pull request e su ogni push su
`main` con quattro job:

- `scan_ruby`: Brakeman e bundler-audit
- `scan_js`: `bin/importmap audit`
- `lint`: RuboCop
- `test`: `bin/rails db:test:prepare test:indispensabili` su PostgreSQL 17

## Deploy

Il deploy è manuale, con Kamal (`config/deploy.yml`), e parte soltanto dalla
cartella principale del progetto, dove si trovano i file locali delle
credenziali (`config/master.key`, `.kamal/secrets`), che non vanno mai
versionati.

```bash
bin/kamal deploy
bin/kamal console   # console Rails in produzione
bin/kamal logs      # log dell'applicazione
```

Gli host serviti vengono letti da `config/domains.yml`.

## Documentazione

- [CONTRIBUTING](CONTRIBUTING.md): flusso di lavoro, Dependabot e credenziali
- `docs/rails-hetzner-deploy/`: guida completa a server, Kamal e deploy
- `docs/appunti/DEPENDABOT_E_CREDENZIALI_KAMAL.md`: procedura Dependabot e credenziali Kamal
- `docs/backup_database.md`: backup settimanale del database di produzione
- `docs/aggiungere-dominio-flowpulse.md`: come aggiungere un dominio
- `docs/architettura_imprenditori_profili_brand.md`: architettura di profili, Brand e accessi
