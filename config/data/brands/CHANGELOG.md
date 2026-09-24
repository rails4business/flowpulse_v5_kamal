# Changelog dei Brand

Ogni dominio mantiene il proprio changelog nella cartella del Brand:

```text
config/data/brands/<brand>/changelog/
├── index.yml
└── entries/
    └── YYYY-MM-DD-slug.md
```

`index.yml` contiene identità del Brand, domini riconosciuti e metadati delle voci. I dettagli restano in Markdown dentro `entries/`.

## Regole

- Una modifica ha un solo proprietario e un solo file Markdown.
- `processi`, `calendari`, `contenuti` e concetti simili sono tag, non falsi Brand.
- Una modifica condivisa appartiene al Brand o alla piattaforma che la governa; gli altri documenti possono collegarla, ma non copiarla.
- Le voci `internal` sono visibili soltanto al superadmin. Non devono comunque contenere segreti o dati personali.
- Correzioni tipografiche e refactoring invisibili non richiedono una voce.

## Campi di una voce

```yaml
- slug: chiave-stabile
  date: "2026-09-24"
  title: Titolo leggibile
  summary: Sintesi breve
  kind: platform | architecture | feature | fix
  visibility: public | internal
  tags: [calendari, servizi]
  source: entries/2026-09-24-chiave-stabile.md
```

## URL

- `/changelog` mostra il registro del dominio corrente;
- `/changelog/aggiornamenti/<slug>` mostra una voce dello stesso dominio;
- in locale `/changelog/<brand>` permette di controllare un Brand specifico.

`flowpulse.net/changelog` mostra soltanto gli aggiornamenti di Flowpulse e, in una sezione distinta, collega i registri degli altri domini. Su ciascun dominio `/changelog` mostra esclusivamente la cronologia del relativo Brand. Quando una modifica coinvolge più progetti, la voce rimane nel registro del proprietario e nomina esplicitamente i collegamenti, senza duplicare il Markdown.
