# Dal NodeEvent alla scheda Markdown

## Lavorare in production senza perdere la storia

Quando un progetto viene costruito davvero, le decisioni non nascono tutte prima del deploy. Alcune arrivano mentre si prova una funzione, si apre un nuovo nodo o si scopre che il piano iniziale non funziona come previsto.

Per questo in FlowPulse servono due luoghi diversi:

- il **database di production**, dove registrare ciò che sta succedendo;
- il **repository**, dove conservare la documentazione consolidata e ricostruibile.

Il collegamento tra i due è il `NodeEvent`.

## Sul nodo rimane la visione generale

Un `Node` identifica una parte stabile del Brand: per esempio il percorso online di PosturaCorretta. Sul nodo rimane la **visione generale**.

La visione spiega che cosa stiamo costruendo, perché esiste e quale direzione deve mantenere. Insieme a essa conserviamo nome, posizione nell'albero, stato e processi. Non è un elenco delle modifiche e non deve essere riscritta a ogni fix.

La visione generale risponde a domande semplici:

> Che cos'è questo nodo? Dove vuole arrivare?

Il lavoro necessario per arrivarci viene registrato nei NodeEvent.

## Nel NodeEvent nasce la scheda di sviluppo

Quando il nodo viene creato, FlowPulse genera l'evento `Creato`. In seguito si possono aggiungere eventi come:

- `Avviato`, quando comincia il lavoro reale;
- `Update`, quando cambia o avanza una parte del progetto;
- `Fix`, quando viene corretto un problema;
- `Consolidato`, quando il progetto raggiunge una forma stabile;
- `Troncato` e `Ripreso`, quando un tentativo viene interrotto o rimesso in movimento.

Ogni evento può contenere un titolo breve, una nota, una **scheda di sviluppo Markdown** e il suo slug.

La scheda nasce nel database di production, dentro il NodeEvent. Può contenere obiettivo, decisioni, cose da fare, verifiche e appunti necessari per lo sviluppo. Non bisogna preparare subito un secondo documento nel repository.

## Dalla scheda nel database alla copia versionata

Il ciclo operativo è questo:

```text
Nodo
→ NodeEvent in production
→ scheda di sviluppo Markdown nel database
→ lavoro pronto per essere implementato
→ copia Markdown nel repository
→ commit e deploy
→ collegamento automatico tramite slug
```

Non ogni evento deve arrivare nel repository. Un piccolo fix può restare soltanto nel database. Quando la scheda serve per implementare, revisionare o ricostruire il lavoro, viene copiata in un file Markdown mantenendo lo stesso slug.

## Scegliere prima lo slug

Nel NodeEvent si indica lo slug della scheda, anche se la sua copia non è ancora presente nel repository o nel deploy.

Esempio:

```text
posturacorretta-percorso-online
```

Finché il file non esiste, FlowPulse mostra lo slug come **Markdown atteso**. Dopo aver copiato la scheda nel repository con lo stesso slug e aver effettuato il deploy, il collegamento diventa apribile.

Il NodeEvent resta l'origine del lavoro; il file è la sua versione conservata in Git e utilizzata durante lo sviluppo.

## Copiare la scheda nel repository

Per PosturaCorretta il corpo Markdown del NodeEvent può essere copiato in:

```text
config/data/brands/posturacorretta/development/entries/
2026-10-01-percorso-online.md
```

La scheda va poi registrata in:

```text
config/data/brands/posturacorretta/development/index.yml
```

con lo stesso slug inserito nel NodeEvent:

```yaml
- slug: posturacorretta-percorso-online
  owner_brand: posturacorretta
  node_slug: posturacorretta-percorso-online
  title: Attivare il percorso online PosturaCorretta
  summary: Iscrizione, accesso, avanzamento e pubblicazione.
  status: in_progress
  started_on: "2026-10-01"
  updated_on: "2026-10-01"
  source: entries/2026-10-01-percorso-online.md
```

Dopo commit e deploy, l'evento ritrova la propria copia attraverso `development_entry_slug`.

## Che cosa conserva lo YAML dei nodi

Lo snapshot:

```text
config/data/brands/posturacorretta/nodes.yml
```

serve a ricostruire la struttura del Brand. Conserva nodi, gerarchia, descrizioni, stato e ponti.

Non contiene la cronologia dei NodeEvent, gli utenti, i permessi o tutto ciò che vive nel database. Per questi dati continua a essere necessario il backup PostgreSQL.

Il comando:

```bash
bin/rails brand_nodes:export BRAND=posturacorretta
```

esporta quindi la mappa dei nodi, non le note Markdown degli eventi.

## Production, repository e deploy hanno ruoli diversi

Possiamo riassumere così:

| Luogo | Che cosa conserva |
|---|---|
| Node | Visione generale, posizione nell'albero, stato e processi |
| Database di production | NodeEvent con schede di sviluppo, persone e cronologia reale |
| `nodes.yml` | Struttura ricostruibile dei nodi del Brand |
| Schede Markdown | Copie versionate dei NodeEvent usate per lo sviluppo |
| Repository Git | Versioni, confronto delle modifiche e distribuzione |

Si scrive la scheda in production perché è lì che il progetto vive. Si porta nel repository quando deve guidare un'implementazione o rimanere nella storia del codice. Il deploy rimette quella copia accanto all'evento da cui era partita.

Così il lavoro quotidiano non deve aspettare il documento perfetto, e il documento non diventa un archivio scollegato da ciò che è successo davvero.
