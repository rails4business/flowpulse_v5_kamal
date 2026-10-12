# Architettura corrente — Brand, Node, Domain e Site

> **Fonte canonica aggiornata all'11 ottobre 2026.** Questo documento governa
> la struttura dei Brand e la loro pubblicazione. In caso di contrasto con
> appunti precedenti, prevale questo documento.

## La regola essenziale

```text
Node   → identità e struttura
Domain → indirizzo pubblico e Node radice
Site   → presentazione editoriale in una lingua
```

Un Brand non richiede un modello separato: è un Node al quale è collegato
almeno un Domain canonico.

## Node

I Node costruiscono una struttura variabile. Possono essere aggiunti, spostati
e articolati mentre il progetto evolve.

- `node_type: professional` identifica un professionista;
- `node_type: project` identifica un progetto;
- `parent_id` esprime soltanto l'appartenenza gerarchica reale;
- `professional_owner_node_id` indica il professionista responsabile;
- `link_node_id` crea un ponte trasversale e non modifica la gerarchia.

“Brand professionali” e “Brand progetto” sono filtri calcolati da `node_type`:
non sono Node contenitore. Un Node privo di Domain rimane un progetto interno.
Quando riceve un Domain canonico diventa anche un Brand o sotto-Brand pubblico,
senza essere ricreato.

Fra la radice di un Brand e un sotto-Brand possono esserci diversi Node
intermedi. La posizione non viene dedotta dal nome del dominio.

## Domain

Ogni dominio pubblico canonico deve puntare a un Node radice.

```text
Domain canonico
├── hostname
├── node_id obbligatorio
├── locale
├── primary
├── site_key oppure controller/action
└── metadata pubblici
```

Gli alias tecnici, come `www`, non possiedono un Node o un Site autonomo:
usano `canonical_host` ed ereditano il contratto dal dominio canonico.

Un dominio tradotto non è un alias. È un Domain canonico distinto, collegato
allo stesso Node oppure al Node linguistico deliberatamente scelto, con
`locale`, canonical, sitemap e futuro `hreflang` propri.

Il Domain non contiene una copia dell'albero. Se cambiano i discendenti del
Node radice, non deve essere riscritto. La sua proiezione pubblica viene
calcolata dal Node corrente applicando stato, visibilità e confini.

Quando l'albero incontra un discendente con un proprio Domain, mostra quel
Node come collegamento al sotto-Brand e non ne espande automaticamente i figli.
I Node ponte vengono mostrati come relazioni, non come discendenti.

## Site

Il Site descrive come un Domain presenta pagine e materiale editoriale.
Risiede in `config/data/sites/<site_key>/` e dichiara almeno:

```yaml
site:
  key: posturacorretta_it
  node_slug: posturacorretta
  locale: it
  renderer: controller # oppure builder
```

Se un Domain usa `site_key`:

- il Site deve esistere;
- `site.node_slug` deve coincidere con il Node del Domain;
- `site.locale` deve coincidere con la lingua del Domain.

Più Domain possono condividere lo stesso Site quando pubblicano davvero la
stessa struttura editoriale. Lo stesso Node può utilizzare Site differenti per
lingue o presentazioni realmente differenti. Gli alias non hanno una cartella
Site separata.

Non tutti i Domain devono essere già convertiti al Page Builder. Un Site usa
implicitamente `renderer: builder`; quando raccoglie configurazioni condivise
ma la navigazione è ancora gestita dall'applicazione dichiara
`renderer: controller`. In questa fase il Domain usa `target_controller` e
`target_action`, ma deve comunque avere un Node radice.

## Fonti di verità

- database: associazioni operative fra Domain, Node e proprietari;
- `config/domains.yml`: configurazione versionata e ricostruibile dei Domain;
- `config/nodes.yml`: struttura iniziale/versionata dei Node gestiti dal
  relativo snapshot;
- `config/data/sites/`: presentazione editoriale;
- `config/data/rails4b/skills.yml`: catalogo versionato delle definizioni e
  delle attivazioni ricostruibili delle Skill;
- contenuti e dati delle Skill: risorse prodotte e collegate ai Node.

YAML e database devono poter essere confrontati, importati ed esportati senza
inventare relazioni. L'assenza di `node_slug` su un dominio canonico è un
errore da risolvere manualmente, non un invito ad assegnare automaticamente un
Node dal nome simile.

## Pubblicazione e AI

La stessa regola governa HTML, sitemap, JSON-LD, API e accesso delle AI:

```text
Node pubblicato e pubblico
+ risorsa pubblicata e accessibile senza autenticazione
= risorsa pubblicamente scopribile
```

