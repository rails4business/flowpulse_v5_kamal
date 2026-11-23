# Contenuti e pubblicazioni — piano di lavoro

Struttura dati unificata per i contenuti editoriali e la loro distribuzione sulle piattaforme
(sito, YouTube, Instagram, Vimeo, Substack, LinkedIn, X, altre future).

Il piano si verifica **un punto alla volta**: ogni punto passa da ⏳ a ✅ solo dopo la conferma.
L'implementazione parte quando tutti i punti sono ✅.

## Vincoli

- Non modificare: `docs/posturacorretta_consapevolezza.md`, la home di PosturaCorretta, la pagina/node
  Consapevolezza, la navigazione di PosturaCorretta.
- Nessuna migrazione distruttiva: YAML e Markdown restano finché un punto non dice il contrario.
- Preservare URL e slug esistenti. Lo stato di pubblicazione invece cambia regola (vedi punto 1).
- Non inventare piattaforme, ruoli, tassonomie o valori che non sono nel repository: chiedere.
- Non toccare modifiche non correlate presenti nel worktree.

## Modello concettuale (da confermare punto per punto)

- **Content** — il contenuto editoriale, indipendente dalla piattaforma: dominio/brand, id stabile, slug,
  titolo, descrizione, corpo o riferimento al Markdown, formato principale, tassonomia, stato, visibilità,
  autore, collaboratori, date editoriali.
- **ContentPublication** — il Content su una piattaforma: piattaforma, formato (articolo, post, newsletter,
  video, reel, short, thread, live…), URL, id esterno, titolo e testo adattati, stato, data programmata ed
  effettiva, posizione, metadata. Un Content ha più pubblicazioni; il sito non è obbligatorio.
- **ContentContribution** — Content + soggetto + ruolo (autore, esperto, conduttore, videomaker, revisore,
  editor, altro).
- **DataCommitment** — il lavoro e lo storico delle decisioni, non il contenitore del contenuto.
- **SavedContent** — i contenuti salvati da una persona (al posto di ContentProgress, vedi punto 8).
  L'avanzamento nei corsi resta sugli impegni.

---

## Punto 1 — Chi decide se un contenuto è pubblicato ✅

**Oggi** lo stato di pubblicazione ha tre meccanismi:

| Contenuti | Chi decide | Dove |
|---|---|---|
| Corsi e capitoli (`config/data/brands/posturacorretta/courses/*/course.yml`) | L'ultima DataCommitment `kind: "content"` conclusa, con `content_key` = `id` (o `slug`), legata al nodo che pubblica | `app/controllers/posturacorretta/learning_controller.rb` (`chapter_publication_history`, `publication_commitments_by_scope`), `app/views/posturacorretta/learning/_publication_admin_bar.html.erb` |
| Articoli del catalogo (`config/data/posturacorretta/contenuti/catalog.yml`) | YAML: `status` + data da `publication_at` o dal nome del file | `app/services/domain_content_catalog.rb` |
| Contenuti del repository (`contents.yml`) | YAML: `status` draft/published/scheduled + `published_at` | `app/services/posturacorretta/content_repository.rb` |

`course.yml` ha già quasi la forma di Content: `id`, `parent_id`, `format`, `slug`, `position`, `status`,
`visibility`, `access`, `title`, `description`, `author_node_slug`, `publisher_node_slug`, `content_path`.

**Chiarito**: ogni contenuto sta sotto un node, che sia un articolo o un corso online. La differenza è solo
nella raccolta che lo contiene:
- **ordine per posizione** (corso → capitoli): la sequenza è fissa e decisa a mano;
- **ordine per data** (blog → articoli): la sequenza segue la data di pubblicazione.

Corso e articolo non sono quindi due sistemi diversi, ma lo stesso Content dentro raccolte che differiscono
solo per il criterio di ordinamento.

**Chiarito**: per contenuti e pubblicazioni vale lo stesso flusso dei node (`config/nodes.yml` →
`bin/rails nodes:import`):
- in sviluppo il YAML è la fonte e si importa nel database;
- testi e struttura si modificano solo nei YAML e nei Markdown, non dall'admin: nessun export dal database
  verso i file (deciso il 2026-11-19);
- le pagine leggono dal database.

Il YAML sta nel repository e viene importato **sia in sviluppo sia in produzione** a ogni deploy.

**Chiarito — cosa sta dove:**

| Dato | YAML (repository, import in sviluppo e produzione) | Database del singolo ambiente |
|---|---|---|
| Contenuto: id, slug, titolo, descrizione, Markdown, raccolta, posizione/data, autore | ✅ | copia importata |
| Dove è pubblicato: piattaforma, formato, URL, id esterno | ✅ | copia importata |
| Decisione pubblica / sospendi / archivia | ❌ | ✅ tramite impegni (DataCommitment) |

Le decisioni di pubblicazione vivono **solo nel database di ciascun ambiente**. Sviluppo e produzione possono
avere stati diversi, e va bene così. L'import non tocca mai lo stato di pubblicazione.

