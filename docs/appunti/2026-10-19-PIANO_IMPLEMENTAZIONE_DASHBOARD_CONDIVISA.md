# Piano — Dashboard condivisa Flowpulse

**Data:** 19 ottobre 2026  
**Stato:** fonte operativa corrente; impostazione rivista il 21 ottobre 2026
**Prototipo:** `docs/private_prototypes/viste_html/Dashboard · generaimpresa.html`
**Modello precedente congelato:** `docs/private_prototypes/viste_html/Dashboard · generaimpresa · originale 2026-10-19.html` (versione precedente al Tavolo; non modificare)
**Implementazione precedente:** `/flowpulse/admin/production` (base da riusare,
non destinazione definitiva)

## Obiettivo

Costruire una nuova dashboard ufficiale condivisa, composta da quattro aree,
che riusi progressivamente frontend, controller, query e modelli esistenti.
Durante la costruzione le vecchie dashboard restano operative; saranno
sostituite soltanto dopo avere raggiunto e verificato la parità funzionale.

```text
Flowpulse             Generaimpresa       Rails4Business       1impegno
visione comune        cosa esiste         come si produce      chi, cosa, quando

Panoramica            Brand               Skill                Impegni
collegamenti          Progetti / Node     Catene               Settimana
regia                 Prodotti            Dime e processi      Contatti e luoghi
```

Flowpulse fornisce la shell, le autorizzazioni, la navigazione e il
collegamento fra le quattro aree. Ogni area conserva però il proprio confine:
Impegni e Settimana appartengono a 1impegno; Brand, Progetti / Node e Prodotti
a Generaimpresa; Skill e catene di montaggio a Rails4Business.

La dashboard non diventa un nuovo Brand e non introduce un quinto archivio.
Legge `Node`, Skill, processi, prodotti e dati di 1impegno dalle rispettive
fonti di verità.

## Decisione architetturale corrente

La destinazione è una nuova shell ufficiale condivisa. La dashboard Creator,
la dashboard produttiva superadmin e il workspace 1impegno sono sorgenti da
riusare, non la struttura definitiva da estendere indefinitamente.

La nuova shell deve riusare:

- shell Flowpulse;
- selezione del ruolo e del canale Creator;
- controllo dei Node amministrabili;
- albero di Node e domini;
- layout responsive già condiviso.

La nuova dashboard non deve avere un controller monolitico: ogni area avrà
controller e viste propri sotto una shell comune. La dashboard tecnica
`/admin/dashboard` resta separata e continua a governare applicazione, domini,
audit e importazioni.

Le landing pubbliche di Generaimpresa, Rails4Business e 1impegno restano
separate. La dashboard le collega ma non le incorpora integralmente.

## Inventario verificato

### Flowpulse e workspace Creator

Da conservare:

- `flowtree_dashboard` come shell autenticata;
- topbar, profilo, cambio ruolo e navigazione responsive;
- `CreatorWorld::DashboardController` per canali, root Node e domini;
- albero e autorizzazioni di `CreatorWorld::NodesController`;
- `FlowRoles` e il menu centralizzato.

Da cambiare:

- la dashboard Creator non deve fermarsi a “Root node e domini”;
- Node e domini diventano l'ingresso **Generaimpresa** del workspace;
- serve una sezione produttiva comune, raggiungibile dal menu Creator;
- le query non devono vivere nelle view.

### Generaimpresa

Da conservare:

- Brand e progetti rappresentati dai `Node`;
- distinzione Brand professionale / Brand progetto;
- gerarchia dei Node, sottobrand e domini;
- proprietario, responsabili e accesso ai pannelli del Brand;
- catalogo pubblico su `generaimpresa.it`.

Da non portare nella dashboard:

- hero e contenuti promozionali della landing;
- schede editoriali pubbliche dei Brand;
- duplicazioni YAML dei dati che esistono già nel database.

### Rails4Business

Da conservare:

- `ReusableSkill`;
- attivazione della Skill sul Node tramite `ReusableSkillNode`;
- `SkillProduct` e collegamenti fra prodotti;
- `NodeProcess` come catena produttiva;
- `reference_data_experience` del `NodeProcess` come primo supporto alla
  **Dima attiva**;