Non vengono aggiunti campi separati `visibility_ai` o `status_ai`.

Ogni Domain canonico pubblico espone inoltre `/llms.txt`, generato dalla stessa
proiezione autorizzata di Domain e Node. Il file non è una copia editoriale da
sincronizzare: `Domain.settings` conserva soltanto `llms_enabled`, l'eventuale
`llms_summary` e le eventuali `llms_instructions`. Se la sintesi è assente si
usa la descrizione pubblica del sito. Alias, Domain disattivati e Node radice
non pubblici non producono un documento. I prodotti delle Skill entrano nel
documento soltanto quando Skill, attivazione, Node e prodotto superano tutti la
policy pubblica condivisa.

## Responsabilità SEO e prestazioni

SEO e PageSpeed non vengono distribuiti come campi duplicati su ogni modello.
La responsabilità è stratificata:

| Livello | Responsabilità |
| --- | --- |
| Domain | identità generale, host e URL canonico, lingua, metadata di fallback, loghi, profili ufficiali, sitemap, robots e JSON-LD `WebSite` con il soggetto principale |
| Node | titolo, descrizione, tipo professionale/progetto, relazioni e pagina pubblica; fornisce il soggetto `Person`, `Organization` o pagina/progetto equivalente |
| Skill | registra il contratto pubblico delle risorse che produce, non una SEO autonoma del plugin |
| Risorsa della Skill | slug, titolo, descrizione, autore/produttore, stato, visibilità, date, immagine, canonical e JSON-LD specifico (`Article`, `Course`, `Event`, `Service`, `Place`...) |
| ProblemSolving | privato per impostazione predefinita; può offrire una proiezione pubblica editoriale senza esporre note, test o persone riservate |

Un servizio condiviso `PublicDiscovery` dovrà comporre questi livelli e
fornire lo stesso insieme autorizzato a HTML, sitemap, JSON-LD e API.

PageSpeed appartiene principalmente a Site, layout, componenti e asset. Il
Domain identifica l'host sul quale misurare il risultato; Node, Skill e
ProblemSolving non conservano punteggi PageSpeed. Per ogni dominio vanno
misurate landing e pagine rappresentative controllando almeno LCP, INP, CLS,
TTFB, peso della pagina, immagini, font, video, CSS/JavaScript inline,
dipendenze CDN, lazy loading e cache. Baseline e risultati appartengono a un
report tecnico datato, non ai record applicativi.

## Controllo amministrativo

L'elenco Domini esegue un audit non distruttivo e segnala:

- dominio canonico senza Node;
- alias canonico mancante o inattivo;
- alias con Node o Site propri;
- Site inesistente;
- incoerenza fra Node o lingua del Site e del Domain;
- ingresso pubblico e metadata mancanti;
- più domini primari per lo stesso Node e lingua.

Finché i Domain storici non sono stati collegati correttamente, questi errori
restano diagnostici. Solo dopo la bonifica `node_id` potrà diventare un vincolo
bloccante per tutti i Domain non alias.

La scheda del singolo Domain aggiunge una checklist di pubblicazione.
`DomainPublicationAudit` non effettua richieste HTTP esterne: verifica il
contratto applicativo di Node, landing, identità, asset, proiezione, sitemap,
robots, `llms.txt`, API e catalogo PageSpeed, quindi offre i link canonici per
la prova reale dopo il deploy. Verde significa pronto, giallo richiede un
completamento non bloccante, rosso impedisce la pubblicazione corretta.

## Ordine di lavoro

1. ✅ definire il contratto `Domain → Node → Site`;
2. ✅ creare l'audit amministrativo dei Domain;
3. ✅ collegare tutti i Domain canonici configurati al proprio Node radice;
4. ✅ verificare coerenza con i Site già presenti;
5. ✅ rendere comune l'ingresso pubblico ai Node;
6. ✅ definire baseline e budget PageSpeed per landing e pagine rappresentative;
7. ✅ rendere sitemap, robots, canonical e JSON-LD consapevoli del Domain;
8. ✅ comporre SEO e dati pubblici di Domain e Node attraverso `PublicDiscovery`;
9. ✅ pubblicare l'API read-only Domain/Node;
10. 🔄 standardizzare progressivamente le Skill e le risorse che producono.
    È un'attività continuativa: ogni Skill viene aperta, sviluppata, verificata
    e, quando pronta, può essere attivata sui Node;
11. ⏸️ aggiungere la proiezione pubblica dei ProblemSolving soltanto quando sarà
   definita e deliberatamente pubblicata.