**Conseguenza**: vale per tutti i contenuti la regola che oggi hanno i capitoli. DataCommitment è il registro
delle decisioni (pubblica, aggiorna, correggi, sospendi, archivia; vince l'ultima conclusa). Il campo
`status` nel YAML non decide la pubblicazione.

**Deciso**: il comportamento cambia. Un contenuto importato per la prima volta parte sempre come bozza e
si pubblica con un impegno, in ogni ambiente. Lo `status` già presente nei YAML (23 capitoli `published`,
articoli del catalogo oggi visibili grazie al YAML e alla data del file) non crea decisioni di pubblicazione.
Quando una raccolta passa al nuovo sistema, i suoi contenuti vanno ripubblicati con gli impegni.

**Deciso**: quando una raccolta passa al nuovo sistema, il campo `status` si **toglie** dal YAML. La regola
vale per **tutti i domini**, non solo PosturaCorretta.

**Deciso**: anche **visibilità** (pubblico, privato, interno…) e **accesso** (gratuito, a pagamento) sono
decisioni di ciascun ambiente e si tolgono dal YAML insieme a `status`. L'impegno di pubblicazione li salva
già (`publication_visibility`, `access_modes`).

**Perimetro trovato** (file YAML in `config/data` con `status`):
- `brands/posturacorretta/courses/*` (9 corsi), `brands/posturacorretta/`, `brands/posturacorretta/development`;
- `books/il-corpo-un-mondo-da-scoprire/chapters` (56 file);
- `posturacorretta/contenuti`, `posturacorretta/accademia`, `posturacorretta/programmi`, `progetti`,
  `libri_pubblicati`, `guide`;
- `markpostura/contenuti`, `sites/markpostura_it/pages`;
- `rails4b/contenuti`, `generaimpresa`, `flowpulse`, `performance`, `people`.

Non tutti sono contenuti editoriali (es. `people`, `performance`): il punto 3 deve dire quali lo sono.

Attenzione: nei libri lo stato è scritto in `access` (`draft`, `hidden`, `hide`, `published`) invece che in
`status`, in `books/il-corpo-un-mondo-da-scoprire/chapters` e `brands/posturacorretta/books/`. Ci sono anche
cartelle che sembrano copie o archivi (`chapters copy`, `old_chapters_20260715`,
`old-il-corpo-un-mondo-da-scoprire`, `test-hidden-book`).

## Punto 2 — NodeContent come ponte Markdown → database ✅

**Oggi**:
- `NodeContent` è il **corpo della pagina di un node**: `has_one :content` su Node, `node_id` unico. Un node
  ha al massimo un corpo.
- Campi: `body_md`, `body_html`, `body_json`, rich text `body` (editor `lexxy`), `editor`, `format`, `data`,
  `source_path`, `source_checksum`.
- In sviluppo ci sono 170 record, tutti con editor `markdown`. Solo 9 hanno `source_path`: le metodiche,
  importate da `Posturacorretta::MethodologyNodeImporter` (Markdown → `body_md`, con checksum).
- Gli altri si scrivono dall'editor dei node (`creator_world/nodes_controller.rb`). La pagina li mostra in
  `app/views/nodes/show.html.erb` (rich text se presente, altrimenti Markdown).

**Conclusione**: NodeContent non può contenere i contenuti di una raccolta, perché ammette un solo corpo
per node, mentre un blog o un corso ne hanno molti. Il **meccanismo di import** però è riutilizzabile:
`source_path` + `source_checksum` + `body_md`, come fa l'importer delle metodiche.

**Deciso**: Content è una tabella nuova che `belongs_to :node` (la raccolta) e riusa lo stesso schema per
il corpo (`body_md`, `source_path`, `source_checksum`). NodeContent resta il corpo della pagina del node.
Articoli e capitoli non diventano node.

## Punto 3 — Quale catalogo è la fonte oggi ✅

**Oggi** ci sono due migrazioni a metà, entrambe verso `config/data/brands/<dominio>/`:

| Cosa | Vecchia fonte | Nuova fonte (canonica) | Chi legge |
|---|---|---|---|
| Corsi e capitoli (raccolte per posizione) | `posturacorretta/contenuti/contents.yml` (29 voci) | `brands/posturacorretta/courses/<corso>/course.yml` (88 voci in 9 corsi) | `Posturacorretta::ContentRepository`: la canonica sovrascrive la vecchia per `id` |
| Articoli (raccolte per data) | `<dominio>/contenuti/catalog.yml` + `articoli/<anno>/<data>-<slug>.md` | `brands/<dominio>/contents/<slug>/content.yml` + `content.md` (1 solo articolo finora) | `DomainContentCatalog`: la canonica arricchisce la voce del catalogo per `slug` |

- Tutte le 29 voci di `contents.yml` esistono anche nei `course.yml`: il file vecchio è già del tutto superato.
- Articoli: 426 in `posturacorretta/contenuti/catalog.yml`. I cataloghi di `markpostura` e `rails4b` hanno
  forme diverse: lista `articles:` per markpostura, lista `items:` con `kind` per rails4b (che mescola
  articoli, eventi, corsi e masterclass). PosturaCorretta li raggruppa per categoria.
- Oltre ai due servizi, leggono i cataloghi anche direttamente: `posturacorretta_controller.rb`
  (`catalog.yml`, `brands/posturacorretta/contents`), `landing_controller.rb` e `domains_controller.rb`
  (`rails4b/contenuti/catalog.yml`), `admin/content_taxonomy_controller.rb`.
- `tassonomia.yml` è la tassonomia (ambiti e sotto-ambiti), non un elenco di contenuti.
- `percorso.yml` descrive la struttura del percorso (quali corsi in quale sezione), non i contenuti.

**Deciso**: l'importer legge solo la forma canonica, `brands/<node>/courses/` per le raccolte per posizione
e `brands/<node>/contents/` per le raccolte per data, per tutti i domini. `<node>` è il node del progetto a
cui appartiene il contenuto; se non c'è un progetto, è il node di chi l'ha scritto (vedi punto 6).
I cataloghi vecchi si convertono in questa forma e poi si tolgono.

## Punto 4 — Date e regole di visibilità implicite ✅

**Oggi**: data dell'articolo dal nome del file o da `publication_at`; una data futura nasconde l'articolo
(visibile solo al superadmin) finché non arriva il giorno; date video (`data_registrazione_video`,
`data_pubblicazione_video`) solo organizzative.

**Deciso**:
- la data del YAML va su Content come **data di scrittura** e si importa come gli altri campi;
- non decide più la visibilità: niente pubblicazione automatica a una data futura, si pubblica con un impegno;
- una raccolta ordinata per data può ordinare per **data di scrittura** oppure per **data di aggiornamento**.

**Proposta**: il criterio di ordinamento è un'impostazione della raccolta (`position`, `written_on`,
`revised_at`), con il default scelto nel YAML della raccolta. Un eventuale selettore per il lettore si può
aggiungere dopo.

**Deciso**: la data di aggiornamento è una colonna dedicata di Content (`revised_at`), scritta dall'impegno
"Aggiorna" o "Correggi" quando si conclude. Vale per ambiente, come la pubblicazione. Non si usa `updated_at`
di Rails, che cambia a ogni salvataggio e quindi a ogni import.

**Deciso — dove sta la logica**: nel model. Oggi le regole delle decisioni di pubblicazione sono nel controller
(`brands/impegno/commitments_controller.rb`: `publication_status_for`, `assign_previous_publication_commitment`,
`published_at`). Vanno spostate in `Brands::Impegno::Commitment` (tabella `data_commitments`): quando un
impegno di pubblicazione passa a `completed`, un callback `after_commit` aggiorna il Content collegato
(stato, visibilità, accesso, `published_at`, e `revised_at` per "Aggiorna" e "Correggi"). Così la regola vale
da qualunque punto si concluda l'impegno: admin, barra editoriale, console o test.

## Punto 5 — Confini con Consapevolezza e home ✅

**Deciso**: per ora i confini restano come sono. La home, la pagina Consapevolezza e le letture dirette in
`posturacorretta_controller.rb` (`load_catalog` su `contenuti/catalog.yml`, `load_canonical_contents` su
`brands/posturacorretta/contents`) non passano al nuovo sistema in questa fase.

**Conseguenza sul punto 3**: `posturacorretta/contenuti/catalog.yml` e `brands/posturacorretta/contents/` non
si tolgono finché quelle pagine leggono da lì. La loro migrazione si decide separatamente.

## Punto 6 — Autori e collaboratori ✅

**Indicato dall'utente**: un contenuto appartiene al node del **progetto** (es. `posturacorretta`, tipo
`project`) e anche al node di **chi l'ha scritto** (es. `markpostura`, tipo `professional`). Se non c'è un
progetto, appartiene solo al node dell'autore.