- `ProblemSolvingCycle` come strumento separato e facoltativo;
- pagine specialistiche di Skill, prodotti, processi e problemi.

Da cambiare:

- i controller Rails4Business usano ancora il layout pubblico `landing`;
- manca un ingresso Rails4Business coerente dentro il workspace;
- manca una query che mostri insieme Skill attive, catene, dima e prodotti di
  un Node;
- la UI deve usare il termine **Dima attiva**, non “Ultimo ciclo”;
- un Ciclo di lavoro concreto non deve essere confuso con la dima.

### 1impegno

Da conservare:

- `DataCommitment`, `DataSlot` e `DataSession`;
- `DataExperience` come ciclo/lavorazione concreta finché non verrà
  eventualmente rinominata;
- `DataExperiences::OrderedSteps`;
- `DataExperiences::Duplicate`;
- agenda, calendario, luoghi, contatti e workspace professionale;
- collegamenti esistenti a Node, SkillProduct e DataExperience.

Da cambiare:

- la vista Settimana deve essere sempre relativa a una persona;
- la pagina della persona deve distinguere impegni da fare, eventi con data ed
  eventi ripetuti;
- nel calendario deve comparire l'occorrenza settimanale, non la regola di
  ricorrenza astratta;
- bisogna definire in modo univoco chi è una “persona coinvolta”;
- la dashboard non deve copiare l'intera agenda di 1impegno.

## UX obiettivo

### Stile

La prima implementazione usa Tailwind CSS già presente nella repository:

- nessun nuovo framework frontend;
- nessun CDN aggiuntivo;
- componenti ERB piccoli e classi Tailwind coerenti con il workspace attuale;
- Turbo Frame per cambiare viste e filtri senza costruire una SPA;
- Stimulus soltanto per interazioni locali necessarie;
- tabella su desktop e righe trasformate in schede su smartphone;
- stati, tipi e responsabilità mostrati con badge sobri e consistenti.

Prima si rifinisce il prototipo statico nello stile Tailwind del progetto. Poi
lo stesso markup viene suddiviso in partial ERB; non si mantiene un secondo CSS
dedicato alla dashboard.

### Impegni — primo incremento verticale di 1impegno

La prima sezione da costruire nella nuova dashboard è l'index **Impegni** di
1impegno. La fonte è `DataCommitment`: non viene creato un nuovo archivio.

L'index, inizialmente in sola lettura, mostra:

- titolo e stato;
- proprietario e destinatario;
- Brand;
- Progetto / Node;
- Skill;
- prodotto;
- eventuale catena;
- data oppure indicazione "da programmare".

La lista rimane leggera. Classificazione completa, modifica, pianificazione,
azioni ed export del singolo record vivono nello show del DataCommitment. Dopo
la verifica di index e show si collega la vista Settimana agli stessi record.

#### Storico: Tavolo e raccolta rapida

La sezione seguente documenta la prima implementazione superadmin chiamata
**Tavolo**. Resta utile come inventario dei campi e della raccolta rapida, ma
non definisce più la navigazione della nuova dashboard ufficiale: quelle voci
sono DataCommitment e compaiono nell'index Impegni di 1impegno.

Prima della vista ordinata serve un posto nel quale scaricare rapidamente
attività, idee, eventi e cose da costruire. Nella dashboard condivisa questa
pagina si chiama **Tavolo**.

Il Tavolo appartiene operativamente a 1impegno, ma viene mostrato come primo
ingresso della dashboard generale perché una voce appena raccolta può non avere
ancora un Brand, una Skill, un prodotto o una data.

Per raccogliere una voce basta il titolo. La classificazione successiva usa la
stessa tabella:

| Raccolta |  | Generaimpresa |  | Rails4Business |  | 1impegno |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Voce | Che cos'è | Brand | Progetto / Node | Skill | Prodotto | Responsabile | Organizzazione | Stato |

Valori iniziali di **Che cos'è**:

- da definire;
- attività;
- progetto;
- Skill;
- prodotto;
- evento;
- evento ripetuto.

Valori iniziali di **Organizzazione**:

- da decidere;
- da completare;
- evento con data;
- evento ripetuto;
- catena produttiva.

Una voce rimane sul Tavolo finché non ha trovato il proprio posto:

- se aggiorna un prodotto esistente, confluisce nella sua riga;
- se crea davvero un nuovo progetto o prodotto, genera una nuova riga nella
  vista generale;
- se è soltanto personale, rimane in 1impegno e nella settimana della persona;
- se è una Skill, entra nel lavoro Rails4Business e potrà poi essere attivata
  sui Node;
- se non è ancora chiara, non deve generare Node o prodotti fittizi.

Il Tavolo non è quindi un quarto archivio. È una coda di raccolta e
classificazione che porta ai modelli proprietari quando la collocazione viene
confermata.

La prima implementazione reale usa un `DataCommitment` con:

```text
status: draft
starts_at: nil
blocks_calendar: false
metadata.workbench.inbox: true
```

La classificazione progressiva viene conservata in
`metadata.workbench` (`item_type`, `organization`,
`classification_status`, `reusable_skill_id`, `product_name`). I collegamenti
reali già disponibili rimangono nelle loro colonne relazionali:

- `domain_id` per il primo contesto Brand;
- `subject` per il Progetto / Node;
- `skill_product_id` per un prodotto già esistente;
- `responsible_profile_id` per la persona responsabile.

Non è stata aggiunta una nuova tabella.

### Vista generale

Una riga rappresenta un prodotto o una lavorazione concreta e viene
raggruppata per Brand e progetto.

| Generaimpresa |  |  | Rails4Business |  | 1impegno |  |
| --- | --- | --- | --- | --- | --- | --- |
| Brand | Progetto | Prodotto | Skill | Catena | Persone | Ultimo impegno |

La vista generale non contiene card riepilogative ridondanti e non contiene
un selettore “Stai lavorando su”. I filtri, quando arriveranno, saranno filtri
reali per Creator, Brand, Node, stato e persona.

### Dettaglio

Il breadcrumb è:

```text
Brand › Progetto › Prodotto
```

Le tab principali sono:

```text
Generaimpresa | Rails4Business | 1impegno
```

Sottoviste:

```text
Generaimpresa
├── Struttura
├── Responsabili
└── Risultato

Rails4Business
├── Skill
├── Catena
├── Dima attiva
└── Prodotti

1impegno
├── Persone
├── Impegni
├── Programmazione
└── Storico
```

Il Ciclo di lavoro concreto può essere raggiunto dai prodotti o dagli impegni.
Non sostituisce la Dima attiva.

### Persona

La prima vista personale implementata riguarda il profilo corrente e usa tre
lenti sugli stessi dati:

```text
Da completare | Agenda | Settimana
```

- **Da completare** mostra gli impegni ancora aperti e tiene fuori le voci del
  Tavolo;
- **Agenda** presenta la settimana giorno per giorno, come un programma;
- **Settimana** colloca gli stessi appuntamenti nella griglia oraria e rende
  visibili anche gli spazi liberi.

Agenda e Settimana mostrano il contenitore superiore: una `DataSession` non
viene duplicata attraverso i Commitment che le appartengono. La pagina non
espone calendari di altri profili. Le vere regole di ricorrenza restano da
modellare: per ora la griglia mostra soltanto occorrenze con una data reale.

## Mappatura sui modelli esistenti

| Informazione UI | Fonte principale |
| --- | --- |
| Brand, progetto, sottoprogetto | `Node` |
| Dominio | `Domain` |
| Proprietario del ramo | `RoleAssignment` / `Profile` |
| Skill disponibile | `ReusableSkill` |
| Skill attiva sul progetto | `ReusableSkillNode` |
| Prodotto | `SkillProduct` |
| Catena | `NodeProcess` |
| Dima attiva | `NodeProcess#reference_data_experience` |
| Ciclo di lavoro | `DataExperience` diversa dalla dima di riferimento |
| Passaggi ordinati | `DataExperiences::OrderedSteps` |
| Persona responsabile | `responsible_profile` |
| Persona assegnata | `assignee_profile` del Commitment |
| Impegno personale | `Brands::Impegno::Commitment` |
| Attività da assegnare | `DataSlot` |
| Attività coordinata / evento concreto | `DataSession` |
| Contenuto pubblico dell'evento | `SkillProduct` della Skill Eventi |

