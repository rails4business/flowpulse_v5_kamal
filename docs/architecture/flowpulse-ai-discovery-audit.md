# Flowpulse — Audit AI Discovery, SEO, API e MCP

Data dell'audit iniziale: 11 ottobre 2026  
Ultimo aggiornamento applicativo: 12 ottobre 2026

## Stato dopo l'audit

Sono ora implementati: associazione `Domain → Node`, audit amministrativo dei
domini, proiezione pubblica condivisa, sitemap e robots per host, canonical e
JSON-LD di base, `llms.txt`, API read-only Domain/Node e prima proiezione
generica dei prodotti delle Skill su `/api/v1/resources`. Il pannello
superadmin dei domini include inoltre un controllo di pubblicazione con stato
verde, giallo o rosso per struttura, metadata, asset, sitemap, robots,
`llms.txt`, API e baseline PageSpeed.

`PublicDiscovery::AccessPolicy` è la fonte unica per HTML, sitemap, JSON-LD,
API e AI. Richiede `published/public`; per uno `SkillProduct` richiede inoltre
Skill disponibile, attivazione attiva e l'intero ramo Node pubblico nel Domain.
`subscription`, `purchase` e `private` non vengono esposti. Le sezioni che
seguono conservano anche decisioni e lacune emerse nell'audit iniziale; quando
una voce contrasta con questo aggiornamento prevale lo stato qui dichiarato.

## Legenda

- **Verificato:** confermato leggendo codice, configurazioni o dati versionati nella repository.
- **Da verificare:** richiede una misura in produzione, una scansione HTTP, dati operativi o una decisione editoriale.
- **Proposto:** soluzione futura; non è descritta come già disponibile.

## 1. Executive Summary

Flowpulse possiede già alcune fondamenta utili per la scoperta pubblica: domini configurati centralmente, redirect verso host canonici, layout con title, description, canonical, Open Graph e Twitter Card, filtri per bozze e contenuti programmati, nodi con stato e visibilità, oltre a cataloghi strutturati per contenuti ed eventi.

La direzione architetturale da rispettare è più ampia della sola indicizzazione dei siti. Il primo livello da consolidare è ogni dominio: identità e landing, prestazioni, SEO, Node radice, accesso ai Node pubblici e API read-only della struttura. Professionisti e operatori potranno così organizzare dati e ragionamenti entro un ingresso comune già comprensibile dal sito e dalle AI. Soltanto dopo questa base verranno attivate progressivamente le Skill-plugin e le collezioni di risorse che producono. Contenuti, servizi, corsi, sessioni, slot, luoghi, professionisti, canali e riferimenti non devono essere trasformati automaticamente in Node.

Il proprietario del Brand e il creatore dei Node governano ciò che può essere esposto. Ogni risorsa prodotta deve inoltre avere stato, visibilità e responsabilità propri. Non viene introdotto un canale privilegiato per le AI: ciò che un visitatore anonimo può consultare può essere incluso anche in sitemap, dati strutturati, API pubbliche e futuro MCP read-only. Ciò che richiede login, iscrizione, abbonamento, acquisto o un ruolo rimane protetto anche quando la ricerca parte da un'AI.

La copertura editoriale delle singole Skill resta progressiva, ma l'ingresso è
ora uniforme: ogni Domain canonico pubblico dispone di sitemap, robots,
JSON-LD, `llms.txt` e API read-only alimentati dalla medesima proiezione. Non è
ancora presente un server MCP e non sono ancora standardizzati tutti i tipi
specializzati di contenuti, corsi, eventi, luoghi e servizi.

Le principali opportunità, in ordine, sono:

1. definire un contratto minimo comune per ogni dominio e la sua landing;
2. misurare e migliorare PageSpeed, accessibilità e peso delle pagine dominio per dominio;
3. rendere sitemap, robots, canonical e JSON-LD dipendenti dal dominio richiesto;
4. esporre dominio e Node pubblici attraverso HTML e API read-only, riusando la stessa policy anonima;
5. attivare successivamente le Skill, che aggiungeranno collezioni standard alla struttura già disponibile.

Un server MCP non è il primo passo. Prima occorre stabilizzare l'ingresso di ogni dominio e la proiezione pubblica dei Node. Senza questa base, URL canoniche complete e un contratto JSON stabile, MCP duplicherebbe logica ancora in evoluzione. La sequenza raccomandata è **dominio e landing → PageSpeed/SEO → Node pubblici → API read-only dei Node → Skill e collezioni → MCP → ricerca semantica**.

## 2. Architettura esistente

### 2.1 Modelli e responsabilità

| Elemento | Stato e responsabilità verificata | Riferimenti |
|---|---|---|
| `Node` | Rappresenta la rete gerarchica. Distingue `professional` e `project`; ha stato `draft/published/archived`, visibilità `public/subscription/member/private`, ponti, processi, eventi, problemi e Skill. Un Node è considerato Brand quando possiede almeno un `Domain`. | `app/models/node.rb` |
| `Domain` | Associa host, eventuale host canonico, Node e destinazione controller/action. Conserva title, description, loghi, favicon, social image, lingua e impostazioni di accesso. | `app/models/domain.rb`, `config/domains.yml` |
| Brand | Non è un model separato: nel codice corrente è un Node dotato di Domain. Esistono Brand professionali e Brand progetto in base a `node_type`. | `app/models/node.rb`, `app/controllers/admin/brands_controller.rb` |
| `ReusableSkill` | Rappresenta la base già implementata delle Skill riutilizzabili. Una Skill è concettualmente un plugin attivabile in più Brand: definisce una funzione e, in futuro, il tipo di risorsa che produce, i ruoli che la gestiscono e il processo comune. È separata sia dai Node sia dal ProblemSolving. | `app/models/reusable_skill.rb` |
| `ProblemSolvingCycle` | Gestisce autonomamente il ciclo problema-soluzione e l'attenzione del creatore. Può essere collegato a Node e Skill e può produrre come esito una soluzione, un progetto, un contenuto, un servizio, un processo o l'idea per una nuova Skill; non è esso stesso una Skill. | `app/models/problem_solving_cycle.rb` |
| `Brands::Impegno::Commitment` | Rappresenta impegni e richieste, con proprietario, calendario, soggetto polimorfico e metadati editoriali/operativi. | `app/models/brands/impegno/commitment.rb`, migrazioni `db/migrate/20260729120000_create_data_commitments.rb` e successive |
| `DataSession` / `DataSlot` | Organizzano sessioni e fasce temporali, separatamente dai contenuti e dai Node. | `app/models/data_session.rb`, `app/models/data_slot.rb` |
| Contatti e luoghi | Sono implementati nell'area 1Impegno e usati, per esempio, dalle richieste di Corpo e Coscienza. | `app/models/brands/impegno/contact.rb`, `app/models/brands/impegno/place.rb`, `app/controllers/brands/corpo_e_coscienza_controller.rb` |
| Interazioni e scambi | **Da verificare / previsto:** non è emerso un sottosistema pubblico completo per denaro ed energia. Esistono campi economici nei commitment e servizi, ma non equivalgono a un sistema di scambio. | `app/models/brands/impegno/commitment.rb`, `app/models/service.rb` |

