# Materiale editoriale comune dei Brand

## Decisione

Le pagine statiche restano organizzate per **dominio** in `config/data/sites`:
qui vivono host, lingua, tema, nav, footer e componenti della landing.

Il materiale che un Brand possiede e può mostrare anche su un altro dominio vive
invece sotto `config/data/brands/<brand_slug>`. Un Brand è un Node; un dominio
è il suo punto di accesso pubblico. Un Brand può avere più domini, mentre un
dominio non diventa proprietario di corsi, articoli o libri.

```text
Domain/site                         Brand editoriale
posturacorretta.org (it)            posturacorretta
  └── tema + nav + landing            ├── courses
                                      ├── contents
                                      ├── docs
                                      ├── books
                                      └── operations (quando serve)
```

Un Brand può inoltre avere strutture proprie: per PosturaCorretta oggi sono il
Percorso educativo e il Programma lezioni.

## Quattro entità comuni

1. **Corsi e capitoli** — catalogo YAML, con testi in Markdown.
2. **Contenuti** — articoli e materiali datati, sempre collegabili a un
   calendario in futuro. Un video non e' un'entita editoriale autonoma: e'
   media di un articolo, di un capitolo, di una Doc o di un capitolo di libro.
3. **Docs** — documentazione stabile, linee guida e istruzioni. Nella UI può
   essere chiamata “Guida”, ma nel sistema resta `docs` per non confonderla con
   un percorso.
4. **Libri** — metadati e indice YAML, con capitoli Markdown.

“Corsi e capitoli” è una sola entità editoriale: il corso è il contenitore, il
capitolo è l'unità leggibile. Una scheda pratica è un capitolo pratico.

Il **Percorso educativo PosturaCorretta** resta per ora una struttura specifica
del Brand: è un indice YAML `Section → Corso`. In futuro un Brand potrà averne
più di uno, con regole e parole proprie; per questo non viene ancora imposto
come modulo comune.

Il **Programma lezioni** resta anch'esso specifico di PosturaCorretta: descrive
lezioni in presenza con insegnante, svolgibili in gruppo o individualmente, e
diventerà la dima di Cycle → DataSession → DataSlot. Insegnanti e centri
restano sotto `posturacorretta/accademia`.

## Struttura canonica dei file

La cartella parte sempre dal Brand, mai dall'estensione del dominio:

```text
config/data/brands/<brand_slug>/
  editorial.yml
  courses/
  contents/
  docs/
    01_conoscere-il-progetto/
    02_...
  books/
    <book_slug>/
      book.yml
      index.yml
      chapters/
  operations/                 # opzionale e specifica del Brand
```

Un file Markdown puo' dichiarare i propri media nel frontmatter, senza creare
una cartella `videos/` separata:

```yaml
title: Titolo del contenuto
published_at: 2026-09-19T09:00:00+02:00
videos:
  - provider: youtube
    id: esempio
```

La numerazione delle cartelle `docs` serve a ordinare le istruzioni e a capire
rapidamente a quale Brand appartengono prima di una futura migrazione. I file
globali in `config/data/books` restano solo una compatibilita temporanea: ogni
libro nuovo o migrato va nella cartella `books/` del Brand proprietario.

## Autore e Brand pubblicatore

Un professionista puo' essere autore senza essere il Brand che pubblica. I
metadati del libro o del singolo Markdown mantengono entrambi i riferimenti:

```yaml
author: Mark Postura
author_node_slug: markpostura
author_path: /markpostura
publisher_node_slug: posturacorretta
publisher_name: PosturaCorretta
publisher_path: /posturacorretta
```

Un contenuto destinato solo a MarkPostura usa `markpostura` in entrambi i ruoli;
uno scritto da Mark per PosturaCorretta mantiene invece autore e pubblicatore
distinti. Gli indici di libri e corsi restano separati: quando saranno rivisti,
ogni categoria avra' il proprio Markdown e non una copia tecnica identica.

