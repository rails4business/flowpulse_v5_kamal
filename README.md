# FlowPulse

FlowPulse è una piattaforma Rails multi-brand: permette a persone e creator di
costruire il proprio mondo attraverso Brand, progetti, persone e contenuti, e di
collegarlo ai mondi degli altri.

Sulla stessa applicazione girano più siti e domini, tra cui
[flowpulse.net](https://flowpulse.net), GeneraImpresa, PosturaCorretta e
Radiestesia e Benessere. L'ecosistema MarkPostura è il primo esempio d'uso, non
il confine della piattaforma.

## Stack

- Ruby 4.0.9, Rails 8.1
- PostgreSQL in sviluppo e produzione; SQLite solo per i test
- Hotwire (Turbo e Stimulus), importmap, Tailwind CSS
- Solid Queue, Solid Cache e Solid Cable
- Action Text con l'editor Lexxy, Active Storage con libvips
- Deploy con Kamal e Thruster

## Avvio in locale

Prerequisiti: Ruby 4.0.9 (vedi `.ruby-version`), PostgreSQL in esecuzione e
libvips per l'elaborazione delle immagini.

```bash
git clone https://github.com/rails4business/flowpulse_v5_kamal.git
cd flowpulse_v5_kamal
bin/setup
```

`bin/setup` installa le gem, prepara il database e avvia `bin/dev`, che lancia
il server Rails e Tailwind in modalità watch. L'applicazione è su
<http://localhost:3000>.

Per avviarla in seguito basta `bin/dev`. Con `bin/setup --skip-server` si
prepara l'ambiente senza avviare il server.

## Test e controlli

```bash
bin/rails test           # test
bin/rails test:system    # test di sistema
bin/ci_checks            # gli stessi controlli della CI (brakeman, bundler-audit, importmap audit, rubocop, test)
bin/ci_checks --quick    # solo scan e lint
```

## Domini e brand

I domini serviti dall'applicazione sono configurati in `config/domains.yml`:
per ogni host si definiscono il brand o nodo di riferimento, la lingua,
l'accesso, i metadati del sito e la pagina di destinazione. Lo stesso file
determina gli host attivi in produzione.

## Contenuti

Parte dei contenuti (brand, nodi, corsi, testi) nasce da file `.yml` e `.md`
nella cartella `docs/` e viene importata nel database. La produzione è la fonte
di verità; i file restano nel repository come sorgente e archivio dei
contenuti.

## Deploy

Il deploy in produzione è manuale, con Kamal, ed è riservato al maintainer.
Le regole su credenziali e deploy sono in [CONTRIBUTING.md](CONTRIBUTING.md).

## Contribuire

Le proposte sono benvenute. Prima di aprire una pull request leggi
[CONTRIBUTING.md](CONTRIBUTING.md).

## Licenza

Copyright (C) 2026 Marco Beffa, progetto rails4business.

Distribuito con licenza [GNU Affero General Public License v3.0](LICENSE)
(AGPL-3.0). Puoi usare, modificare e ridistribuire il codice; se fai girare una
versione modificata come servizio accessibile in rete, devi renderne
disponibile il codice sorgente con la stessa licenza.