**Oggi** nei YAML:
- `author: markpostura` (427 voci), `author_node_slug: markpostura` (81), `publisher_node_slug: posturacorretta` (85);
- `belleri`, `frapporti`, `damiata`: autori di articoli in `posturacorretta/contenuti/catalog.yml`, **senza
  un node** (in `config/nodes.yml` ci sono 2 node `professional`, tra cui `markpostura`);
- `author: Mark Postura` nell'intestazione di molti Markdown dei capitoli e in
  `brands/posturacorretta/books/postura-corretta-in-un-mese/book.yml`: è `markpostura` scritto per esteso;
- `Philippe E. Souchard`, `Godelieve Denys-Struyf`, `Léopold Busquet`… sono gli autori dei libri esterni della
  bibliografia (`posturacorretta/libri_pubblicati/biblioteca_postura.yml`), non autori di contenuti nostri.

**Indicato dall'utente**: `belleri`, `frapporti`, `damiata` non hanno ancora accettato il progetto, quindi
per ora non diventano node. Un collaboratore può essere un professionista senza node: insegnante
PosturaCorretta, professionista del Percorso Integrato, professionista digitale di Rails4Business, founder di
GeneraImpresa.

**Oggi** un professionista può esistere in sei posti diversi:

| Dove | Cosa | Ha un node? |
|---|---|---|
| Node `professional` (`config/nodes.yml`) | identità professionale; può esistere prima del dominio e dell'account (changelog GeneraImpresa 2026-09-25, Radioestesia) | è il node |
| `profiles` (database) | account utente; `primary_node_id` verso il suo node | opzionale |
| `config/data/people/profiles.yml` (`PersonProfileCatalog`) | schede persone con certificazioni (es. `davide-cattaneo`, `antonio-ventura`) | no |
| `config/data/posturacorretta/accademia/teachers/*.yml` | insegnanti PosturaCorretta | no |
| `posturacorretta_directory_people` (database) | elenco professionisti per dominio, `profile_id` opzionale | no |
| `generaimpresa/projects.yml`, `rails4b/landing.yml` | professionisti e founder citati nelle pagine | no |

**Indicato dall'utente**: la persona è il **Profile**. Dal profilo si deve poter sapere:
- se ha un suo node, e se quel node ha un suo dominio;
- di quali progetti fa parte e con quale ruolo:
  - PosturaCorretta → insegnante, oppure professionista di una metodica;
  - Percorso Integrato → professionista della salute o del benessere;
  - Rails4Business → professionista digitale;
  - GeneraImpresa → founder.

**Oggi nel codice**:
- `Profile` ha `primary_node` (il suo node, che può avere domini e quindi essere un brand) e
  `role_assignments`;
- `RoleAssignment` collega profilo, ruolo e contesto (un Node). I ruoli sono `admin`, `ideatore`, `creator`,
  `digital`, `responsabile`, `operator` (con `role_operator` testuale per la funzione). `digital` esiste già;
  insegnante, professionista di metodica, professionista della salute/benessere e founder no;
- `Profile` ha `belongs_to :user` con `user_id` obbligatorio: **un profilo esiste solo con un account**.