## Definizione di persona coinvolta

Per evitare elenchi arbitrari, la prima query considera coinvolta una persona
se ricopre almeno uno di questi ruoli nel perimetro selezionato:

1. responsabile del NodeProcess;
2. responsabile della DataExperience;
3. responsabile o assegnatario di un DataCommitment;
4. partecipante registrato tramite Commitment dentro Slot o Session.

Creatore del record e persona coinvolta non sono sinonimi. Il
`created_by_profile` rimane informazione di audit e non rende automaticamente
la persona membro del lavoro.

## Backend condiviso da introdurre

Non serve subito un nuovo modello. Serve prima un livello di lettura comune:

```text
ProductionDashboard::Scope
├── limita Creator, RoleAssignment e Node autorizzati
├── applica il contesto del dominio quando necessario
└── impedisce di leggere calendari estranei

ProductionDashboard::Query
├── carica Node, Skill attive, Process e prodotti
├── raccoglie cicli e ultimo impegno senza N+1
└── restituisce record reali, senza contatori inventati

ProductionDashboard::RowPresenter
└── prepara una riga Brand → Progetto → Prodotto

ProductionDashboard::DetailPresenter
└── prepara le tre tab del dettaglio

ProductionDashboard::PersonPresenter
└── prepara impegni, eventi, ricorrenze e settimana autorizzata
```

Questi oggetti non scrivono dati e possono essere riutilizzati prima dal
superadmin e poi dai Creator.

## Rotte precedentemente proposte

Queste rotte documentano l'ipotesi precedente basata sul workspace Creator e
non sono più la destinazione approvata:

```text
/creator_world/production
/creator_world/production/inbox
/creator_world/production/:id
/creator_world/production/people/:profile_id
/creator_world/production/people/:profile_id/week
```

L'identificatore del dettaglio non deve obbligare a creare un nuovo modello.
Il controller può ricevere `node_id`, `skill_product_id` o
`data_experience_id` come chiavi esplicite finché il dominio non richiederà
un'entità aggregata persistente.

### Rotte già implementate per il superadmin

```text
/flowpulse/admin/production
/flowpulse/admin/production/nodes/:id
/flowpulse/admin/production/tavolo
/flowpulse/admin/production/tavolo/:id
```

L'index ha quattro ingressi di sistema:

```text
Flowpulse | Generaimpresa | Rails4Business | 1impegno
```

Questa prima implementazione collocava Tavolo e Progetti/prodotti sotto
Flowpulse. Nella nuova struttura è codice da riusare: Impegni passa a
1impegno, mentre Brand, Progetti / Node e Prodotti passano a Generaimpresa.
Nel dettaglio di un Node le letture trasversali possono rimanere:

```text
Generaimpresa | Rails4Business | 1impegno
```

Nella prima fase le tre aree rimandano anche alle dashboard specialistiche già
presenti. L'apertura ai Creator resterà separata dall'accesso superadmin.

## Fasi di implementazione

### Fase 0 — Terminologia e documentazione

- [x] distinguere Catena, Dima attiva, Ciclo di lavoro e Prodotto;
- [x] rendere personale la vista Settimana del prototipo;
- [ ] marcare definitivamente il piano del 17 ottobre come storico nelle
      sezioni incompatibili;
- [ ] aggiornare il vocabolario generale di 1impegno con Dima e Ciclo.

### Fase 1 — UI Tailwind statica

- [ ] tradurre il prototipo nelle convenzioni Tailwind della repository;
- [ ] eliminare il CSS autonomo del prototipo;
- [ ] verificare tabella desktop e schede mobile;
- [ ] definire empty state, loading state, error state e dati mancanti;
- [x] aggiungere il Tavolo con inserimento rapido e classificazione nella
      tabella;
- [ ] mantenere Tavolo, Tabella/Elenco, dettaglio e pagina persona;
- [ ] approvare l'UX prima di collegare query reali.

### Fase 2 — Shell Rails in sola lettura

