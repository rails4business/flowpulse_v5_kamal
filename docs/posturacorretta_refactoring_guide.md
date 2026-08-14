# Refactoring delle guide PosturaCorretta

## Obiettivo

Riunire tutte le guide pubbliche di PosturaCorretta in un solo lettore uniforme, raggiungibile dalla home, senza perdere testi, Markdown, componenti HTML, dati dinamici, anchor o vecchi URL.

Il lettore condiviso deve offrire:

- un solo indice configurato da YAML;
- una sola sezione aperta alla volta;
- lo stesso layout per ogni guida;
- rendering coerente di Markdown e partial HTML;
- indice H1, H2 e H3 del documento;
- navigazione precedente, indice e successivo;
- aside desktop e pannello mobile uniformi;
- compatibilità con i vecchi collegamenti.

Le pagine operative restano distinte dalle guide. Non devono essere duplicate nell'indice perché sono già raggiungibili dal menu **Esplora**.

## Separazione tra guide e pagine operative

### Guide nel lettore unico

- PosturaCorretta in un mese;
- Conoscere il progetto;
- Come funziona il Percorso Integrato;
- Come funziona l'Accademia;
- Come funzionano gli Eventi;
- Come funzionano le Metodiche;
- Collaborare.

### Pagine operative esterne al lettore

- Percorso Integrato: ricerca, orientamento, programmi, professionisti e luoghi;
- Contenuti: catalogo, ricerca e filtri;
- Eventi: calendario, filtri, dettagli e iscrizioni;
- Accademia: curriculum, moduli, pratica e abilitazioni;
- Metodiche: catalogo e filtri;
- Collabora: proposte, adesioni e call to action.

Le pagine operative possono essere collegate dal testo e dalle CTA dei capitoli pertinenti. Non servono collegamenti duplicati in fondo all'aside.

## Sorgente unica attuale

Tutti i contenuti editoriali delle guide sono raccolti in:

- `config/data/posturacorretta/guide/indice.yml`, unico indice e fonte della navigazione;
- `config/data/posturacorretta/guide/<sezione>/`, per introduzioni e capitoli Markdown;
- `app/views/posturacorretta/guide/sections/<sezione>/`, per i capitoli HTML dinamici.

Le vecchie copie sotto `primo_mese/contenuti`, `percorso/contenuti` e `collabora/professionisti` sono state rimosse. Matrice e paradigmi sono ora in `guide/02_progetto/01_paradigmi_e_matrice.md`.

I cataloghi e i dati operativi restano intenzionalmente fuori da `guide/`.

## Inventario storico delle sorgenti migrate

### PosturaCorretta in un mese

Sorgenti Markdown:

- `config/data/posturacorretta/guide/01_primo_mese/01_errori.md`;
- `02-benefici.md`;
- `00_da_dove_iniziare.md`;
- `04-disallineamento.md`;
- `05-metodiche.md`.

Il capitolo sulla visione usa attualmente il blocco HTML `introduction` della view `app/views/posturacorretta/libro.html.erb`.

### Conoscere il progetto

La partial `app/views/posturacorretta/guide/sections/02_progetto/_visione.html.erb` contiene i blocchi HTML riutilizzabili:

- `introduction`;
- `map`;
- `actors`;
- `roles`;
- `garden`;
- `book`.

Il blocco `map` usa inoltre:

- `config/data/posturacorretta/guide/02_progetto/01_paradigmi_e_matrice.md`;
- partial `posturacorretta/chakras_ambiti`;
- partial `posturacorretta/aree`;
- tassonomie PosturaCorretta.

Questi componenti non devono essere convertiti forzatamente in Markdown.

### Percorso Integrato

Indice e contenuti attuali:

- indice in `config/data/posturacorretta/guide/indice.yml`;
- Markdown in `config/data/posturacorretta/guide/03_percorso/`;
- partial in `app/views/posturacorretta/guide/sections/03_percorso/`;
- collaborazione in `config/data/posturacorretta/guide/07_collabora/`.

La pagina operativa resta `/posturacorretta/percorso`. La guida storica resta temporaneamente disponibile su `/posturacorretta/percorso/come-funziona`.

### Accademia

La guida è attualmente incorporata in:

- `app/views/landing/_accademia_curriculum.html.erb`;
- tab `guide`;
- anchor `educazione`, `formazione-verticale`, `formazione-orizzontale`, `risposta`, `ruoli`, `percorsi`, `funzione`, `collabora`, `fasi`, `ambiti-insegnante`.

Il curriculum e i moduli restano operativi nella pagina Accademia. La parte guida dovrà essere estratta in partial riutilizzabili dal lettore unico.

### Eventi

La guida è nella tab `how` di `app/views/posturacorretta/eventi.html.erb`:

- introduzione agli eventi;
- `partecipanti`;
- `conduttori`;
- `location`.

Calendario, filtri e modale evento restano nella pagina operativa.

### Metodiche

La guida è nella tab `how` di `app/views/posturacorretta/metodiche.html.erb`:

- introduzione;
- `persone`;
- `professionisti`;
- `scuole`.

Catalogo e filtri restano nella pagina operativa.

### Collaborare

Sorgenti principali:

- `app/views/posturacorretta/collabora.html.erb`;
- `app/views/posturacorretta/collabora_professionisti.html.erb`;
- `config/data/posturacorretta/collabora/professionisti/guide.yml`;
- relativi file Markdown;
- `app/views/posturacorretta/collabora_digital.html.erb`.