Al completamento del punto 3 risultano configurati dodici Domain canonici,
tutti associati a un Node. `igieneposturale.it` punta al Node
`igiene-posturale`, mantenuto `draft/private` dentro i Brand in costruzione:
il dominio rinvia temporaneamente a GeneraImpresa, non espone una sitemap e non
entra nella discovery pubblica. Il Node potrà essere spostato in seguito senza
cambiare il Domain.

Al completamento del punto 4 i Site presenti sono due e risultano validi:
`markpostura_it` usa il Page Builder, mentre `posturacorretta_it` dichiara la
modalità transitoria `renderer: controller` e continua a raccogliere anche la
configurazione PWA. Node e lingua coincidono con i rispettivi Domain. Gli altri
Domain restano correttamente serviti dai controller dichiarati e non richiedono
una cartella Site fittizia.

Al completamento del punto 5 sia l'URL pubblico `/nodes/:id` sia il fallback
del Domain preparano la pagina tramite `PublicNodePresentation`. Visibilità,
confine del dominio, breadcrumb, navigazione fra Node, strumenti del creator e
iscrizione vengono quindi calcolati nello stesso modo; le landing dedicate
continuano a mantenere i propri URL e controller.

Al completamento del punto 6 tutti i dodici Domain canonici sono presenti nel
contratto `config/data/performance/domain_budgets.yml`, con budget comuni e
pagine rappresentative. Le baseline reali restano dichiarate `pending` e
Lighthouse/PageSpeed viene eseguito esternamente, senza dipendenze npm nella
repository. `igieneposturale.it` è temporaneamente `skipped` perché il suo Node
è ancora draft/private. Il comando `bin/rails performance:audit` valida il
contratto senza effettuare chiamate di rete.

Al completamento del punto 7 `PublicDiscovery::DomainCatalog` definisce gli URL
pubblici propri di ciascun dominio e `PublicDiscovery::DomainUrls` compone
landing, contenuti pubblicati e Node pubblici interni, fermandosi davanti a
ponti e sotto-Brand con un altro dominio. `/sitemap.xml` e `/robots.txt` sono
dinamici per host; un dominio con Node non pubblico non espone sitemap e blocca
i crawler. I layout pubblici usano canonical sull'host configurato e includono
JSON-LD `WebSite`, `WebPage`, `Person` oppure `Organization`; le pagine Node
aggiungono `BreadcrumbList`. Le aree e le risorse private restano escluse.

Al completamento del punto 8 `PublicDiscovery::Projection` è la proiezione
anonima condivisa di Domain e Node. Espone identità e asset pubblici del
dominio, Node radice e lista piatta dei Node consultabili con relazione, padre,
URL e data di aggiornamento. Un ramo non pubblico viene interrotto; un ponte è
una relazione verso il target e non ne duplica i dati; un sotto-Brand con un
altro dominio viene esposto come confine senza attraversarne i discendenti.
Sitemap e JSON-LD consumano questa proiezione. Non vengono esposti ruoli
amministrativi, eventi di sviluppo, processi, DataCommitment o note interne.

Al completamento del punto 9 la proiezione è disponibile in sola lettura su
`/api/v1/domain`, `/api/v1/nodes`, `/api/v1/nodes/:slug`,
`/api/v1/resources` e `/api/v1/resources/:id`, sempre rispetto al dominio
corrente. La stessa proiezione alimenta pagine HTML delle risorse, sitemap,
JSON-LD e `llms.txt`. Alias e host alternativi vengono rediretti al canonical;
un dominio, Node o prodotto non pubblico restituisce `404`, mentre slug
pubblici ambigui restituiscono `409`. Le risposte supportano CORS pubblico,
cache condivisa, ETag e richieste condizionali. Il contratto è descritto in
[`../architecture/public-discovery-api.md`](../architecture/public-discovery-api.md).

Il piano esteso per SEO, API e AI è in
[`../architecture/flowpulse-ai-discovery-audit.md`](../architecture/flowpulse-ai-discovery-audit.md).

## Skill: contratto operativo e sincronizzazione

`ReusableSkill` resta separata da `ProblemSolvingCycle`. La prima descrive una
capacità riutilizzabile simile a un plugin; il secondo segue un problema
concreto e può utilizzare zero o più Skill senza diventare una Skill.

Le Skill possono usare altre Skill attraverso dipendenze esplicite. Non viene
imposta una gerarchia rigida: Percorsi può usare Corsi e Contenuti, mentre
Eventi può usare Contenuti e coordinare in seguito `DataSession` e `DataSlot`.
La risorsa prodotta rimane nel proprio model e appartiene al Node che ha
attivato la Skill.

La relazione `ReusableSkillNode` distingue la definizione del plugin dalla sua
attivazione su un Brand o progetto e possiede uno stato proprio: `draft`,
`active` oppure `suspended`. La configurazione specifica del Node resta sulla
relazione e non modifica la definizione comune.