### 2.2 Livelli concettuali da mantenere separati

| Livello | Responsabilità | Esempi |
|---|---|---|
| Struttura | Organizza identità, Brand, progetti e confini. | Domain, Brand, Node, sotto-Brand, collegamenti tra Node. |
| Ricerca di soluzioni | Permette al creatore di isolare un problema, formulare ipotesi, testare e validare una soluzione. | `ProblemSolvingCycle`. |
| Funzioni attivabili | Fornisce plugin riutilizzabili ai Brand. | Skill Contenuti, Corsi, Eventi, Servizi, Luoghi, Professionisti, Canali, Prenotazioni. |
| Risorse prodotte | Contiene i dati concreti generati tramite una Skill attiva. | Articolo, corso, servizio, `DataSession`, `DataSlot`, luogo, profilo, canale, fonte. |
| Operatività personale | Registra una richiesta, un impegno o una partecipazione, senza diventare automaticamente informazione pubblica. | `DataCommitment`. |
| Responsabilità | Stabilisce chi crea la struttura e chi mantiene una risorsa. | Creatore, proprietario del Brand, responsabile del Node, produttore, operatore. |
| Esposizione | Decide cosa può vedere un visitatore anonimo e, di conseguenza, cosa può essere indicizzato o interrogato pubblicamente. | Stato editoriale e visibilità ordinaria, senza campi specifici per le AI. |

**Proposto.** Il produttore è il ruolo responsabile della risorsa generata da una Skill. Per esempio, la Skill Contenuti produce contenuti gestiti da autore/editor/produttore; la Skill Eventi produce sessioni e slot gestiti dall'organizzatore; la Skill Servizi produce servizi gestiti dal professionista o responsabile. Il ruolo non risulta ancora standardizzato in un unico modello e non va descritto come già operativo.

Il ProblemSolving rimane indipendente: è gestito dal creatore e può collegarsi a Node e Skill, ma non deve essere inserito nel catalogo dei plugin. Una soluzione validata può successivamente diventare una Skill riutilizzabile oppure generare un'altra risorsa.

### 2.3 Node come punto di composizione

**Proposto.** Il Node è il punto comune al quale vengono associate sia le attivazioni delle Skill sia i ProblemSolving, mantenendoli separati:

```text
Domain / Brand
└── Node
    ├── Skill attivate
    │   ├── Skill Contenuti → Content
    │   ├── Skill Corsi → Course
    │   ├── Skill Eventi → DataSession / DataSlot
    │   ├── Skill Luoghi → Place
    │   ├── Skill Servizi → Service
    │   └── Skill Professionisti → profili professionali
    └── ProblemSolving
        ├── problema
        ├── ipotesi e test
        └── soluzione
```

Occorre distinguere tre elementi:

1. **definizione della Skill:** il plugin riutilizzabile disponibile in Rails4Business;
2. **attivazione della Skill:** il collegamento della Skill a uno specifico Node/Brand, con futura configurazione, stato e responsabile;
3. **prodotto della Skill:** la risorsa concreta creata e gestita, per esempio un contenuto, un corso, una sessione o un luogo.

La relazione `ReusableSkillNode` esistente è la base dell'attivazione, ma oggi rappresenta principalmente il collegamento e non va descritta come un sistema completo di configurazione. Ogni prodotto dovrebbe appartenere a un Node principale, che determina responsabilità, Brand, dominio canonico e limite di visibilità. Una futura relazione aggiuntiva può consentire l'uso della stessa risorsa in più Node senza perdere il Node principale.

Il dominio aggrega i prodotti pubblici dei propri Node, fermandosi davanti a un sotto-Brand con dominio proprio. L'API del Node espone invece soltanto ciò che appartiene a quel Node.

### 2.4 Routing e rendering per dominio

**Verificato.** La root passa da `DomainsController`, che risolve il dominio corrente e può:

- renderizzare un sito editoriale configurato;
- inoltrare a un controller/action specifico;
- renderizzare il Node pubblico associato;
- usare Flowpulse come fallback.

Gli alias `www` e gli host alternativi sono associati a `canonical_host`; `CanonicalBrandHost` impedisce inoltre che, su un dominio dedicato, si navighi impropriamente un altro Brand tramite il suo prefisso di percorso. Le richieste GET/HEAD vengono redirette permanentemente al dominio corretto.

Riferimenti:

- `app/controllers/domains_controller.rb`
- `app/controllers/concerns/current_domain.rb`
- `app/controllers/concerns/canonical_brand_host.rb`
- `config/routes.rb`
- `config/domains.yml`

### 2.5 Fonti editoriali

**Verificato.** L'applicazione usa più fonti, ciascuna con un compito differente:

- database per Node, Domain, ruoli, DataCommitment, processi, problemi e Skill;
- YAML/Markdown per siti, articoli, corsi, professionisti, eventi e registri di progetto;
- `DomainContentCatalog` per normalizzare contenuti tra Flowpulse, PosturaCorretta, Mark Postura e Rails4Business;
- `DomainEventCatalog` per eventi e relazioni con domini/progetti;
- `FlowpulseProjectRegistry` per lo stato leggero dei progetti della rete.

Riferimenti:

- `app/services/domain_content_catalog.rb`
- `app/services/domain_event_catalog.rb`
- `app/models/flowpulse_project_registry.rb`
- `config/data/flowpulse/projects.yml`
- `config/data/sites/`
- `config/data/brands/`

Questa pluralità non va eliminata automaticamente: serve una **proiezione pubblica normalizzata**, non necessariamente una nuova fonte primaria.

I contenuti esistono già in più cataloghi YAML/Markdown e viste. **Proposto:** la loro gestione dovrà essere standardizzata come Skill Contenuti attivabile nei Brand. La Skill non coincide con i contenuti prodotti: definisce contratto, ruoli e comportamento comuni; ciascun contenuto resta una risorsa con autore/produttore, Brand, eventuale Node, stato, fonti e URL propri.

### 2.6 Autorizzazioni e visibilità

**Verificato.** `ApplicationController` espone un Node quando è pubblicato e pubblico, quando è in abbonamento e l'utente è iscritto, oppure quando l'utente autorizzato lo gestisce. I cataloghi editoriali escludono bozze e contenuti futuri per gli utenti pubblici; le anteprime e le pagine editoriali non pubbliche impostano `X-Robots-Tag: noindex, nofollow`. Le aree amministrative usano layout con `noindex,nofollow`.

Riferimenti:

- `app/controllers/application_controller.rb`
- `app/controllers/nodes_controller.rb`
- `app/controllers/concerns/editorial_rendering.rb`
- `app/views/layouts/brand_admin.html.erb`
- `app/services/domain_content_catalog.rb`

Una futura API deve riusare queste decisioni di visibilità tramite un livello condiviso, evitando di ricostruirle nei controller API.

### 2.7 Policy pubblica unica