**Proposta**:
- `Content.node` = il node della raccolta (progetto, oppure autore se non c'è un progetto);
- ContentContribution collega Content, **Profile** e ruolo nel contenuto (autore, esperto, conduttore,
  videomaker, revisore, editor…). Node e dominio della persona si ricavano da `profile.primary_node`;
- l'import risolve `author` / `author_node_slug` nel profilo che ha quel node come `primary_node`;
- l'appartenenza ai progetti con ruolo (insegnante, founder…) passa da RoleAssignment ed è un lavoro a parte,
  fuori da questo piano.

**Indicato dall'utente**: l'admin deve poter aggiungere una persona come insegnante PosturaCorretta,
specialista di una metodica, professionista del Percorso Integrato, di Rails4Business o founder di
GeneraImpresa **anche se non ha ancora un account**.

**Deciso**: niente profili senza account e niente account inventati. Nel 90% dei casi il professionista non ha
tempo, quindi all'inizio **una persona lo inserisce per conto suo**, come nome.

**Oggi esiste già** questo meccanismo: `Brands::Impegno::Contact` (tabella `impegno_contacts`). È una persona o
un'organizzazione inserita da un profilo (`profile_id` = chi la aggiunge) con `name`, `kind`, `email`,
`phone`, `notes`, `metadata`. Gli impegni la usano già per "fare qualcosa per conto di" qualcuno
(`participant_contact_id`, mostrato come "Per <nome>").

**Proposta**: ContentContribution collega il contenuto a **un Profile oppure a un Contact** (esattamente uno dei
due), con il ruolo nel contenuto. Quando il professionista accetterà e avrà un account, il collegamento tra
contatto e profilo si deciderà a parte. Anche i ruoli nei progetti (insegnante, founder…) per chi è solo un
contatto restano un lavoro a parte.

**Da verificare**: come si rappresentano progetto e autore su Content (es. `node` = progetto o autore, più
ContentContribution verso il node dell'autore), se ContentContribution punta a Node, a Profile o a entrambi,
e come mappare gli `author:` esistenti.

## Regola generale — riferimenti a un Content

Ogni record che **vive solo nel database** e punta a un Content salva **sia `content_id` sia `content_key`**
(la chiave stabile del YAML; per i contenuti storici senza id, lo slug). Vale per DataCommitment, ContentProgress
e qualsiasi tabella futura dello stesso tipo. `content_id` può cambiare con un backup, un ripristino o una
ricostruzione del database; `content_key` no, e serve a ricollegare tutto.

I record che arrivano dal YAML con l'import (ContentPublication, ContentContribution, ContentLink) nel YAML
indicano il contenuto per chiave, e l'import li ricrea già collegati.

## Punto 7 — I tre significati di `content_key` ✅

**Oggi** `content_key` su DataCommitment è:
- la chiave editoriale nelle decisioni di pubblicazione (`kind: "content"`);
- lo slug del corso nelle iscrizioni;
- lo slug del capitolo nei completamenti (`kind: "academy"`, `metadata.record_type: "chapter_completion"`,
  `metadata.course_slug`).

**Verificato**: in sviluppo ci sono 11 impegni `content` (decisioni di pubblicazione) e 2 `academy`
(1 iscrizione, 1 completamento). In tutti e tre i casi `content_key` indica **un Content**: il contenuto da
pubblicare, il corso a cui ci si iscrive, il capitolo completato. Cambia solo il significato dell'impegno,
che è già dato da `kind` e da `metadata.record_type`.

Differenze di chiave da gestire:
- le decisioni usano l'`id` del YAML, oppure lo `slug` se l'id manca;
- iscrizioni e completamenti usano lo `slug`;
- lo slug di un capitolo è unico solo dentro il suo corso: per questo il completamento salva anche
  `metadata.course_slug`.

**Proposta**:
- `data_commitments.content_id` (nullable, FK verso Content) e, per il lavoro su una piattaforma,
  `content_publication_id` (nullable);
- un backfill collega gli impegni esistenti al Content per dominio + `id`/`slug` (+ `course_slug` per i
  capitoli), e segnala quelli che non trova invece di inventare;
- il codice scrive sempre sia `content_id` sia `content_key`.

**Deciso**: `content_key` **resta per sempre**, accanto a `content_id`. YAML e Markdown restano come copia di
sicurezza dei contenuti, e `content_key` è la chiave del YAML, uguale in ogni ambiente. `content_id` invece
cambia tra sviluppo e produzione e a ogni ricostruzione del database. Se il database si ricostruisce dai YAML,
gli impegni si ricollegano ai Content tramite `content_key`. Una validazione controlla che i due campi puntino
allo stesso Content.

## Punto 8 — Avanzamento e salvati ✅

**Oggi** il completamento dei capitoli è già un DataCommitment (`chapter_completion`), letto da
`Posturacorretta::HomeJourney` e da `learning_controller`.

**Verificato**: oggi si registrano solo azioni esplicite dentro un corso. Iniziare un corso crea un impegno
`academy` con `record_type: course_enrollment`. Il pulsante "completato" su un capitolo crea un impegno
`chapter_completion`, e bisogna aver completato il capitolo precedente
(`Posturacorretta::LearningController#complete_chapter`). Le semplici visualizzazioni non si registrano.

**Proposta**: l'avanzamento nei corsi resta com'è, con gli impegni collegati al Content (`content_id` +
`content_key`). ContentProgress serve solo per tracciare lettura e visione **fuori dai corsi**, che oggi non
esiste.

**Deciso**: niente tracciamento automatico di lettura e visione. Al posto di ContentProgress ci sono i
**salvati**: una persona salva un contenuto e ritrova i suoi salvati.

**Proposta**: un modello `SavedContent` con `profile_id`, `content_id`, `content_key` (regola generale) e data di
salvataggio; un contenuto si salva una sola volta per profilo (indice unico `profile_id` + `content_key`).
Si salva e si toglie con un pulsante, solo da autenticati.

**Deciso**: i salvati arrivano in una fase successiva, dopo Content e pubblicazioni.

## Punto 10 — Il contenuto come programma di un evento ✅

**Indicato dall'utente**: in alcuni casi il contenuto descrive cosa si fa in un evento programmato. All'evento
poi si aggiunge una DataSession o un DataSlot.

**Oggi**:
- `DataExperience` (un'esperienza, es. un ciclo di incontri) → `DataSession` (incontro con `starts_at`/`ends_at`,
  `position`, `visibility`) → `DataSlot` (parte di un incontro, con `position` e orari);
- sessioni, slot, esperienze e impegni hanno già un `skill_product_id`: il "cosa si fa" è oggi uno
  **SkillProduct**;
- `SkillProduct` (Rails4Business: prodotto di una competenza riutilizzabile, `reusable_skill_node`) ha `title`,
  `slug`, `status`, `visibility`, `format` (markdown, yaml, json, external), `body`, `data`, `source_path`,
  `published_at`, e collegamenti tra prodotti (`skill_product_links` con `relation_kind` e `position`).
  Lo usano i controller Rails4Business, l'area impegni, la dashboard di produzione, l'API e la pagina pubblica
  dei prodotti. In sviluppo ci sono 0 SkillProduct.

**Sovrapposizione**: SkillProduct ha quasi gli stessi campi di Content, e `skill_product_links` fa lo stesso lavoro
di ContentLink.

**Deciso**: si parte con SkillProduct come concetto separato. Sessioni e slot ricevono in più un riferimento al
Content del programma (`content_id` + `content_key`), in una fase successiva. Se far confluire SkillProduct in
Content si valuta più avanti.

## Punto 11 — Content come scheda: professionista, centro, scuola, metodica ✅

**Indicato dall'utente**: un contatto si collega a un Content, e quel Content è la **scheda del professionista**,
inserita in una raccolta (es. PosturaCorretta → Insegnanti, Professionisti di una metodica). Allo stesso modo
un Content può essere la scheda di un **centro** o di una **scuola** di una metodica.

**Proposta**: la scheda e la persona restano distinte.
- Content è la **scheda pubblica**: titolo, descrizione, Markdown, raccolta, ordine, pubblicazione con impegni.
  I campi propri del tipo (città, certificazioni, video…) stanno in `data` (jsonb), secondo il `format`
  (`professional`, `center`, `school`…);
- l'**identità** resta dov'è: Contact (inserito per conto della persona) o Profile (quando ha un account), collegati
  alla scheda con ContentContribution e un ruolo (es. `subject`, "è la scheda di");
- così la scheda è visibile a tutto il progetto anche se il contatto è personale di chi l'ha inserito.

**Oggi esistono già**, da far convergere più avanti:
- `posturacorretta_directory_people` e `posturacorretta_directory_places` (database, per dominio, con
  `visibility` e `listing_sections`);
- `config/data/people/profiles.yml`, `posturacorretta/accademia/teachers/`, `posturacorretta/professionisti/`,
  `posturacorretta/posturacorretta_professionisti.yml`;
- le metodiche come node (`posturacorretta/metodiche/`, importate con `MethodologyNodeImporter`).

**Deciso**: le schede entrano **già nella prima fase**, come tipi ammessi, senza migrare gli elenchi esistenti.

**Tipi indicati dall'utente**: `insegnante_posturacorretta`, `professionista_percorsointegrato` (collegabile a
una metodica PosturaCorretta), `professionista_rails4b`, `founder_generaimpresa`, `centro_posturacorretta`,
`metodica_posturacorretta`, `centro_percorsointegrato`.

**Proposta sui nomi**: il progetto è già dato dal node della raccolta in cui sta la scheda, quindi il tipo
può essere generico e il progetto non si ripete nel nome:

| Tipo indicato | Tipo (`format`) | Progetto (node della raccolta) |
|---|---|---|
| `insegnante_posturacorretta` | `insegnante` | posturacorretta |
| `professionista_percorsointegrato` | `professionista` | percorso-integrato |
| `professionista_rails4b` | `professionista` | rails4business |
| `founder_generaimpresa` | `founder` | generaimpresa |
| `centro_posturacorretta` | `centro` | posturacorretta |
| `centro_percorsointegrato` | `centro` | percorso-integrato |
| `metodica_posturacorretta` | `metodica` | posturacorretta |

Così un nuovo brand non richiede tipi nuovi.

**Collegamento tra contenuti**: "professionista collegato a una metodica" è un legame tra due Content (scheda
professionista → scheda metodica). Serve una relazione tra contenuti, oltre a `parent_id`.

**Conflitto da risolvere**: oggi le metodiche sono **node** (`posturacorretta/metodiche/`, importate da
`Posturacorretta::MethodologyNodeImporter` con il loro NodeContent, 9 in sviluppo). Una scheda
`metodica` come Content le duplicherebbe.

**Verificato — cosa dipende dalle metodiche come node**:
- in `config/nodes.yml` sono 10 node `project` con `view_type: methodology`, figli di `metodiche-posturali`,
  con `map_placements` sulla mappa di posturacorretta.org: sono **stazioni della mappa**;
- i node `access_bridge` (es. `accesso-gds-da-primo-incontro`) puntano alla metodica con `link_node_slug`;
- le pagine pubbliche (`/posturacorretta/metodiche`, `/posturacorretta/metodiche/:slug`, la tab metodiche di
  Consapevolezza) **non** leggono i node: leggono `posturacorretta/metodiche/metodiche.yml`,
  `professionisti.yml` e `scuole.yml` tramite `PosturacorrettaMethodologies`.

**Deciso**: le metodiche diventano **Content** (tipo `metodica`), non node. Sono un elenco quasi infinito, non
qualcosa da rappresentare sulla mappa. Una metodica diventa node **solo se ha un sito nostro**, come
`corpoecoscienza` (che è già un node a parte, con il suo dominio).

**Regola generale**: un node esiste se ha una struttura da rappresentare o un sito; le voci di un elenco sono
Content.

**Conseguenze** (da fare in una fase successiva, non nella prima):
- i 10 node `view_type: methodology` sotto `metodiche-posturali` (`fisioterapia`, `gds`, `osteopatia`,
  `mezieres`, `rpg`, `souchard`, `feldenkrais`, `alexander`, `kinesiologia-applicata`,
  `bioritmi-corpo-coscienza`) diventano Content nella raccolta di `metodiche-posturali`, con le loro
  posizioni sulla mappa che spariscono;
- il loro NodeContent (importato da `MethodologyNodeImporter`) diventa il corpo del Content, e l'importer delle
  metodiche si toglie;
- i 5 node ponte che puntano a una metodica con `link_node_slug` **si tolgono**, ma il legame si rifà (vedi
  sotto):
  `accesso-fisioterapia-da-primo-incontro`, `accesso-gds-da-primo-incontro`,
  `accesso-osteopatia-da-primo-incontro`, `accesso-corpo-coscienza-da-primo-incontro`,
  `accesso-kinesiologia-da-primo-incontro`;
- le pagine pubbliche delle metodiche e la tab di Consapevolezza leggono ancora `metodiche/*.yml`: restano
  così finché non si decide la migrazione di Consapevolezza (punto 5).

**Verificato — cosa fanno i ponti**: collegano sulla mappa il **corso introduttivo** di PosturaCorretta alla
metodica. Per esempio `accesso-gds-da-primo-incontro` ha come genitore `biomeccanica-comportamentale-gds`
("Introduzione alla biomeccanica comportamentale (GDS)", corso della linea `postura-recupero`) e punta a `gds`.
Come node sono nascosti (`HIDDEN_BRIDGE_TYPES` in `admin/metro_maps_controller.rb`, `flowpulse/network`): servono
solo a disegnare il collegamento.

**Deciso**: i ponti si tolgono, ma il **legame resta**, rifatto come collegamento tra il node del corso
introduttivo e il Content della metodica (es. "Scopri la metodica" dalla pagina del corso).

**Deciso**: un solo modello di collegamento (`ContentLink`) per tutti i legami che non sono
genitore/figlio, con un tipo di legame:
- Content → Content: professionista → metodica, centro → metodica;
- Node → Content: corso introduttivo → metodica.

**Deciso — nomi dei tipi**: generici (`insegnante`, `professionista`, `founder`, `centro`, `scuola`,
`metodica`); il progetto è dato dal node della raccolta.

## Punto 12 — Luoghi ⏳

**Indicato dall'utente**: le sedi servono (es. la Sede PosturaCorretta), un luogo può essere chiuso (il Giardino
del Corpo), può valere per più domini e può avere un articolo diverso a seconda del dominio; per ora i luoghi
nascono dall'admin.

