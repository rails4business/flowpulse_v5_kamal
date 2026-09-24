# Censimento materiale PosturaCorretta

> Rilevazione iniziale: non eliminare o spostare file da questa lista senza
> aggiornare prima il relativo loader e verificare la vista pubblica.

## Sorgenti canoniche attuali

| Entità | Sorgente canonica | Uso corrente |
| --- | --- | --- |
| Percorso educativo PosturaCorretta | `config/data/posturacorretta/contenuti/percorso.yml` | Indice educativo specifico della home |
| Corsi → Capitoli | `config/data/brands/posturacorretta/courses/<course_slug>/course.yml` | Sorgente canonica dell'Accademia: ogni corso contiene teoria e schede pratiche in `chapters/`; `contents.yml` resta soltanto indice di compatibilità |
| Corso *Inizia con PosturaCorretta* | `config/data/brands/posturacorretta/courses/inizia-con-posturacorretta/` | Primo corso migrato: indice e capitoli autonomi |
| Contenuto *Consapevolezza e coscienza corporea* | `config/data/brands/posturacorretta/contents/consapevolezza-e-coscienza-corporea/` | Primo articolo migrato: `content.yml` più Markdown; conserva lo slug pubblico storico |
| Indice didattico dettagliato | `config/data/posturacorretta/accademia/posturacorretta_percorso.yml` | Lettura di corsi/capitoli in `Posturacorretta::LearningController` |
| Programma lezioni | `config/data/posturacorretta/programmi/programma_lezioni_posturacorretta.yml` | Ordine didattico, individuale o gruppo |
| Docs PosturaCorretta | `config/data/posturacorretta/guide/indice.yml` + Markdown | Documentazione propria di PosturaCorretta; non contiene il Percorso Integrato |
| Programma lezioni | `config/data/posturacorretta/programmi/programma_lezioni_posturacorretta.yml` | Lezioni in presenza, gruppo o individuali |
| Libro *PosturaCorretta in un mese* | `config/data/brands/posturacorretta/books/postura-corretta-in-un-mese/` | Libro pubblicato, sorgente canonica del Brand |
| Libro *Il corpo, un mondo da scoprire* | `config/data/books/il-corpo-un-mondo-da-scoprire/` | Libro pubblicato, da migrare successivamente sotto il Brand proprietario |

## File simili, ma non duplicati funzionali

| Sorgente | Perché non va rimossa ora | Decisione |
| --- | --- | --- |
| `posturacorretta/percorso/percorso.yml` | Alimenta ancora una vista di orientamento/guida in `Brands::PosturacorrettaController`; non è l'indice didattico della home. | Tenere separato; rinominare solo quando la sua pagina sarà riprogettata. |
| `posturacorretta/accademia/percorso_didattico_full.yml` | Non risulta letto dal controller. Non contiene 47 lezioni reali, ma 11 moduli storici del primo mese. | Tenerlo in audit: i suoi testi restano utili come capitoli del corso introduttivo, ma non è il Programma lezioni. |
| `posturacorretta/accademia/posturacorretta_percorso.yml` | Sembra vicino a `contents.yml`, ma è ancora letto dall'attuale lettore dei corsi. | Tenerlo finché il lettore non usa direttamente il catalogo comune. |

## Copie tecniche certe

Queste copie hanno lo stesso hash del file corrispondente in `chapters/` e
non sono richiamate dal libro pubblicato:

```text
config/data/books/il-corpo-un-mondo-da-scoprire/chapters copy/
  001-section-parte-1-di-cosa-parleremo-in-questo-libro.md
  002-chapter-il-tuo-corpo-ti-accompagna-ogni-giorno.md
  003-chapter-quando-perdi-la-salute.md
  004-chapter-creare-un-percorso-integrato.md
  005-chapter-la-postura-come-punto-d-ingresso.md
  006-chapter-la-guerra-dell-attenzione.md
```

Altre copie/storici da non mostrare come sorgenti editoriali:

```text
config/data/books/il-corpo-un-mondo-da-scoprire/old_chapters_20260715/
config/data/books/old-il-corpo-un-mondo-da-scoprire/
config/data/posturacorretta/guide/01_primo_mese/01_errori copy.md
config/data/posturacorretta/guide/01_primo_mese/00_ultima_sconfitta copy.md
config/data/posturacorretta/taxonomies copy.yml
config/data/books/test-hidden-book/
```

## Ordine sicuro di pulizia

1. Il confronto tra `percorso_didattico_full.yml` e
   `programma_lezioni_posturacorretta.yml` è stato eseguito: il primo ha 11
   moduli del primo mese, il secondo 36 lezioni operative. Non vanno fusi
   riga-per-riga. I contenuti storici devono essere verificati come capitoli
   del corso `Inizia con PosturaCorretta`; il Programma conserva le schede e
   l'ordine delle lezioni pratiche.
2. Portare `posturacorretta_percorso.yml` a riferimenti `content_id` del
   catalogo `contents.yml`, poi cambiare il loader del lettore.
3. Dopo il test della home/corsi, spostare gli storici in un unico archivio
   interno, senza cancellarli.
4. Solo alla fine rimuovere le sei copie identiche in `chapters copy/` e i due
   Markdown `copy` della guida, se non contengono modifiche intenzionali.

## Regola per i nuovi Brand

Un nuovo Brand non deve partire con copie di questi file: crea il proprio
`config/data/brands/<slug>/editorial.yml`, quindi aggiunge solo le entità che
gli servono. Il Domain sceglie poi quali di esse esporre nella sua landing.

## Migrazione completata: Percorso Integrato

La precedente sezione `guide/03_percorso` non appartiene piu' a
PosturaCorretta: persone, tutor, professionisti e programmi sono ora in
`config/data/brands/percorso-integrato/docs/`. Le vecchie URL ricevono un
redirect tecnico verso `/percorso-integrato/docs`.