**Implementato.** Non sono stati introdotti `status_ai`, `visibility_ai`,
`ai_discoverable` o stati paralleli. Il Node stabilisce il confine massimo
deciso dal creatore; ogni risorsa collegata mantiene il proprio stato
editoriale e la propria modalità di accesso. `PublicDiscovery::AccessPolicy`
viene riusata dal rendering HTML pubblico, dalle sitemap, dai dati strutturati,
dall'API e da `llms.txt`.

Una risorsa completa è pubblicamente consultabile quando:

1. appartiene a un Node pubblicato e con visibilità `public`;
2. è a sua volta pubblicata;
3. può essere aperta da un visitatore anonimo;
4. non contiene dati personali o informazioni escluse dalle normali regole pubbliche.

In forma sintetica:

```text
Node pubblicato e pubblico
        +
risorsa pubblicata e accessibile anonimamente
        =
stessa risorsa disponibile sul sito, nelle sitemap,
nei dati strutturati, nelle API pubbliche e per le AI
```

La risorsa può restringere il limite del Node, mai ampliarlo. Se un corso richiede iscrizione, abbonamento o acquisto, può restare pubblica la sua scheda di presentazione, mentre capitoli e materiali protetti non entrano nella discovery pubblica. `robots.txt`, `noindex` e canonical restano eccezioni tecniche per duplicati, filtri, prototipi e aree amministrative, non nuove fonti editoriali di verità.

### 2.8 Stato della rete dei Brand

| Brand/strumento | Presenza verificata | Discovery attuale | Nota |
|---|---|---|---|
| Flowpulse | Dominio, landing, registro progetti e pagine rete | HTML pubblico | Manca un manifesto strutturato pubblico della rete. |
| PosturaCorretta | Dominio, Node, contenuti, corsi, professionisti, insegnanti, eventi | È il dominio meglio coperto; sitemap dedicata | La sitemap è codificata specificamente per questo host. |
| Percorso Integrato | Dominio, landing, documentazione, professionisti, luoghi | HTML pubblico | Non risulta incluso in una sitemap propria. |
| Il Giardino del Corpo | Dominio, landing, eventi e luoghi collegati | HTML pubblico | Il dominio è configurato; discovery strutturata assente. |
| Rails4Business | Dominio, contenuti, problemi e Skill | Landing/contenuti pubblici; dashboard autenticate | Problemi e Skill non vanno esposti pubblicamente senza una decisione esplicita. |
| GeneraImpresa | Dominio, catalogo Brand/progetti | HTML pubblico con filtri di visibilità | Buon candidato come catalogo umano; serve contratto machine-readable. |
| CantaCheTiPassa | Dominio, landing e sezione fisarmonica | HTML pubblico | Mancano sitemap e dati strutturati dedicati. |
| Inside Adventure | Prototipo pubblico sotto Flowpulse | `noindex,nofollow` | Corretto finché è dichiarato in sviluppo. |
| 1Impegno | Dominio e applicazione operativa | Parte prevalentemente autenticata/operativa | Non indicizzare dati personali, calendari o richieste. |
| Calendario stagionale delle tradizioni contadine | Contenuto presente nei cataloghi/libro | Non risulta un Brand/dominio autonomo operativo | Trattarlo inizialmente come contenuto, non inventare un'entità separata. |
| Corpo e Coscienza | Dominio, landing, formazione, professionisti/richieste | HTML pubblico; richieste private | Da aggiungere alla discovery strutturata senza esporre contatti/richieste. |

### 2.9 Primo inventario tecnico dei domini

Questo inventario deriva dalle configurazioni versionate. L'associazione effettiva nel database di produzione resta **da verificare**, perché `Domain` può essere aggiornato/importato e collegato a un Node anche oltre quanto dichiarato nel file YAML.

| Dominio canonico | Rendering configurato | Node dichiarato nella configurazione | Metadata/asset | Prima criticità |
|---|---|---|---|---|
| `flowpulse.net` | `landing#flowpulse`, layout comune `landing` | Non indicato in `config/domains.yml` | Title e description presenti; asset Brand non dichiarati | Definire Node radice e completare identità visuale prima dell'API. |
| `markpostura.it` | Sito editoriale `markpostura_it` | `markpostura` nel sito editoriale/configurazione Domain | Navigazione e tema dedicati; metadata distribuiti tra sito e Domain | Uniformare il contratto Domain con i siti editoriali senza duplicare la fonte. |
| `posturacorretta.org` | `brands/posturacorretta#home` con redirect/percorso pubblico dedicato | `posturacorretta` | Metadata, loghi, favicon e social image presenti | È il dominio più completo ma ha molte viste legacy/copie da escludere dall'audit degli asset realmente serviti. |
| `percorsointegrato.it` | `brands/percorso_integrato#index`, layout `landing` | Non indicato nel YAML Domain | Metadata e immagini presenti | Collegare esplicitamente il Node radice o verificare il collegamento DB. |
| `generaimpresa.it` | `brands/genera_impresa#index`, layout `landing` | Node `generaimpresa` esiste in `config/nodes.yml`, non è indicato nel YAML Domain | Title/description presenti; loghi non dichiarati | Allineare Domain e Node prima di esporre l'albero pubblico. |
| `rails4b.com` | `landing#rails4b`, layout `landing` | `rails4business` | Title/description presenti; loghi non dichiarati | Preparare ingresso Node e asset condivisi. |
| `cantachetipassa.it` | `landing#cantachetipassa`, layout `landing` | `cantachetipassa` | Title/description presenti; loghi non dichiarati | Misurare landing e sezione fisarmonica, poi collegare l'ingresso Node. |
| `svuotamente.it` | `brands/svuotamente#index`, rendering senza layout | Non indicato nel YAML Domain | Title/description presenti | Eccezione architetturale: assenza del layout pubblico comune e quindi metadata/asset/policy potenzialmente divergenti. |
| `1impegno.it` | `brands/impegno/home#index`, layout `landing`, con area operativa | Non indicato nel YAML Domain | Title/description presenti | Separare chiaramente landing pubblica e applicazione autenticata; nessun calendario personale nell'API pubblica. |
| `igieneposturale.it` | `landing#igieneposturale` | Non indicato nel YAML Domain | Metadata specifici non dichiarati | Completare identità e decidere il Node radice. |
| `ilgiardinodelcorpo.it` | `landing#giardino_del_corpo`, layout `landing` | `ilgiardinodelcorpo` | Title/description presenti; loghi non dichiarati | Preparare asset e ingresso Node; eventi/luoghi arriveranno dopo tramite Skill. |
| `corpoecoscienza.org` | `brands/corpo_e_coscienza#index`, layout `landing` | `corpoecoscienza` | Metadata, loghi, favicon e social image presenti | Conservare richieste e contatti fuori dalla proiezione pubblica Domain/Node. |

Prime osservazioni trasversali:

- il layout `landing` centralizza già gran parte dei metadata e degli asset, ma alcune pagine seguono percorsi differenti;
- `public_node` carica anche Tailwind tramite CDN oltre agli asset locali: è una priorità di verifica PageSpeed e coerenza;
- molte viste contengono CSS e JavaScript inline; occorre misurare soltanto quelle realmente raggiunte dalle route pubbliche, non le copie legacy presenti nella repository;
- non tutti i domini dichiarano `node_slug`, anche quando un Node omonimo esiste in `config/nodes.yml`;
- loghi, favicon e social image non sono completi per tutti gli host;
- la prima implementazione non deve aggiungere Skill: deve rendere uniforme l'ingresso del dominio e dei suoi Node pubblici.

## 3. Audit SEO

| Funzionalità | Stato attuale | Problema | Soluzione proposta | Priorità |
|---|---|---|---|---|
| Sitemap XML | **Implementato:** `/sitemap.xml` usa il Domain corrente e compone root, path configurati, contenuti pubblicati, Node pubblici interni e prodotti pubblici delle Skill. | Le future Skill specializzate dovranno registrare le proprie collezioni nello stesso livello condiviso. | Estendere `PublicDiscovery` senza aggiungere sitemap parallele. | P0 |
| `robots.txt` | **Implementato:** risposta dinamica per host, sitemap canonica e blocchi per aree amministrative/private e URL con query. | Le policy andranno riviste quando nasceranno API e discovery pubbliche. | Mantenere una sola policy per dominio e aggiungere esplicitamente i nuovi endpoint pubblici. | P0 |
| Host canonici | **Verificato:** alias e percorsi Brand vengono rediretti al dominio previsto. | Serve controllare in produzione catene, protocolli, `www` e tutte le combinazioni di route. | Test HTTP read-only e matrice host/percorso; mantenere un solo salto 301. | P0 |
| Canonical per pagina | **Implementato nei layout pubblici:** usa l'host canonico del Domain e il path senza parametri. Alias e host alternativi vengono rediretti; i prodotti hanno un URL pubblico stabile. | Le future risorse specializzate dovranno conservare lo stesso contratto. | Conservare la generazione condivisa e testare i nuovi tipi di risorsa. | P1 |
| Title e description | **Verificato:** fallback per Domain e supporto `content_for`; 112 occorrenze di metadata specifici nelle viste considerate. | Copertura e qualità non sono validate automaticamente; alcune pagine potrebbero ereditare descrizioni generiche. | Inventario automatico degli URL pubblici con controllo unicità, lunghezza e fallback. | P1 |
| Open Graph/Twitter | **Verificato:** implementati nei layout principali. | Immagini spesso quadrate/logo; mancano tipologie specifiche per article/profile/event/video. | Metadata specifici per risorsa e immagini social 1200×630 dove disponibili. | P1 |
| Schema.org / JSON-LD | **Implementato:** base `WebSite`, `WebPage`, `Person` o `Organization`, breadcrumb Node e primo mapping generico `Article`, `Course`, `Event`, `Service`, `Place`, `HowTo` o `CreativeWork` per i prodotti. | Ogni Skill specializzata deve ancora validare campi e tipo propri. | Ampliare i metadata senza inventare dati mancanti. | P0 |
| Link interni | **Verificato:** nav e collegamenti tra molti Brand esistono; Flowpulse e GeneraImpresa offrono cataloghi. | La relazione Brand → progetto → professionista → contenuto non è esposta uniformemente e può dipendere da YAML diversi. | Hub pubblico della rete con link HTML crawlable e relazione semantica coerente. | P1 |
| Articoli | **Verificato:** cataloghi con slug, autore, data, dominio e filtri draft/scheduled. | Sitemap incompleta e assenza `Article` JSON-LD; non tutti i cataloghi sono compresi da `DomainContentCatalog`. | Normalizzare il contratto pubblico dei contenuti e includere soltanto record pubblicabili. | P0 |
| Corsi/capitoli | **Verificato:** route e repository PosturaCorretta presenti. | Mancano sitemap completa, `Course`/`LearningResource`, autore/editore e policy canonica documentata. | Indice pubblico dei corsi e JSON-LD; capitoli indicizzabili soltanto quando lo show è realmente accessibile. | P1 |
| Eventi | **Verificato:** catalogo cross-domain e route pubbliche; alcuni dati pubblici sono ancora mock nel controller eventi. | URL evento non sempre punta a uno show univoco; dati mock possono confondere indicizzazione e stato reale. | Separare demo e dati reali; URL stabile per evento e JSON-LD `Event`. | P0 |
| Professionisti | **Verificato:** elenchi/schede in Flowpulse, Percorso Integrato e PosturaCorretta. | Possibile duplicazione della stessa persona in domini diversi senza identità comune dichiarata. | `Person` con `sameAs`, identificatore stabile e ruoli specifici per Brand; canonical coerente per ciascuna funzione pubblica. | P1 |
| Video/social | **Verificato:** link YouTube e immagini esterne sono presenti in dati/viste. | Non esiste un catalogo ufficiale uniforme né `VideoObject`; embed e anteprime possono pesare. | Campi ufficiali `sameAs`, `VideoObject`, thumbnail e lazy loading; distinguere profilo ufficiale da semplice fonte. | P1 |
| Pagine private/bozze | **Verificato:** controlli applicativi e `noindex` per molte anteprime/admin; Inside Adventure è `noindex,nofollow`. | Serve una verifica complessiva degli status code: redirect a root per un Node nascosto può apparire come soft-404. | Preferire 404/410 coerenti per risorse non pubbliche anonime; testare header robots su ogni area sensibile. | P0 |

## 4. Audit AI Discovery

### 4.1 Cosa può comprendere oggi un agente

**Implementato.** Un agente può leggere landing e pagine pubbliche, JSON-LD,
`llms.txt` e gli endpoint versionati relativi all'host corrente. Può ottenere
l'identità del Domain, la struttura Node autorizzata e i prodotti pubblici
generici delle Skill senza accedere a dati amministrativi o riservati.

Limiti principali:

- manca ancora un endpoint trasversale dell'intero ecosistema; l'API attuale è
  correttamente circoscritta al dominio richiesto;
- ProblemSolving e definizioni amministrative delle Skill restano esclusi;
  Node e prodotti pubblici hanno invece una rappresentazione JSON stabile;
- autori, publisher, versioni, `sameAs` e fonti sono presenti in modo disomogeneo;
- i tipi JSON-LD generici esistono, ma i contratti specializzati devono ancora
  distinguere pienamente corso, evento, servizio, luogo e professionista;
- alcuni contenuti di sviluppo sono volutamente pubblici ma `noindex`, altri sono dashboard private: una discovery futura deve conservarne la distinzione;
- non è presente una ricerca pubblica trasversale verificata.

### 4.2 Manifesto pubblico proposto

**Proposto.** Aggiungere una proiezione read-only, per esempio `/discovery` in HTML e `/api/v1/discovery` in JSON, contenente:

- identità dell'ecosistema e versione del contratto;
- Brand pubblici con tipo, dominio canonico, descrizione e link;
- Node pubblici esplicitamente autorizzati, senza rivelare la struttura privata;
- collezioni pubbliche prodotte dalle Skill attive: contenuti, corsi, servizi, professionisti, luoghi e canali ufficiali;
- eventi descritti attraverso `DataSession` e disponibilità/programmazione attraverso `DataSlot`, senza esporre i DataCommitment personali;
- eventuali problemi, ragionamenti e soluzioni che il creatore abbia scelto esplicitamente di pubblicare;
- relazioni tipizzate (`belongs_to_brand`, `authored_by`, `offered_by`, `located_at`, `uses_skill`);
- data di aggiornamento e URL canonico;
- link alle collezioni paginabili.

La proiezione dovrebbe derivare da servizi/policy condivisi, non interrogare indiscriminatamente tutti i record.

**Base Domain/Node/risorse implementata.** `PublicDiscovery::Projection` produce già
l'identità pubblica del dominio, il Node radice e i Node pubblici attraversabili.
Interrompe i rami privati, rappresenta i ponti come relazioni e tratta i
sotto-Brand con dominio proprio come confini. Sitemap e JSON-LD usano questa
stessa proiezione. I prodotti generici delle Skill sono già proiettati come
risorse; contenuti, corsi, servizi, professionisti, luoghi, sessioni e slot
riceveranno contratti specializzati progressivamente. ProblemSolving rimane
escluso per impostazione predefinita.

Ogni dominio dovrebbe dichiarare soltanto le collezioni che ha realmente attivato. Un Brand personale potrebbe esporre profilo, servizi, contenuti, luoghi e canali; PosturaCorretta potrebbe esporre anche corsi, professionisti, sessioni e slot. La discovery non deve presupporre che tutti i domini abbiano la stessa quantità di dati, ma deve offrire lo stesso contratto per ogni tipo di risorsa.

Le ricerche AI dovrebbero poter collegare, quando pubblici, elementi differenti senza confonderne la natura:

```text
problema → soluzione validata → contenuto o servizio → professionista
        → Skill utilizzata → Brand/Node → sessione e slot → luogo/canale
```

### 4.3 `llms.txt`

**Implementato per dominio canonico pubblico.** È generato dalla stessa
proiezione di sitemap e API, elenca struttura e risorse pubbliche e può essere
disattivato nelle impostazioni del Domain. Rimane un indice editoriale utile,
non uno standard universalmente applicato e non sostituisce:

- robots e sitemap;
- HTML accessibile e link interni;
- JSON-LD;
- autenticazione/autorizzazione;
- API o MCP;
- termini d'uso e controlli tecnici.

Il documento viene generato per dominio e punta esclusivamente a URL canonici e
pubblici.

## 5. API e MCP

### 5.1 Stato corrente

**Implementato.** Esiste il namespace pubblico read-only `/api/v1` per Domain,
Node e risorse generiche. Usa schema versionato, URL canonici, CORS pubblico,
cache, ETag e risposte `404` stabili per elementi non pubblici. Non sono ancora
presenti OpenAPI, ricerca trasversale, rate limit dedicato o server MCP.

### 5.2 Alternative

| Alternativa | Vantaggi | Limiti/prerequisiti | Raccomandazione |
|---|---|---|---|
| HTML + JSON-LD | Massimo beneficio immediato per motori, link e AI browser; nessuna autenticazione speciale. | Non è ideale per query complesse o grandi collezioni. | Prima scelta per Fase 1. |
| Endpoint discovery JSON | Contratto piccolo, cacheabile e facilmente consumabile; chiarisce la rete. | Richiede policy pubblica e schema/versione. | Primo endpoint della Fase 2. |
| API REST read-only | Paginazione, filtri, ricerca e risorse tipizzate; riusabile dal frontend e da MCP. | Richiede versionamento, rate limit, serializzazione, errori e documentazione. | Costruire dopo il manifesto discovery. |
| Markdown pubblico | Utile per contenuti editoriali e agenti; semplice da leggere. | Perde parte delle relazioni e può duplicare HTML; attenzione a canonical e contenuti riservati. | Opzionale per singoli contenuti pubblici. |
| Server MCP | Offre strumenti descritti e accesso guidato agli agenti; può supportare autenticazione. | Ecosistema client variabile, superficie di sicurezza maggiore, necessita API/policy stabili e audit log. | Fase 3, come adattatore sopra servizi già testati. |
| RAG/ricerca semantica | Ricerca concettuale su molti contenuti e relazioni. | Costi, aggiornamento indici, provenienza, cancellazione, privacy e valutazione della qualità. | Solo Fase 4. |

### 5.3 API minima proposta

**Primo rilascio implementato**, relativo al dominio della richiesta:

- `GET /api/v1/domain`
- `GET /api/v1/nodes`
- `GET /api/v1/nodes/:slug`
- `GET /api/v1/resources`
- `GET /api/v1/resources/:id`

Questi endpoint descrivono identità del dominio, Node radice, Node pubblici e relazioni navigabili. Un sotto-Brand con dominio proprio compare come collegamento e viene poi interrogato sul proprio host. L'API applica la stessa policy del sito anonimo e non attraversa Node privati, per iscritti o riservati.

**Estensioni future registrate dalle Skill attive:**

- `GET /api/v1/contents`
- `GET /api/v1/contents/:slug`
- `GET /api/v1/services`
- `GET /api/v1/sessions`
- `GET /api/v1/slots`
- `GET /api/v1/places`
- `GET /api/v1/channels`
- `GET /api/v1/professionals`
- `GET /api/v1/search?q=...`

Le stesse collezioni possono essere interrogate nel contesto di un singolo Node:

- `GET /api/v1/nodes/:node_slug/skills`
- `GET /api/v1/nodes/:node_slug/contents`
- `GET /api/v1/nodes/:node_slug/courses`
- `GET /api/v1/nodes/:node_slug/sessions`
- `GET /api/v1/nodes/:node_slug/places`
- `GET /api/v1/nodes/:node_slug/services`

**ProblemSolving, separato dalle Skill:**

- `GET /api/v1/nodes/:node_slug/problem-solvings`
- `GET /api/v1/nodes/:node_slug/problem-solvings/:id`

Le route aggregate del dominio restituiscono i prodotti pubblici di tutti i suoi Node accessibili; le route annidate restituiscono quelli del solo Node. L'elenco `skills` descrive le capacità attive sul Node, mentre contenuti, corsi, sessioni e luoghi sono i prodotti di quelle capacità.

Node, ProblemSolving e Skill non devono essere pubblicati per semplice appartenenza al modello. Si riusano stato, visibilità e accessibilità anonima già applicati dal sito, senza introdurre campi AI paralleli. I ProblemSolving sono privati per impostazione predefinita, ma il creatore può in futuro pubblicarne una rappresentazione ordinaria. NodeEvent, processi interni, DataCommitment e richieste restano privati salvo una futura vista pubblica deliberata. Sessioni e slot pubblici devono essere separati dagli impegni e dalle partecipazioni personali.

### 5.4 MCP proposto

Il server MCP dovrebbe essere un adattatore sottile sui servizi dell'API, con strumenti iniziali come:

- `list_public_brands`
- `get_public_brand`
- `search_public_content`
- `get_public_content`
- `search_public_solutions`
- `list_public_sessions`
- `list_public_places`
- `list_public_professionals`

Solo in seguito, con autenticazione e scope:

- consultazione dei Node autorizzati;
- consultazione delle Skill accessibili;
- calendario e DataCommitment dell'utente;
- azioni mutanti, ciascuna con conferma e autorizzazione esplicita.

L'accesso autenticato deve riusare policy condivise, non limitarsi a riconoscere il client MCP. Il server non deve fidarsi del solo `User-Agent`.

## 6. Performance e sicurezza

### 6.1 Stato verificato

- produzione con asset digestati e cache annuale;
- `SolidCache`, `SolidQueue` e `SolidCable` configurati;
- SSL forzato, HSTS e host authorization;
- Thruster disponibile per caching/compressione del traffico;
- rate limit per login, recupero password e listing pubblici PosturaCorretta;
- immagini prevalentemente servite anche tramite ImageKit;
- CSP presente soltanto come configurazione commentata, quindi non risulta applicata;
- logging standard con request ID, senza classificazione verificata dei client AI;
- assenza verificata di Rack::Attack o di una policy globale per crawler/API;
- alcune viste caricano Tailwind da CDN e contengono CSS/JS inline, elemento da misurare e consolidare.

### 6.2 Core Web Vitals e tempi di risposta

**Da verificare in produzione.** La lettura statica non misura LCP, INP, CLS, TTFB, peso delle pagine o cache hit ratio. Occorre raccogliere:

- Lighthouse/PageSpeed su una pagina rappresentativa per dominio;
- dati real-user, se compatibili con la privacy;
- tempi Rails/DB p50, p95 e p99;
- dimensione HTML/CSS/JS e richieste a terze parti;
- impatto di immagini, iframe YouTube, font e script inline;
- cache hit/miss di Solid Cache.

### 6.3 Query e caching

**Verificato:** alcuni controller/cataloghi caricano YAML e percorrono collezioni o filesystem a ogni richiesta; sono presenti preload mirati in varie aree. **Da verificare:** query N+1 e costo reale sui dataset di produzione.

**Proposto:** profilare prima di ottimizzare; poi cache per dominio/versione dei cataloghi pubblici, ETag/Last-Modified per sitemap/API/contenuti e preload delle relazioni usate dai serializer.

### 6.4 Protezione da traffico abusivo

**Proposto:** applicare limiti diversi a:

- HTML pubblico;
- sitemap/robots/discovery;
- ricerca e API;
- endpoint costosi o dipendenti da provider esterni;
- autenticazione e azioni mutanti.

Prevedere risposte `429`, `Retry-After`, cache condivisa e limiti per token oltre che per IP sugli accessi autenticati. IP e User-Agent non identificano con certezza una persona o un servizio.

### 6.5 Logging AI e privacy

Separare:

- **identità verificata:** token/API key, OAuth, certificati o reverse DNS verificato secondo la documentazione del provider;
- **identità dichiarata:** User-Agent o header fornito dal client;
- **segnali tecnici:** IP, ASN, frequenza, endpoint e status code.

Non attribuire automaticamente una richiesta a ChatGPT, Claude o Gemini dal solo User-Agent. Conservare soltanto dati necessari, con durata definita, accesso limitato, mascheramento/anomizzazione dove possibile e informativa coerente. Non registrare query o risposte contenenti dati personali senza una base e uno scopo definiti.

## 7. Piano di implementazione

### Fase 1 — MVP: domini, landing, SEO e Node pubblici

1. Inventariare come viene renderizzato ciascun dominio e quali layout, CSS, JavaScript e sorgenti usa.
2. Definire il contratto minimo del dominio: identità, host canonico, Node radice, lingua, Site, title, description, loghi e collegamenti ufficiali.
3. Definire un ingresso HTML standard alla struttura dei Node pubblici, rispettando il confine dei sotto-Brand con dominio proprio.
4. Misurare PageSpeed/Core Web Vitals e ridurre CSS/JavaScript inline, dipendenze CDN, immagini e video non ottimizzati.
5. Rendere sitemap e robots dinamici per host.
6. Uniformare canonical, Open Graph, Twitter Card e JSON-LD `WebSite`/`Organization` o tipo equivalente.
7. Applicare una sola policy: l'ingresso pubblico mostra esclusivamente ciò che può vedere un visitatore anonimo.
8. Verificare status code, soft-404, pagine duplicate, filtri e prototipi `noindex`.
9. Applicare lo standard progressivamente a tutti i domini, iniziando da Flowpulse e PosturaCorretta.

La standardizzazione SEO segue una responsabilità unica per livello:

| Livello | Dati e output da standardizzare |
|---|---|
| Domain | canonical, lingua, metadata di fallback, loghi, riferimenti ufficiali, `WebSite`, soggetto principale, sitemap e robots |
| Node | identità pubblica, tipo, descrizione, relazioni e soggetto strutturato professionale/progetto |
| Skill | contratto con cui registra le collezioni prodotte; il plugin non riceve metadata SEO duplicati |
| Prodotto della Skill | URL, metadata editoriali, autore/produttore, stato, visibilità e JSON-LD specifico della risorsa |
| ProblemSolving | nessuna esposizione predefinita; eventuale rappresentazione editoriale pubblica distinta dagli appunti interni |

PageSpeed non diventa un attributo di Domain, Node, Skill o ProblemSolving. Il
Domain è l'unità di misurazione, mentre Site, layout, componenti, asset e
rendering sono l'unità tecnica di intervento. Baseline e verifiche datate
devono stare in report tecnici ripetibili.

La root Flowpulse non richiede Node contenitore chiamati “Brand progetto” e
“Brand professionali”. Le due categorie sono viste generate da `node_type` sui
Node che possiedono un Domain. `parent_id` deve descrivere soltanto
appartenenze reali. Per esempio Igiene Posturale potrà essere un discendente di
PosturaCorretta, anche attraverso più Node intermedi; non si presume che sia un
figlio diretto. Se il Node che ne rappresenta la radice viene collegato a
`igieneposturale.it`, diventa anche un sotto-Brand pubblico. Il dominio padre
lo espone come confine e collegamento, senza attraversarne automaticamente
l'albero interno.

La struttura dei Node è variabile. `parent_id` esprime la gerarchia corrente;
un Node ponte esprime una relazione trasversale senza modificare quella
gerarchia. Il Domain non contiene una copia dell'albero e non ne dipende dalla
profondità: punta al proprio Node radice e la proiezione pubblica viene
calcolata da lì, applicando stato, visibilità e confini degli altri Domain.

Contratto proposto:

- un Node può avere uno o più Domain;
- ogni Domain dichiara Node radice, lingua e Site (`site_key`);
- la riorganizzazione dei discendenti non richiede di modificare il Domain;
- i Node ponte vengono esposti come relazioni e non come figli;
- più Domain possono condividere lo stesso Site;
- lo stesso Node può usare Site differenti quando cambia realmente la
  presentazione editoriale;