**Deciso**:
- `Place` è il luogo fisico: `name`, `slug` (unico), `address`, `city`, `province`, `latitude`, `longitude`,
  `status` (`open`/`closed`), `closed_on`, `description`, `created_by_profile`, `metadata`. Un luogo chiuso non
  si cancella: resta per la storia ma non compare tra i luoghi attivi (`Place.open`).
- `PlaceDomain` collega il luogo a un dominio, con un **Content facoltativo** che lo racconta in quel dominio
  (es. la scheda `centro-posturacorretta` su posturacorretta.org). Il Content deve stare nel node del dominio o
  in un suo discendente. Nessuna tabella content_places: un luogo ha al più un Content per dominio.
- `posturacorretta_directory_places` (un solo dominio, senza coordinate né stato) confluirà in `Place`.

**Fatto (non committato)**: migrazione `20261120100000_create_places`, model `Place` e `PlaceDomain`, test.
In sviluppo: `sede-posturacorretta`, su posturacorretta.org (con `centro-posturacorretta`) e su
percorsointegrato.it (senza Content).

**Admin (fatto, non committato)**: `/flowpulse/rete/luoghi`, solo superadmin (`Admin::PlacesController`,
`Admin::PlaceDomainsController`): elenco con filtro per dominio, nuovo/modifica, chiusura con data, collegamento
ai domini con il Content scelto tra quelli del dominio.

**Pagina Centri di PosturaCorretta (fatto, non committato)**: elenco e mappa dai luoghi aperti collegati a
posturacorretta.org (`PlaceDomain`); un luogo rimanda alla scheda del centro solo se è pubblicata.

**Ancora da fare**: confluenza di `posturacorretta_directory_places` → accesso dei professionisti → altri domini
che mostrano i loro luoghi.

## Punto 13 — Pubblicazione modificata direttamente, non più dagli impegni ⏳

**Deciso dall'utente (2026-11-20)**: la pubblicazione non passa più dagli impegni. `publication_status`,
`publication_visibility` e `published_at` si modificano direttamente, per Content e per Place; alla nascita sono
in bozza e privati.