## Confini tra Brand

Una Doc appartiene a un solo Brand. In particolare, **Come funziona il Percorso
Integrato** appartiene a `percorso-integrato/docs`, con URL e navigazione propri:
non deve comparire come sezione, voce o rimando editoriale di PosturaCorretta.
I vecchi URL PosturaCorretta potranno soltanto ricevere un redirect tecnico al
nuovo indirizzo del Percorso Integrato, senza mantenere una pagina duplicata.

## Registro iniziale

Ogni Brand adotta un solo file:

```text
config/data/brands/<brand_slug>/editorial.yml
```

Il registro dichiara le sorgenti già attive senza duplicarle. Per ciascun
blocco indica `id`, `kind`, `source`, `status`, `visibility` e note di
migrazione. Il primo è:

```text
config/data/brands/posturacorretta/editorial.yml
```

Questo rende subito visibili materiali pubblici, interni, bozze e archivi;
permette inoltre di confrontare file equivalenti prima di spostarli.

## Pubblicazione

La visibilità non dipende soltanto dalla cartella:

```yaml
status: draft | scheduled | published | archived
visibility: private | internal | public
published_at: 2026-09-21T09:00:00+02:00 # quando necessario
```

Le cartelle `drafts` e `archive` possono aiutare l'ordine umano, ma il loader
deve sempre applicare i metadati. In questo modo una bozza non diventa pubblica
per errore perché è stata spostata, e un archivio resta rintracciabile.

## Regole pratiche per lavorare a mano sui Markdown

Puoi aggiungere e modificare testi direttamente nei file `.md`. Per non
confondere le quattro entità, applica queste regole:

1. Una **scheda pratica** va sempre in
   `courses/<corso>/chapters/` ed è un capitolo con `chapter_type: practical`;
   non va in `contents/`.
2. Un **articolo pubblico** va in `contents/<slug>/content.md`, con il suo
   `content.yml` nella stessa cartella.
3. Una **istruzione stabile** va in `docs/<numero-sezione>/`; un **libro** va
   in `books/<libro>/chapters/`.
4. Non spostare o rinominare un file già collegato da un YAML: prima aggiorna
   il relativo `content_path`, `course.yml`, `indice.yml` o `content.yml`.
5. Non duplicare lo stesso Markdown in due Brand: se il testo cambia per
   pubblico o finalità, crea una versione editoriale propria; se è solo un
   richiamo, collega l'originale.

Per un nuovo capitolo di corso, il lavoro manuale minimo è:

```text
1. creare courses/<corso>/chapters/<slug>.md
2. aggiungere il capitolo nel course.yml dello stesso corso
3. indicare id, parent_id, slug, position, chapter_type, status,
   visibility, access e content_path
4. lasciare status: draft finché non è pronto
```

Per un nuovo articolo, invece:

```text
1. creare contents/<slug>/content.md
2. creare contents/<slug>/content.yml con slug, titolo, stato e data
3. aggiungere l'indice pubblico solo quando l'articolo è pronto
```

## Migrazione graduale

1. Censire le sorgenti nel registro del Brand.
2. Confrontare i doppioni e scegliere una sorgente canonica.
3. Spostare un blocco alla volta sotto `config/data/brands/<brand>/...`.
4. Aggiornare il repository/loader che lo legge.
5. Conservare redirect e riferimenti finché il nuovo rendering non è verificato.

Per i corsi, durante la transizione, il catalogo storico può restare in uso:
un `courses/<course_slug>/course.yml` canonico sostituisce soltanto le voci con
gli stessi `id`. Questo permette a ogni corso di avere indice e Markdown propri
prima di migrare il catalogo completo.

Non si crea ora una tabella database: l'architettura `Content → DataSession →
DataSlot → DataCommitment` resta disciplinata dal documento principale
`ARCHITETTURA_CICLI_CONTENUTI_E_SERVIZI.md`.