- gli alias tecnici usano l'host canonico;
- le traduzioni non sono alias: hanno canonical, sitemap e `hreflang` propri.

### Fase 2 — API pubblica del dominio e dei Node

1. Servizio condiviso `PublicDiscovery` che riusa la policy del rendering HTML anonimo.
2. Endpoint relativi all'host corrente: `GET /api/v1/domain`, `GET /api/v1/nodes` e `GET /api/v1/nodes/:slug`.
3. Rappresentare i sotto-Brand come collegamenti al proprio dominio senza attraversarne internamente l'albero dal dominio padre.
4. Esporre soltanto identità del dominio, Node pubblici, relazioni pubbliche e URL canonici; nessuna Skill è necessaria per il primo rilascio.
5. Aggiungere versionamento, ETag/Last-Modified, cache, rate limit, documentazione e test di non-esposizione.

### Estensione progressiva — Skill e collezioni

1. Attivare le Skill una alla volta sui Brand che ne hanno bisogno.
2. Standardizzare per prima la Skill Contenuti usando i dati YAML/Markdown esistenti.
3. Far registrare a ogni Skill le proprie collezioni pubbliche, per esempio contenuti, corsi, sessioni, servizi, luoghi o canali.
4. Definire produttore e ruoli della risorsa senza confonderli con creatore o proprietario del Brand.
5. Collegare ogni prodotto a un Node principale e, soltanto quando serve, ad altri Node secondari.
6. Estendere l'API con collezioni aggregate del dominio e collezioni specifiche del Node, senza cambiare il contratto base.
7. Conservare la policy pubblica unica anche per tutte le risorse prodotte.
8. Esporre separatamente i ProblemSolving associati ai Node soltanto quando possiedono una rappresentazione pubblica ordinaria.

### Fase 3 — MCP

1. Definizione dei casi d'uso e dei client supportati.
2. Server MCP read-only sopra i servizi API.
3. Autenticazione e scope per risorse non pubbliche.
4. Audit log minimizzato e revoca delle credenziali.
5. Valutazioni automatiche su autorizzazioni, citazioni e completezza.

### Fase 4 — RAG avanzato

1. Corpus pubblico con provenienza, versione e diritto di indicizzazione.
2. Chunking coerente con articoli/capitoli, senza separare autore e fonte.
3. Indice semantico aggiornabile e cancellabile.
4. Ricerca ibrida lessicale + vettoriale.
5. Valutazioni su precisione, citazioni, obsolescenza e leakage tra Brand/utenti.

## 8. Checklist operativa

| Attività | Priorità | Complessità | File probabilmente coinvolti | Dipendenze | Criterio di completamento | Rischi |
|---|---:|---:|---|---|---|---|
| Inventariare il rendering di ogni dominio | P0 | Media | `config/domains.yml`, `config/routes.rb`, controller, layout e landing | Nessuna | Tabella per host con target, layout, Node radice, asset, metadata e criticità | Trascurare route servite sia da host sia da prefisso |
| Definire il contratto standard del dominio | P0 | Alta | `app/models/domain.rb`, `app/models/node.rb`, `config/domains.yml`, documentazione architetturale | Inventario domini | Ogni dominio dichiara identità, Node radice, lingua, Site, metadata e ingresso pubblico senza dipendere dalle Skill | Creare Node contenitore artificiali o confondere alias e traduzioni |
| Standardizzare l'ingresso HTML ai Node | P0 | Alta | `domains_controller.rb`, `nodes_controller.rb`, layout/viste pubbliche | Contratto del dominio e policy anonima | Ogni dominio permette di scoprire soltanto il proprio albero pubblico e si ferma ai sotto-Brand | Esporre discendenti privati o duplicare sotto-Brand |
| Misurare e migliorare PageSpeed per dominio | P0 | Media | layout, CSS, JavaScript, immagini, video, deploy/cache | Inventario rendering e accesso produzione | Baseline e obiettivi verificati per landing rappresentative | Ottimizzazioni generiche che alterano UX |
| Pubblicare API read-only Domain/Node | P0 | Alta | nuovo service/policy, routes e controller API | Ingresso HTML e policy pubblica stabili | `/api/v1/domain`, `/api/v1/nodes` e show restituiscono lo stesso insieme visibile anonimamente | Leakage o contratto prematuro |
| Formalizzare Skill come plugin | P1 | Alta | `app/models/reusable_skill.rb`, collegamenti Skill/Node, futura configurazione di attivazione | Contratto e API base del dominio | Una Skill definisce funzione, risorsa prodotta, ruoli e processo ed è attivabile in più Brand | Confondere Skill, risorsa prodotta e ProblemSolving |
| Standardizzare la Skill Contenuti | P1 | Alta | `DomainContentCatalog`, cataloghi YAML/Markdown, viste editoriali | Contratto Skill e infrastruttura dominio | I contenuti esistenti usano un contratto comune senza migrazione distruttiva | Perdere metadati specifici dei Brand |
| Definire responsabilità del produttore | P1 | Media | ruoli, policy e futuri collegamenti alle risorse | Contratto Skill | Ogni risorsa indica chi può produrla e mantenerla | Sovrapporre creatore, proprietario e produttore |
| Definire la policy pubblica unica | P0 | Alta | policy Node, cataloghi, futuri concern/service di pubblicazione | Ruoli e contratto risorse | HTML pubblico, sitemap, JSON-LD, API e MCP restituiscono lo stesso insieme anonimamente accessibile | Esposizione accidentale o fonti di verità divergenti |
| Definire proiezione pubblica del ProblemSolving | P1 | Media | `problem_solving_cycle.rb`, future policy/serializer | Regole del creatore | Il creatore può pubblicare parti selezionate senza esporre appunti interni | Pubblicare ragionamenti o persone non autorizzati |
| Standardizzare sessioni, slot e luoghi pubblici | P1 | Alta | `data_session.rb`, `data_slot.rb`, Place, cataloghi eventi | Skill Eventi/Luoghi | Eventi e disponibilità sono ricercabili senza esporre DataCommitment personali | Confondere programma pubblico e calendario personale |
| Standardizzare canali e riferimenti ufficiali | P1 | Media | cataloghi professionisti/Brand, nuovi dati comuni | Identità Brand/persona | Sito, social, YouTube e fonti hanno tipo, URL, titolare e ufficialità | Dichiarare come ufficiale un riferimento non verificato |
| Inventariare URL pubblici per dominio | P0 | Media | `config/routes.rb`, `config/domains.yml`, cataloghi in `config/data/` | Regole di pubblicazione | Elenco ripetibile con URL, tipo, stato e canonical | Omettere route dinamiche o includere bozze |
| Rendere sitemap domain-aware | P0 | Media | `app/controllers/sitemaps_controller.rb`, `app/views/sitemaps/show.xml.builder` | Inventario URL | Ogni host elenca solo URL canonici pubblici propri | Duplicati e contenuti futuri |
| Rendere robots domain-aware | P0 | Bassa | `public/robots.txt` o nuova route/controller | Sitemap per dominio | Ogni dominio indica la propria sitemap e protegge aree private | Bloccare per errore risorse pubbliche |
| Testare redirect e canonical | P0 | Media | `canonical_brand_host.rb`, `domains_controller.rb`, `seo_helper.rb` | Matrice domini | Un solo 301 verso host/URL canonico e canonical coincidente | Loop o canonical cross-domain |
| Aggiungere JSON-LD WebSite/Organization | P0 | Bassa | layout/helper SEO, `config/domains.yml` | Identità ufficiali | Output valido per ogni dominio pubblico | Dati organizzativi non concordati |
| Aggiungere JSON-LD alle risorse | P0 | Media | viste articoli, corsi, eventi, professionisti | Schema dei metadati | Validazione Schema.org senza campi inventati | Mescolare ruoli e identità personali |
| Eliminare soft-404 pubblici | P0 | Bassa | `nodes_controller.rb`, controller contenuti | Decisione 404/410 | Risorse invisibili restituiscono risposta coerente | Cambiare UX degli utenti autenticati |
| Separare demo/mock dagli eventi pubblici | P0 | Media | `public_events_controller.rb`, cataloghi eventi | Fonte eventi reale | Nessun evento fittizio appare indicizzabile | Perdita temporanea di contenuto demo |
| Costruire hub HTML della rete | P1 | Media | viste Flowpulse/GeneraImpresa, `FlowpulseProjectRegistry` | Tassonomia Brand | Tutti i Brand pubblici sono divisi dinamicamente per `node_type` e hanno link, tipo e dominio ufficiale | Divergenza tra YAML e DB o categorie trasformate in Node fittizi |
| Definire identità professionista e `sameAs` | P1 | Media | cataloghi professionisti e viste | Identificatore persona | Schede cross-domain collegabili senza duplicazione ambigua | Privacy e consenso |
| Ottimizzare immagini/video | P1 | Media | viste e cataloghi media | Audit CWV | Dimensioni, lazy loading e thumbnail coerenti | Regressioni visive |
| Creare `llms.txt` per dominio | P2 | Bassa | nuova route/template o file generati | URL stabili | Solo link canonici pubblici e descrizione breve | Affidarsi eccessivamente a supporto non uniforme |
| Definire `PublicDiscovery` | P0 | Alta | nuovo service/policy | Regole di visibilità consolidate | Stesso risultato tra HTML, JSON e test policy | Leakage di strutture private |
| Pubblicare API v1 read-only | P1 | Alta | routes, controller API, serializer/Jbuilder | `PublicDiscovery` | Contratto versionato, paginato e documentato | Scraping abusivo e breaking changes |
| Aggiungere ETag/cache API | P1 | Media | controller/API/cache | API stabile | 304 corretto e invalidazione prevedibile | Dati obsoleti |
| Rate limit per discovery/API | P0 | Media | controller/config/cache | Endpoint definiti | 429/Retry-After e limiti misurabili | Penalizzare crawler legittimi/NAT |
| Documentare API | P1 | Media | `docs/`, eventuale OpenAPI | Contratto API | Specifica validabile ed esempi senza dati privati | Documentazione non aggiornata |
| Implementare MCP read-only | P2 | Alta | nuovo adapter/server | API e auth stabili | Tool discovery, risposte citate e policy testate | Nuova superficie di attacco |
| Definire retention log AI/API | P0 | Media | privacy/config/logging | Valutazione privacy | Scopo, campi, accessi e durata documentati | Raccolta eccessiva di dati |
| Misurare CWV e backend | P0 | Media | osservabilità/deploy | Accesso produzione | Baseline p50/p95/p99 e CWV per dominio | Decisioni basate su test locali |
| Valutare CSP effettiva | P1 | Media | `content_security_policy.rb`, viste inline/CDN | Inventario script/style | Policy report-only senza violazioni critiche, poi enforcement | Rottura di inline script/CDN |
| Preparare corpus RAG | P2 | Alta | cataloghi/contenuti, nuovo indice | API, provenienza e privacy | Ogni frammento conserva fonte, autore, versione e URL | Materiale riservato o obsoleto |