- I Content si modificano nell'admin di ogni brand (`/<brand>/admin/contents`): i Content del node del brand e dei
  discendenti; nel brand del titolare anche i suoi Content che stanno in altri brand (`profile_id` su Content,
  dall'`author_node_slug` per quelli dei YAML).
- I luoghi restano nell'admin di Flowpulse (solo superadmin per ora).
- I pulsanti Pubblica/Aggiorna/Sospendi della barra editoriale dei capitoli modificano direttamente il Content.
- Gli impegni di pubblicazione già fatti restano come storia, ma non cambiano più lo stato; il deploy non
  riapplica più le decisioni.

**Ordine**: 1) pubblicazione su Place ✅ → 2) `profile_id` su Content ✅ (entrambi non committati; il titolare
si assegna all'import una volta sola: l'autore, o il titolare del corso per i capitoli; poi cambia solo
dall'admin) → 3) pagina Contenuti ✅ (non committata: `/<brand>/admin/contents`, `Brands::Admin::ContentsController`) → 4) ✅ (non committato) nessun ricalcolo dagli impegni né al deploy
(`ContentCommitmentLinks` collega solo); la barra editoriale chiama
`PATCH /posturacorretta/contenuti-editoriali/:content_key/pubblicazione` (`publish`, `update` = `revised_at`,
`suspend`), permesso agli amministratori del node del Content o del brand PosturaCorretta
nell'admin del brand → 4) impegni che non decidono più + barra editoriale con modifica diretta.

## Punto 9 — Fasi di implementazione ⏳

**Proposta**. Ogni fase è un commit a sé, con test, reversibile (migrazioni con `down`), e lascia le pagine
funzionanti.

**Fase 1 — Struttura dati e import, nessuna pagina cambia**
- Tabelle e model:
  - `contents`: `node_id`, `parent_id`, `key` (unica), `slug`, `format`, `position`, `title`, `description`,
    `body_md`, `source_path`, `source_checksum`, `data` (jsonb), `written_on`, `revised_at`, e lo stato di
    pubblicazione dell'ambiente (`publication_status`, `publication_visibility`, `access_modes`,
    `published_at`) scritto solo dagli impegni;
  - `content_publications`: piattaforma, formato, URL, id esterno, titolo e testo adattati, posizione,
    `metadata`, più lo stato di pubblicazione dell'ambiente;
  - `content_contributions`: Content + Profile **oppure** Contact + ruolo;
  - `content_links`: da Content o da Node verso Content, con tipo di legame e posizione;
  - `data_commitments`: `content_id` e `content_publication_id` (nullable), accanto a `content_key`.
- Import `contents:import` (e `contents:validate` senza salvare) da `brands/<node>/courses/` e
  `brands/<node>/contents/`: crea o aggiorna per `key`, non tocca mai lo stato di pubblicazione, un nuovo
  contenuto parte in bozza.
- Callback sull'impegno: quando un impegno di pubblicazione si conclude, aggiorna Content o ContentPublication
  (punto 1, punto 4).
- Le pagine continuano a leggere i YAML come oggi.

**Stato fase 1 — implementata, da verificare**
- Migrazione `db/migrate/20261117100000_create_contents.rb` (reversibile, provata con rollback).
- Model: `Content`, `ContentPublication`, `ContentContribution`, `ContentLink`; collegamenti su `Node`
  (`editorial_contents`, `outgoing_content_links`), `Profile`, `Brands::Impegno::Contact`,
  `Brands::Impegno::Commitment` (`content`, `content_publication`, callback di pubblicazione).
- Import: `app/services/content_catalog.rb`, `bin/rails contents:validate` e `bin/rails contents:import`.
- Autore ed editore letti anche dall'intestazione YAML dei Markdown dei capitoli (69 file su 85 la hanno);
  i valori del `course.yml` hanno la precedenza. Un capitolo resta nel node del suo corso.
- In sviluppo: 90 contenuti (10 corsi, 78 capitoli, 2 articoli), tutti in bozza, 76 contributi d'autore;
  il secondo import non crea nulla di nuovo.
- Test: `test/models/content_test.rb`, `test/services/content_catalog_test.rb`, nuovi casi in
  `test/models/brands/impegno/commitment_test.rb`.
- Le regole di pubblicazione nel controller degli impegni non sono ancora state spostate: il callback legge
  i campi già impostati dal controller. Lo spostamento completo si fa con la fase 2.

**Fase 2 — Corsi e capitoli dal database**
- Backfill di `content_id` sugli impegni esistenti (punto 7), con elenco di quelli non trovati.
- `learning_controller` e `ContentRepository` leggono da Content; lo stato visibile è quello del Content.
- `status`, `visibility`, `access` tolti dai `course.yml`; `contenuti/contents.yml` tolto.
- ~~Export `contents:export` verso i YAML~~: tolto, i file restano l'unica fonte di testi e struttura.

**Stato fase 2 — passo 1 (backfill) fatto**
- `DataCommitment#matching_content`: le decisioni trovano il Content per chiave, le iscrizioni per slug del
  corso, i completamenti per slug del capitolo dentro `metadata.course_slug`. Se i Content sono zero o più di
  uno, l'impegno non viene collegato. Lo stesso collegamento avviene a ogni salvataggio.
- `content_key` può essere la chiave o lo slug del Content collegato (iscrizioni e completamenti legacy).
- `ContentCommitmentLinks` + `bin/rails contents:link_commitments` (`DRY_RUN=1` per provare): collega gli
  impegni che hanno solo `content_key` e riapplica in ordine le decisioni concluse dei Content collegati.
  `contents:import` lo esegue alla fine, così un database ricostruito dai YAML si ricollega da solo.
- In sviluppo: 12 impegni collegati su 13, 11 decisioni riapplicate (`inizia-trama-postura-fisiologia`
  pubblicato). Non collegato: il completamento 8, con lo slug `trama-postura-fisiologia`; nel `course.yml`
  quel capitolo oggi ha lo slug `postura-salute-altri-aspetti`, e l'id `inizia-trama-postura-fisiologia` è
  rimasto lo stesso.
- Da fare nel passo 2: iscrizioni e completamenti nuovi salvano la chiave del Content (`id`), non lo slug,
  così un cambio di slug non li stacca più.

**Stato fase 2 — passo 2a (struttura dal database) fatto**
- `deploy:sync_catalogs` (hook `post-deploy` di Kamal) importa i contenuti dopo i Node e collega gli impegni:
  a ogni deploy YAML e Markdown aggiornano testo e struttura, mai lo stato di pubblicazione.
- `Posturacorretta::ContentRepository` legge i Content del node `posturacorretta` e restituisce gli stessi
  hash di prima; lo usano le pagine del corso, Consapevolezza e Connessione (i loro file non cambiano).
  A parità di posizione l'ordine è per chiave, uguale in ogni ambiente.
- Confronto prima/dopo in sviluppo: stessi corsi, capitoli, ordine e stato. Unica aggiunta: i capitoli
  riportano autore ed editore dell'intestazione del Markdown.
- Solo per il 2a, `status`, `visibility`, `access` si leggono ancora dai `course.yml`
  (`ContentRepository::ENVIRONMENT_KEYS`).
- Test: `import_posturacorretta_contents` in `test/test_helper.rb` importa i Content dove servono.

**Stato fase 2 — passo 2b (stato dal Content) fatto**
- `ContentRepository` restituisce `status`, `visibility`, `access` del Content (`access`: `free` se l'accesso
  è libero o non ancora deciso, altrimenti `paid`); senza `include_scheduled` mostra solo i pubblicati.
- `learning_controller`: corso e capitolo sono disponibili se il Content è pubblicato, pubblico e libero
  (`published_for_public?`). Gli impegni restano per la cronologia nella barra editoriale.
- Tolti `status`, `visibility`, `access` dai 9 `course.yml` (264 righe).
- Corsi che si vedevano solo grazie al YAML e vanno ripubblicati con un impegno, in ogni ambiente:
  `corpo-come-un-giardino`, `inizia-con-posturacorretta`, `introduzione-percorso-integrato-posturacorretta`,
  `il-tuo-stato-di-salute`, `percorso-integrato`, `postura-e-fisiologia`. I capitoli no: già prima si
  vedevano solo con una decisione.