Per il lavoro individuale iniziale si usa questo flusso:

```text
repository/development              deploy/production
skills.yml -- import/upsert ------> database operativo
skills.yml <-- export + commit ---- modifiche fatte nel database
```

I comandi sono:

```sh
bin/rails skills:validate OWNER=markpostura
bin/rails skills:import OWNER=markpostura
bin/rails skills:export OWNER=markpostura
bin/rails skills:dump OWNER=markpostura
```

L'hook `.kamal/hooks/post-deploy` importa automaticamente prima i Node, poi le
Skill e infine i Domain. In questo modo le attivazioni possono risolvere gli
slug dei Node e i Domain trovano a loro volta la struttura già aggiornata.

Import e validazione non eliminano record, dipendenze o attivazioni assenti
dal file. L'export effettuato sul server non aggiorna da solo la repository:
il file generato deve essere riportato in development, controllato e
committato. In produzione `skills:dump` permette di ottenere lo snapshot su
standard output senza affidarsi al filesystem temporaneo del container. Non è
prevista sincronizzazione bidirezionale automatica, perché
due modifiche concorrenti potrebbero sovrascriversi. Lo YAML conserva la
definizione generale, la documentazione, le dipendenze e le attivazioni per
slug; cronologia, risorse prodotte e dati sensibili restano nel database.

### Prodotti delle Skill

`SkillProduct` rappresenta ciò che una Skill produce in un Node. Appartiene a
`ReusableSkillNode`, quindi non duplica né la Skill né il Node produttore.
Conserva titolo, slug, stato, visibilità, formato, corpo Markdown, metadata
JSONB e l'eventuale `source_path`. Quest'ultimo è relativo alla radice della
repository ed è limitato a `config/data/`.

Il testo vive in `body`; `data` contiene soltanto i metadata specifici della
Skill. YAML è il formato dello snapshot, non una terza copia dentro il
database. `SkillProductLink` collega i prodotti con relazioni esplicite come
`contains`, `uses`, `presents` o `schedules`, evitando relazioni nascoste nel
JSON.

I prodotti con `source_path` vengono esportati nel file Markdown indicato; i
metadata confluiscono in `config/data/rails4b/skill_products.yml`. Un prodotto
senza percorso può essere lavorato nel database, ma non genera un file
Markdown separato finché non viene scelta la destinazione.

```sh
bin/rails skill_products:validate OWNER=markpostura
bin/rails skill_products:import OWNER=markpostura
bin/rails skill_products:export OWNER=markpostura
bin/rails skill_products:dump OWNER=markpostura
```

`skill_products:dump` include anche i corpi Markdown nello YAML stampato, così
una modifica nata in produzione può essere recuperata anche se il relativo
file vive nel filesystem temporaneo del container. Dopo aver riportato lo
snapshot in development, `skill_products:export` separa nuovamente i corpi nei
rispettivi `source_path`.

### Prova pilota rimandata: primo contenuto reale

La migrazione dei contenuti esistenti non blocca lo sviluppo del contratto
generale. Come prima prova verrà usato, in un passaggio successivo, il capitolo:

```text
config/data/brands/posturacorretta/courses/inizia-con-posturacorretta/chapters/incontro-salute-metodiche.md
```

La prova dovrà:

1. attivare la Skill `Contenuti` sul Node effettivamente responsabile del
   percorso online, senza assegnarla automaticamente alla radice del Brand;
2. creare un solo `SkillProduct` con `content_type: course_chapter`;
3. usare il file esistente come `source_path`, senza modificarne
   involontariamente il testo;
4. verificare import, export, pagina pubblica e collegamenti da Skill e Node;
5. accertare quale copia sia operativa e come venga consolidata nella
   repository prima di estendere la migrazione agli altri contenuti;
6. aggiungere la proiezione/API pubblica dei prodotti soltanto dopo questa
   verifica.

Stato: **rimandata, non bloccante**.

### Gestione completa delle attivazioni rimandata

In un passaggio successivo verrà completata la gestione di `ReusableSkillNode`:
stato dell'attivazione (`draft`, `active`, `suspended`), configurazione JSON,
responsabile dell'attivazione e pagina amministrativa comprensibile. La
semplice selezione del Node nella scheda della Skill resta una scorciatoia
temporanea e crea un'attivazione in bozza.

Questa attività è **rimandata e non bloccante**, come la prova sul primo
contenuto reale. Modelli, associazioni e campi già presenti rimangono la base
su cui costruire la futura interfaccia, senza introdurre ora altro lavoro.