Le CTA, WhatsApp e azioni operative devono restare contestuali ai capitoli corrispondenti.

## Struttura definitiva dell'indice YAML

La sorgente centrale è:

`config/data/posturacorretta/guide/indice.yml`

Tipi previsti:

- `chapters`: sezione composta da capitoli renderizzati nel lettore;
- `group`: raggruppamento visuale senza contenuto proprio;
- `markdown`: capitolo letto da un file Markdown;
- `partial`: capitolo HTML renderizzato da una partial;
- `vision`: compatibilità temporanea con i blocchi della vecchia Visione;
- `redirect`: compatibilità temporanea durante la migrazione.

Struttura obiettivo:

```yml
sections:
  - id: percorso
    title: Come funziona il Percorso Integrato
    type: chapters
    items:
      - slug: percorso-inizia
        title: Inizia il percorso
        type: partial
        source: posturacorretta/percorso/inizia
        legacy_urls:
          - /posturacorretta/percorso/come-funziona?page=linee-guida-inizia
```

L'indentazione deriva da `children`; non deve essere salvata come booleano grafico.

## Layout condiviso

Il lettore deve diventare una partial o un componente responsabile esclusivamente di:

1. intestazione pagina;
2. aside desktop;
3. drawer mobile;
4. accordion dell'indice;
5. area del documento;
6. eventuale indice H1/H2/H3;
7. precedente, indice e successivo.

Il contenuto non deve definire layout, aside o navigazione propri.

## Strategia per non perdere informazioni

1. Non eliminare le sorgenti durante l'estrazione.
2. Estrarre i blocchi HTML in partial senza riscriverne il testo.
3. Rendere la stessa partial sia nella vecchia pagina sia nel nuovo lettore.
4. Confrontare visivamente entrambe le versioni.
5. Solo dopo il confronto, trasformare il vecchio URL in redirect.
6. Conservare gli anchor significativi tramite redirect al nuovo capitolo.
7. Non convertire in Markdown componenti dinamici, card, matrici o dati caricati dal controller.

## Compatibilità degli URL

Durante il refactoring ogni vecchio URL deve avere una destinazione esplicita.

Esempi:

- `/posturacorretta/percorso/come-funziona?page=...` → capitolo Percorso nel lettore;
- `/posturacorretta/eventi?tab=how#partecipanti` → capitolo Eventi per partecipanti;
- `/posturacorretta/metodiche?tab=how#professionisti` → capitolo Metodiche per professionisti;
- `/posturacorretta/accademia?tab=guide#fasi` → capitolo Accademia sulle tre fasi.

I redirect permanenti vengono aggiunti solo dopo aver verificato il nuovo rendering.

## Piano di implementazione

### Fase 1 — Base e documentazione

- [x] creare l'indice centrale YAML;
- [x] creare accordion condiviso nella home;
- [x] distinguere guide e pagine operative;
- [x] documentare inventario e strategia;
- [x] togliere dall'aside i collegamenti operativi duplicati.

### Fase 2 — Percorso Integrato

- [x] importare la gerarchia di `percorso/aside.yml` nell'indice centrale;
- [x] supportare gruppi e `children` nel lettore;
- [x] renderizzare Markdown e partial del Percorso nella home;
- [x] mantenere form, professionisti e luoghi nella pagina operativa;
- [x] verificare precedente e successivo;
- [x] aggiungere redirect dei vecchi parametri `page`.

### Fase 3 — Eventi e Metodiche

- [x] estrarre le sezioni guida in partial;
- [x] renderizzarle nel lettore;
- [x] mantenere calendari, cataloghi e filtri nelle pagine operative;
- [x] aggiungere redirect delle vecchie tab;
- [ ] rimuovere i blocchi guida duplicati dalle vecchie viste dopo il confronto visivo.

### Fase 4 — Accademia

- [x] creare i capitoli condivisi della guida nel lettore;
- [x] conservare moduli, tab di pratica e abilitazioni nella pagina operativa;
- [x] aggiungere redirect della vecchia tab guida;
- [ ] rimuovere il blocco guida dal grande partial del curriculum dopo il confronto visivo.

### Fase 5 — Collaborare

- [x] riutilizzare i Markdown professionali esistenti;
- [x] estrarre insegnanti e digitale in capitoli uniformi;
- [x] mantenere CTA contestuali e messaggi WhatsApp;
- [x] collegare le vecchie guide ai nuovi capitoli;
- [ ] eliminare duplicazioni residue tra le viste operative di Percorso e Collabora.

### Fase 6 — Pulizia

- [ ] rimuovere aside e layout duplicati dalle vecchie guide;
- [ ] rimuovere codice non più raggiungibile;
- [ ] aggiornare sitemap e metadati;
- [ ] validare tutti i vecchi URL;
- [ ] verificare desktop, Android e iPhone.

## Criteri di completamento

Il refactoring è concluso quando:

- tutte le guide si leggono nello stesso layout;
- l'indice centrale è l'unica fonte di navigazione documentale;
- le pagine operative non duplicano le guide;
- i vecchi URL non restituiscono errori;
- nessun testo o componente HTML è stato perso;
- aside e contenuto funzionano su desktop, Android e iPhone;
- una correzione al lettore si applica automaticamente a tutte le guide.