- Non toccato (home): `Posturacorretta::HomeCourseCatalog` legge ancora i `course.yml`; `status` e `access`
  ora mancano solo dalla sua risposta JSON, che la home non usa.
- Fase 2 chiusa: `contents:export` non si fa, i file restano l'unica fonte di testi e struttura.

**Stato fase 2 — passo 2c (iscrizioni e completamenti con la chiave) fatto**

- Le nuove iscrizioni e i nuovi completamenti salvano in `content_key` la chiave del Content (l'`id` del
  YAML) e quindi anche `content_id`; i corsi senza `id` (sezioni e primo mese storici) usano ancora lo slug.
  In `metadata` restano `course_slug` e `chapter_slug` com'erano al momento.
- I progressi si leggono con `learning_slug` e `learning_course_slug` del model: lo slug attuale del Content
  collegato, altrimenti quello salvato. Così un cambio di slug non perde i progressi già registrati.
- `matching_content` per iscrizioni e completamenti cerca prima la chiave, poi lo slug (record storici).
- Unico ritocco fuori dal corso: `posturacorretta_completed_chapters` in `PublicNodePresentation` usa gli
  stessi metodi; la home riceve lo stesso formato `{ course_slug => [chapter_slug] }` di prima.

**Stato fase 2 — passo 2d (regole di pubblicazione nel model) fatto**

- `publication_status_for`, la data di pubblicazione, `blocks_calendar` e la decisione precedente
  (`previous_publication_commitment`) sono ora in `Brands::Impegno::Commitment` (callback `before_validation`);
  il controller degli impegni imposta solo chi decide (`published_by_profile`) e controlla i permessi.
- Una decisione registrata già conclusa tiene lo stato indicato, o quello del tipo di cambiamento se manca, e
  la data indicata o l'ora attuale. Una decisione pianificata che si conclude prende lo stato dal tipo di
  cambiamento e la data di conclusione, da qualunque punto venga conclusa (prima valeva solo per l'azione
  "Concludi" del controller).
- `contenuti/contents.yml` resta per ora (deciso il 2026-11-18): il vincolo iniziale dice di non eliminare
  YAML e lo leggono ancora un test, la pagina admin delle sorgenti didattiche e il materiale editoriale.

**Stato fase 2 — passo 2e (capitoli nei node delle lezioni) fatto**