- [x] aggiungere la voce “Dashboard Flowpulse” al menu superadmin;
- [x] creare controller e viste iniziali nel namespace `Admin`;
- [x] mantenere separata la Regia tecnica dalla dashboard produttiva;
- [ ] aggiungere in seguito la voce “Produzione” al menu Creator;
- [ ] estrarre query e autorizzazioni condivise prima dell'apertura ai Creator;
- [ ] usare `flowtree_dashboard` e partial condivisi;
- [ ] limitare inizialmente l'accesso a superadmin e ideatore autorizzato;
- [ ] mantenere le pagine specialistiche come destinazioni dei link.

### Fase 3 — Generaimpresa reale

- [ ] costruire `ProductionDashboard::Scope`;
- [ ] caricare Creator, Brand, progetti e sottoprogetti dai Node;
- [ ] riusare dominio, proprietario e responsabili esistenti;
- [ ] raggruppare le righe per Brand senza duplicare l'albero;
- [ ] testare sottobrand, Node ponte e Node senza dominio.

### Fase 4 — Rails4Business reale

- [ ] caricare le Skill attive tramite `ReusableSkillNode`;
- [ ] mostrare `NodeProcess` e responsabile;
- [ ] mostrare la Dima attiva tramite `reference_data_experience`;
- [ ] ordinare i suoi passaggi con `DataExperiences::OrderedSteps`;
- [ ] mostrare SkillProduct diretti e prodotti collegati a cicli;
- [ ] collegare alle pagine Rails4Business già presenti;
- [ ] mostrare ProblemSolving soltanto come collegamento facoltativo.

### Fase 5 — 1impegno reale

- [x] consentire un Commitment personale in bozza, senza data, che non blocca
      il calendario e rappresenta una voce ancora da organizzare;
- [x] costruire il filtro e il form rapido del Tavolo;
- [x] permettere di assegnare progressivamente Node, Skill, prodotto,
      responsabile e forma di organizzazione;
- [ ] spostare la voce dalla raccolta alla vista corretta soltanto dopo la
      classificazione;
- [ ] definire e testare la query delle persone coinvolte;
- [ ] mostrare ultimo impegno senza duplicare l'agenda;
- [x] costruire per il profilo corrente le viste Da completare, Agenda e
      Settimana;
- [ ] modellare e distinguere la regola di ricorrenza dalle sue occorrenze;
- [x] proteggere la prima vista personale dai dati appartenenti ad altri
      profili;
- [ ] collegare ogni elemento alla pagina operativa di 1impegno.

### Fase 6 — Dima e cicli

- [ ] impedire che la Dima attiva venga confusa con un ciclo ordinario;
- [ ] verificare che la duplicazione svuoti date, orari e stati;
- [ ] decidere se gli assegnatari della dima debbano diventare suggerimenti o
      rimanere vuoti;
- [ ] permettere di avviare un nuovo ciclo dalla Dima attiva;
- [ ] mantenere i cicli conclusi immutabili rispetto alle modifiche future
      della dima.

### Fase 7 — Scrittura controllata

Solo dopo la lettura reale:

- [ ] creare o collegare un prodotto;
- [ ] attivare una Skill sul Node;
- [ ] scegliere o aggiornare la Dima attiva;
- [ ] avviare un ciclo;
- [ ] assegnare Commitment e Slot;
- [ ] programmare Session;
- [ ] pubblicare o aggiornare uno SkillProduct.

Le azioni continuano a usare controller e servizi del dominio proprietario;
la dashboard non deve contenere una seconda implementazione delle regole.

### Fase 8 — Apertura progressiva

- [ ] test con il superadmin su PosturaCorretta;
- [ ] apertura all'ideatore del Brand;
- [ ] apertura ai responsabili dei singoli Node;
- [ ] apertura limitata agli operatori sui propri impegni;
- [ ] audit finale delle autorizzazioni.

## Primo caso pilota

Usare un solo flusso reale:

```text
Creator: Mark Postura
Brand: PosturaCorretta
Progetto: Percorso online oppure Canale YouTube
Skill: Contenuti / Media
Catena: produrre e pubblicare un contenuto
Dima attiva: passaggi ordinati della produzione
Ciclo: un articolo o un video concreto
Persone: responsabile e assegnatari reali
Risultato: SkillProduct in bozza o pubblicato
```

