# Home PosturaCorretta — UX e progressione Scopri → Pratica → Approfondisci

## Obiettivo

Rendere `posturacorretta.org` (in locale `/posturacorretta`) una home che una persona capisce al primo sguardo: **da dove inizio, cosa faccio dopo, chi mi segue**. La progressione è già scritta nella pagina e diventa la struttura della home:

1. **Scopri** — corso online, 10 minuti al giorno;
2. **Pratica** — lezioni con un insegnante PosturaCorretta, nei centri;
3. **Approfondisci** — metodiche posturali e professionisti formati.

Documenti collegati, da rispettare:

- [`ecosistema_persona_tre_progetti.md`](ecosistema_persona_tre_progetti.md) — la persona al centro; Il Giardino del Corpo è un progetto distinto, non una sezione interna di PosturaCorretta.
- [`posturacorretta_home_valutazione_interventi.md`](posturacorretta_home_valutazione_interventi.md) — interventi già fatti (Inizia, Corso 1 di 6, avanzamento, stati dei capitoli) e criteri di decisione.

## Metodo

Un punto alla volta: si presenta il punto, si decide insieme, si implementa, si verifica in locale, si segna `[x]`. Gli altri punti restano in attesa.

## Stato attuale (26/11/2026)

File principali:

- [`app/views/nodes/posturacorretta_home/_overview.html.erb`](../app/views/nodes/posturacorretta_home/_overview.html.erb) — schede Inizia / Percorso educativo / Consapevolezza / Connessione;
- [`app/views/nodes/posturacorretta_home/_landing.html.erb`](../app/views/nodes/posturacorretta_home/_landing.html.erb) — hero, tre principi, tabella programma, parti del percorso educativo;
- [`app/controllers/nodes_controller.rb`](../app/controllers/nodes_controller.rb) `domain_home` e `prepare_posturacorretta_home` in [`public_node_presentation.rb`](../app/controllers/concerns/public_node_presentation.rb).

Cosa vede oggi un visitatore:

- **tre livelli di navigazione**: menu in alto (Home, Insegnanti, Centri, Servizi, About), schede della home (Inizia, Percorso educativo, Consapevolezza, Connessione), sotto-schede del percorso educativo (Recupero, Movimento, Mente, Fisiologia);
- nomi interni (“Espressione”, “Consapevolezza”, “Connessione”) che non dicono cosa si trova;
- Movimento, Mente e Fisiologia aprono “Questa parte del programma è in preparazione”;
- “Richiedi accesso” in alto per tutti: è il flusso per chi lavora sul brand;
- “Inizia”, “Inizia il percorso” e le due colonne della tabella programma puntano quasi tutti a `/posturacorretta/percorsi/postura-recupero`, cambia solo `tab=online|lezioni`;
- chi ha già fatto l'accesso vede la stessa vetrina;
- testi da rivedere: “Salute perfetta”; “Ogni metodica ha una scuola” (le scuole oggi non esistono).

## Punti

### 1. Home senza schede — [ ]

**Proposta.** La home diventa una pagina unica, senza `pc-index-cabinet__tabs`:

1. hero: titolo, una frase, **un solo pulsante principale** “Inizia il corso online” (porta alla prima tappa) e un secondario “Come funziona” (ancora `#come-funziona`);
2. i tre passi Scopri / Pratica / Approfondisci come blocchi cliccabili, ognuno con una destinazione;
3. anteprima del programma: i primi corsi (Corso 1 di N…) e “Vedi tutto il programma”;
4. fiducia: chi cura il progetto (rimando alla pagina persone, quando esisterà);
5. footer.

**Destinazioni dei tre passi:**

| Passo | Destinazione proposta | Rotta esistente |
|---|---|---|
| Scopri | prima tappa del corso online | `posturacorretta_postura_recupero_path(tappa: "introduzione-al-percorso-integrato", tab: "online")` |
| Pratica | insegnanti e centri | `posturacorretta_insegnanti_path`, `posturacorretta_centres_path` |
| Approfondisci | metodiche, poi professionisti | `posturacorretta_metodiche_path`, `posturacorretta_professionisti_path` |

**Da decidere:**

- il link `?area=…` resta valido (redirect alla nuova sezione) o lo togliamo?
- nell'anteprima i corsi sono 3 (come oggi in “Inizia il programma”) o i 6 di “Corso 1 di 6”?

### 2. Menu in alto e accesso — [ ]

**Proposta.** Menu: **Percorso · Insegnanti · Centri · Metodiche · Accedi**. “Servizi” e “About” passano nel footer. “Richiedi accesso” esce dal menu pubblico e va nel footer come “Collabora con PosturaCorretta”.

**Da decidere:** il menu viene dai Node (`_public_navigation_items`): si cambia nel database/YAML dei nodi (vedi flusso nodes.yml → import) o nel codice?

### 3. Consapevolezza e Connessione — [ ]

**Proposta.** Escono dalla home come schede.

- **Consapevolezza** (corso, metodiche, percorsi): confluisce in Approfondisci.
- **Connessione** (`dalla-posturacorretta-al-giardino-del-corpo`): appartiene al Giardino del Corpo, quindi diventa un rimando distinto in fondo alla home o nel footer (“Il Giardino del Corpo”), non un passo del percorso.

**Da decidere:** le pagine `/posturacorretta/consapevolezza` e `/posturacorretta/connessione` restano come pagine autonome?

### 4. Parti del programma in preparazione — [ ]

**Proposta.** Movimento, Mente e Fisiologia non sono più cliccabili: nell'indice del programma compaiono con l'etichetta “In arrivo”, come già succede per i capitoli non pubblicati. Quando una parte ha contenuti pubblicati diventa cliccabile da sola.

**Da decidere:** mostrarle “In arrivo” oppure nasconderle del tutto?

### 5. Un link per ogni voce del programma — [ ]

**Proposta.** Nella tabella programma ogni riga ha un solo link (il corso online). Le lezioni con insegnante si raggiungono dal passo **Pratica**, non da una seconda colonna.

### 6. Home per chi ha già fatto l'accesso — [ ]

**Proposta.** In cima alla home, al posto dell'hero, un blocco “Continua da dove eri”: prossimo capitolo da leggere, avanzamento del corso, link al programma. Si riusa l'avanzamento già calcolato (capitoli segnati come letti). Senza corsi iniziati si vede l'hero normale.

### 7. Testi — [ ]

**Proposta.**

- sostituire “Salute perfetta con PosturaCorretta” con una frase senza promesse sanitarie;
- “Approfondisci”: togliere “Ogni metodica ha una scuola”, parlare di professionisti formati nella metodica;
- correggere “Impara come funziona il tuo corpo quali sono…” e “Pronto ad iniziare?”.

**Da decidere:** i testi nuovi li scrivi tu o propongo io una bozza da correggere?

### 8. Link sul dominio reale — [ ]

**Proposta.** Verificare che su `posturacorretta.org` i link della home puntino alla radice (`/insegnanti`), non a `/posturacorretta/insegnanti`. Riguarda il routing per host, non la UX: va fatto prima di pubblicare la nuova home.

## Ordine proposto

1 → 2 → 4 → 5 → 3 → 6 → 7 → 8. Il punto 1 viene prima perché gli altri dipendono dalla struttura della home.