- Ogni capitolo ha `lesson_node_slug` nel `course.yml` e l'import lo mette in quel node (`view_type:
  course_lesson`); i corsi restano nel node `posturacorretta`. `ContentRepository` trova i capitoli dal corso.
- Node nuovi in `config/nodes.yml`: corso e lezione per Il tuo stato di salute (sotto `stato-di-salute`), per
  Percorso Integrato (sotto `percorso-integrato`) e, in Educazione 3, "Il corpo, un mondo da scoprire" e "Le tue
  risorse", ciascuno con il ponte verso `ilgiardinodelcorpo` e `rails4business`. Questi due brand sono ora figli
  di `markpostura` (domini invariati) e lasciano le righe 5 e 6 della mappa alle due lezioni.
- In produzione le due posizioni vecchie sulla mappa vanno tolte a mano: l'import non cancella posizioni.

**Stato fase 3 — passo 1 (percorsi di Rails4Business) fatto**

- I due percorsi di `rails4b/percorso.yml` sono corsi: `brands/rails4business/courses/voglio-collaborare` e
  `brands/generaimpresa/courses/ho-un-progetto`, con le 5 guide ciascuno come capitoli. I testi restano in
  `config/data/rails4b/contenuti` (`content_path`); `publication_at` diventa `written_on`.
- Un node per percorso, dove stanno le guide: `voglio-collaborare` sotto `rails4business` e `ho-un-progetto`
  sotto `generaimpresa`. Nessuna posizione sulle mappe.
- Le pagine `rails4b/percorsi/...` e `rails4b/contenuti/...` leggono ancora `percorso.yml` e `catalog.yml`.

**Stato fase 3 — passo 2 (articoli di markpostura e rails4b) fatto**

- Un node per gli articoli di ogni brand: `articoli-markpostura` (sotto `markpostura`, 8 articoli) e
  `articoli-rails4business` (sotto `rails4business`, 8 articoli + `dal-nodeevent-alla-scheda-markdown`).
- Ogni articolo è `brands/<brand>/contents/<slug>/content.yml` (`format: post`); il testo resta nei vecchi
  `articoli/<anno>/` tramite `content_path`, la data diventa `written_on`. I cataloghi vecchi restano.
- `DomainContentCatalog` usa il `content.md` canonico solo se esiste, così le pagine attuali trovano ancora il
  testo nei vecchi percorsi. Le pagine leggono ancora i cataloghi: il passaggio a Content è il prossimo passo.

**Stato fase 3 — passo 3 (DomainContentCatalog da Content) fatto**

- Per `markpostura` e `rails4b` `DomainContentCatalog` legge i Content dei node in `CONTENT_NODES`
  (`articoli-markpostura`; `articoli-rails4business`, `voglio-collaborare`, `ho-un-progetto`) e non più il loro
  `catalog.yml`. Visibilità = stato del Content; una data futura non nasconde più nulla.
- PosturaCorretta e flowpulse restano sul catalogo YAML.
- Dopo il deploy i 17 articoli e le 10 guide sono in bozza: vanno pubblicati con un impegno (`content_key` =
  chiave dell'articolo, cioè lo slug). Le pagine `rails4b/percorsi` e `rails4b/contenuti` leggono ancora i YAML.

**Stato fase 3 — passo 4 (pagine rails4b da Content) fatto**

- `rails4b/contenuti`, `rails4b/contenuti/:slug` e `rails4b/percorsi/:slug` leggono articoli e guide dai Content.
  `percorso.yml` dà solo titolo e indirizzo dei trenini, più `course_key` (il corso con le guide in ordine); i
  suoi `steps` e `catalog.yml` restano come copia ma non vengono letti.
- Una guida non pubblicata resta nel trenino "in preparazione" (titolo sì, testo no); un articolo non
  pubblicato è visibile solo al superadmin. Le date mostrano il giorno di scrittura, senza ora.
- Ancora sul YAML: la home di rails4b.com in `domains_controller.rb` (`prepare_rails4b_landing`), lasciata per
  non toccare modifiche in corso in quel file.

**Fase 3 — Articoli**
- Conversione dei cataloghi di `markpostura` e `rails4b` nella forma `brands/<node>/contents/`.
- `DomainContentCatalog` legge da Content.
- `posturacorretta/contenuti/catalog.yml` resta finché non si decide la migrazione di home e Consapevolezza
  (punto 5).

**Fase 4 — passo 1 (node Risorse) fatto**

- Ogni dominio raccoglie le sue raccolte di schede e articoli in un node "Risorse" (senza posizione sulla mappa):
  - `risorse-posturacorretta` → `insegnanti-posturacorretta`, `centri-posturacorretta`,
    `metodiche-posturacorretta`, `scuole-posturacorretta` (vuoti);
  - `risorse-stato-di-salute` → `comuni`, `centri`, `professioni`, `scuole-formazione-professionisti` (spostati);
  - `risorse-markpostura` → `articoli-markpostura`; `risorse-rails4business` → `articoli-rails4business`.
- Le schede si scrivono come gli articoli: `brands/<brand>/contents/<slug>/content.yml` + `content.md`, con
  `format` (`insegnante`, `centro`, `metodica`, `scuola`, `professionista`, `founder`) e `publisher_node_slug` =
  node della raccolta; entrano con l'import. Metodica e scuola sono distinte: la scuola forma nella metodica
  (legame ContentLink).

**Fase 4 — passo 2 (insegnanti e Sede) fatto, non committato**

- Schede `insegnante-markpostura`, `insegnante-davide-cattaneo`, `insegnante-antonio-ventura` (in
  `insegnanti-posturacorretta`) e `centro-posturacorretta` (in `centri-posturacorretta`); testi dai vecchi `.md`.
  Gli altri centri di `centers.yml` non esistono più e non sono stati convertiti (il file resta).
- `AcademyCurriculum` prende insegnanti e centri dai Content; `public` = pubblicazione del Content.
  Lo stato dell'insegnante resta come `teacher_status` (in Content `status` è riservato alla pubblicazione).
- Senza luoghi aperti la landing del Giardino del Corpo non mostra la sezione Luoghi.

**Fase 4 — Schede e metodiche**
- Schede `insegnante`, `professionista`, `founder`, `centro`, `scuola`, `metodica` (punto 11).
- Metodiche da node a Content; tolti i 10 node delle metodiche, i 5 ponti e `MethodologyNodeImporter`;
  legami rifatti con ContentLink.

**Fase 5 — Dopo**
- SavedContent (punto 8).
- Riferimento al Content del programma su sessioni e slot (punto 10).
- Valutazione di SkillProduct dentro Content.
- Profili per i contatti che accettano, e ruoli nei progetti (punto 6).

## Da fare — punti aperti (2026-11-20), uno alla volta

**Dopo ogni deploy in produzione (manuale)**
- Creare la Sede in `/flowpulse/rete/luoghi`, collegarla a posturacorretta.org con la scheda
  `centro-posturacorretta` e pubblicarla.
- Una volta sola: `bin/rails contents:publish_backlog` (prima con `DRY_RUN=1`) pubblica le bozze con la data
  di `config/data/contents_published_on.yml`, generato in locale con `contents:generate_published_on`
  (written_on del file, altrimenti il primo commit; per un corso il capitolo più vecchio).
- Una volta sola: `bin/rails places:import_directory` (prima con `DRY_RUN=1`).
- Togliere dalla mappa di posturacorretta.org le posizioni vecchie di `ilgiardinodelcorpo` e `rails4business`.

**Punti aperti**
1. ✅ Admin Contenuti del brand: una sola tabella con il dominio da cui esce ogni contenuto e il tipo,
   filtrabile per dominio e tipo; tutti i contenuti pubblicati con la data recuperata.
2. ⏳ Luoghi.
   - ✅ Confluenza: il tab "Centri e luoghi" di percorsi-sul-territorio e il filtro "Luoghi" dei contenuti leggono
     `Place.shown_on(dominio)` (aperti, pubblici, collegati al dominio). `centers.yml` e la tabella
     `posturacorretta_directory_places` restano; `bin/rails places:import_directory` (una volta, `DRY_RUN=1` per
     provare) copia le righe vecchie in `Place` + `PlaceDomain`.
   - ⏸ Accesso dei creator e altri domini che mostrano i loro luoghi: per ora resta com'è (solo superadmin,
     luoghi su posturacorretta.org e Giardino). Professionisti e centri andrebbero in Percorso Integrato, non in
     Stato di salute dove erano stati messi: da riprendere quando si sistema Percorso Integrato.
3. ⏳ Fase 4: metodiche e scuole come Content, insieme alla decisione su Consapevolezza (punti 5 e 11).
   - ✅ Passo a: schede `metodica-*` (le 9 di `metodiche.yml` + `metodica-fisioterapia` solo col titolo) in
     `metodiche-posturacorretta`; il testo resta in `metodiche/contenuti/*.md` (`content_path`). Nascono in
     bozza. L'import legge `links: { <tipo>: [...] }` e crea i ContentLink; non li toglie mai.
     `metodiche.yml`, `scuole.yml` e `professionisti.yml` restano; le pagine pubbliche e Consapevolezza li
     leggono ancora. I professionisti di `professionisti.yml` sono dati di esempio: non convertiti.
   - **Deciso**: niente schede scuola per ora (quelle di `scuole.yml` sono segnaposto, una per metodica).
     Distinzione che conta: la **metodica** ha i suoi professionisti formati (e, se ha un sito nostro, è un
     node con dominio, come `corpoecoscienza`); il **corso PosturaCorretta** (percorso educativo) è seguito e
     insegnato dagli insegnanti PosturaCorretta e ha corsi introduttivi che presentano i principi di ogni
     metodica, come assaggio. Il legame corso introduttivo → metodica è quello del passo b.
   - ✅ Passo b: i 10 node delle metodiche e i 5 ponti `accesso-…-da-primo-incontro` sono in `removed_slugs`
     di `nodes.yml` (l'import dei node li toglie, anche in produzione); tolti `MethodologyNodeImporter`, la
     task `posturacorretta:import_methodology_nodes` e il suo test. I 5 legami corso introduttivo → metodica
     sono ContentLink da node, scritti nelle schede come `links_from_nodes: { metodica: [<corso>] }`.
     `metodiche-posturali` resta sulla mappa senza figli, con il ponte `accesso-categoria-metodiche-da-altre-metodiche`.
4. ✅ Home di rails4b.com (`DomainsController#prepare_rails4b_landing`): leggeva `percorso.yml` e
   `rails4b/contenuti/catalog.yml` per calcolare percorso e tappe che la vista non usava. Ora legge solo i testi
   di `landing.yml`; percorsi, guide e articoli restano su `LandingController`, che li prende dai Content. Il
   vecchio `catalog.yml` non lo legge più nessuno (il file resta).
5. ⏳ Fase 5:
   - ⏳ SavedContent (punto 8).
   - ⏳ Programma degli eventi: Content su sessioni e slot (punto 10).
   - ✖ SkillProduct dentro Content: **deciso di no** (2026-11-21). SkillProduct resta il prodotto di una skill
     riusabile, con sessioni, slot e impegni suoi.
   - ⏳ Profili per i contatti e ruoli nei progetti (punto 6): da chiarire.

## Resoconto finale

Architettura trovata, decisioni prese, file modificati, schema delle relazioni, test eseguiti, parti ancora
da migrare, decisioni che richiedono conferma.