Il pilota deve includere anche un prodotto creato senza catena, per verificare
che la dashboard non renda obbligatorio il processo produttivo.

## Raccolta iniziale da caricare sul Tavolo

Queste voci costituiscono il primo caso reale del prototipo. Le collocazioni
visibili nella demo sono proposte modificabili: l'elenco originale non viene
trasformato automaticamente in nuovi Node o prodotti.

### Canta che ti passa

- Coro mercoledì sera “Amici miei”;
- lezioni di fisarmonica;
- esercitazioni di fisarmonica.

### Percorso Integrato

- preparare il form per i professionisti;
- pagina per il Comune;
- pagina informativa.

### Elisa

- Elementi;
- ritmi stagionali;
- orologio degli organi;
- corpi energetici.

### Piattaforma

- accesso;
- contenuti;
- corsi;
- percorsi;
- eventi.

### PosturaCorretta

- concludere il percorso;
- renderlo accessibile agli insegnanti;
- gruppi PosturaCorretta;
- lezioni individuali;
- video YouTube del canale PosturaCorretta;
- incontri settimanali a tema padel.

### Il Giardino del Corpo

- eventi di musicoterapia, apericoro, tessuti e meditazione;
- Drone / Giancarlo.

### Da collocare

- contenuti Instagram.

## Vincolo rilevato nel modello attuale

`Brands::Impegno::Commitment` richiede normalmente `starts_at` quando non è
collegato a una bozza di `DataExperience` e non è una richiesta esterna. Per
implementare il Tavolo senza inventare un altro modello bisogna ammettere il
caso esplicito:

```text
status: draft
starts_at: nil
blocks_calendar: false
external_request: false
```

Questo record rappresenta una voce personale **da organizzare**, non una
richiesta esterna e non ancora un appuntamento. Quando viene classificato può
ricevere Node, prodotto, responsabile e data oppure diventare parte di Slot o
Session. La regola va protetta con test per non indebolire la validazione degli
impegni già programmati.

## Test necessari

### Query e modelli

- scope dei Node amministrabili;
- dima appartenente allo stesso NodeProcess;
- prodotto e ciclo appartenenti allo stesso Node;
- persona coinvolta deduplicata con ruoli distinti;
- nessuna esposizione di Commitment estranei;
- caricamento senza N+1;
- prodotto senza ciclo e ciclo senza prodotto.

### Controller

- superadmin vede tutti i Node autorizzati;
- ideatore vede soltanto i propri rami;
- responsabile vede soltanto il Node assegnato;
- persona apre la propria settimana autorizzata;
- traveler e anonimo non accedono al workspace produttivo.

### Sistema e responsive

- tabella desktop;
- schede mobile;
- cambio tab con URL conservabile;
- breadcrumb;
- ritorno dalla settimana alla persona;
- empty state per Skill, processo, dima, prodotti, persone e impegni mancanti.

## Cosa non fare nella prima versione

- non spostare le landing pubbliche dentro la dashboard;
- non sostituire l'admin tecnico;
- non creare un nuovo modello “DashboardProduct”;
- non duplicare Node, SkillProduct o Commitment;
- non introdurre costi e statistiche inventate;
- non rendere obbligatoria la catena per ogni prodotto;
- non mostrare il calendario completo di una persona solo perché compare in un
  progetto;
- non riscrivere contemporaneamente tutte le pagine Rails4Business e
  1impegno.

## Ordine operativo consigliato

1. approvare il Tavolo e la sua tabella di classificazione;
2. rifinire il prototipo in Tailwind;
3. approvare index, dettaglio, persona e settimana;
4. creare la shell Rails in sola lettura;
5. implementare il Commitment in bozza senza data e l'inserimento rapido;
6. collegare prima Node e responsabilità;
7. collegare Skill, processi, dima e prodotti;
8. collegare persone e ultimo impegno;
9. testare il pilota PosturaCorretta;
10. soltanto dopo aggiungere le altre azioni di scrittura.