## 9. Raccomandazione finale

Le cinque attività con il miglior rapporto beneficio/intervento sono:

1. **Inventario tecnico dei domini:** chiarisce per ogni host rendering, layout, Node radice, asset e metadata prima di intervenire.
2. **Contratto standard del dominio:** stabilisce identità, landing, ingresso ai Node e policy pubblica comune, senza dipendere dalle Skill.
3. **PageSpeed e SEO condivisi:** sistema sitemap, robots, canonical, JSON-LD e asset nella base comune e poi verifica ogni landing.
4. **Ingresso pubblico ai Node:** rende la struttura navigabile sul sito rispettando pubblicazione, visibilità e confini dei sotto-Brand.
5. **API read-only Domain/Node:** offre alle AI una porta stabile sulla stessa struttura anonimamente visibile; le Skill aggiungeranno collezioni in seguito.

Soltanto dopo questa base conviene standardizzare la Skill Contenuti e poi le altre Skill. Prima di MCP occorre osservare l'uso dell'API Domain/Node e delle prime collezioni. L'interfaccia pubblica deve esporre soltanto relazioni deliberate e stabili.

La sintesi architetturale aggiornata è:

> I Node costruiscono la mappa dei Brand e dei progetti. Il ProblemSolving permette al creatore di cercare e validare soluzioni. Le Skill sono plugin attivabili nei Brand e producono risorse concrete gestite dai rispettivi produttori. Il proprietario del Brand e il creatore definiscono i confini; ogni risorsa conserva stato e visibilità propri. Le AI pubbliche possono consultare soltanto ciò che può consultare un visitatore anonimo.

## 10. Controlli non completabili con la sola repository

- Risposte HTTP e redirect effettivi in produzione per ogni combinazione host/percorso.
- Contenuto realmente servito da `robots.txt` e sitemap dietro proxy/CDN.
- Stato DNS, certificati TLS, redirect del proxy e comportamento della cache edge.
- Copertura reale negli indici Google/Bing e accessi dei crawler AI.
- Supporto effettivo di `llms.txt` da parte dei singoli servizi al momento della pubblicazione.
- Core Web Vitals, TTFB, peso pagina, cache hit ratio e tempi PostgreSQL reali.
- Query N+1 e piani SQL sui dati di produzione.
- Configurazione effettiva di compressione/CDN/ImageKit e trasformazioni applicate alle immagini.
- Identità ufficiali, account social, canali YouTube e consenso a esporre `sameAs` per ogni persona/Brand.
- Completezza e correttezza editoriale dei dati Schema.org non ancora definiti.
- Retention, accessi e contenuto dei log di produzione.
- Volume di traffico atteso e soglie appropriate di rate limiting.
- Requisiti legali/privacy per analytics, logging AI, API autenticata e indicizzazione dei profili.
- Client MCP da supportare, meccanismo di autenticazione e compatibilità con l'infrastruttura di deploy.
