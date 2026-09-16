# Architettura editoriale — pagine YAML e componenti

> **Fonte di verità per il livello editoriale.** Questo documento riguarda
> esclusivamente Site, pagine YAML, componenti, Track editoriali, Mount,
> domini, anteprime e visibilità. Non introduce nuove tabelle.
>
> Content, DataSession, DataSlot, Cycle e Service restano separati e sono
> descritti in
> [ARCHITETTURA_CICLI_CONTENUTI_E_SERVIZI.md](ARCHITETTURA_CICLI_CONTENUTI_E_SERVIZI.md).

## Obiettivo

Costruire le landing e le pagine editoriali dei diversi Node/Brand usando:

- file YAML versionati;
- componenti Rails autorizzati;
- un tema specifico per ogni Brand;
- proprietà assegnata a un Node;
- pubblicazione tramite Domain e indirizzi controllati;
- visibilità inizialmente `public` o `superadmin`.

Quasi tutti i domini potranno iniziare da una pagina costruita dal Page
Builder. Le funzioni realmente operative continueranno a usare controller e
action Rails dedicati.

## Decisioni da risolvere in ordine

1. vocabolario;
2. struttura delle cartelle;
3. schema di `site.yml`;
4. schema di una pagina;
5. proprietà e pubblicazione;
6. Mount e indirizzi;
7. responsabilità del Page Builder;
8. registro dei componenti;
9. varianti grafiche e temi;
10. fonti editoriali;
11. stato e visibilità;
12. validazione;
13. gestione degli errori;
14. migrazione dei file esistenti;
15. pilota MarkPostura.

## Decisione 1 — vocabolario

**Stato: confermata.**

`path` viene utilizzato esclusivamente per un percorso URL. Non indica mai un
percorso editoriale.

`track` è il termine tecnico usato nei file YAML e nel codice per indicare un
percorso editoriale ordinato. Nell'interfaccia pubblica il termine mostrato
rimane **Percorso**.

Esempio:

```yml
page:
  kind: track
  track_key: percorso-posturacorretta

mounts:
  - domain: posturacorretta.org
    path: /
```

Questa distinzione vale anche per Rails4Business:

- Track tecnico `collaborare` → “Voglio collaborare” nell'interfaccia;
- Track tecnico `ho-un-progetto` → “Ho un progetto” nell'interfaccia.

## Decisione 2 — struttura delle cartelle

**Stato: confermata.**

Le configurazioni editoriali dei siti vivono in:

```text
config/data/sites/<node_slug>_<locale>/
```

Il suffisso indica la lingua o variante editoriale, non l'estensione del
dominio. Per esempio PosturaCorretta utilizza:

```text
config/data/sites/posturacorretta_it/
```

anche se il dominio primario è `posturacorretta.org`.

La struttura canonica è:

```text
config/data/sites/posturacorretta_it/
├── site.yml
├── mounts.yml
├── pages/
├── tracks/
├── documents/
└── shared/
```

- `site.yml`: Node proprietario, lingua, tema, domini, navigazione, footer e
  ingresso principale;
- `mounts.yml`: indirizzi canonici e redirect delle risorse editoriali;
- `pages/`: pagine costruite dal Page Builder;
- `tracks/`: percorsi editoriali ordinati, chiamati “Percorsi” nel frontend;
- `documents/`: testi Markdown editoriali richiamabili tramite chiave;
- `shared/`: soli dati editoriali condivisi tra più pagine dello stesso Site.

Una nuova cartella viene creata soltanto quando cambia almeno una caratteristica
editoriale reale, come lingua, contenuto, tema o pubblico. Alias e redirect non
generano nuove cartelle.

Esempio:

```text
posturacorretta.org     → sites/posturacorretta_it
www.posturacorretta.org → redirect/alias, nessuna nuova cartella
posturacorretta.org/en  → potenziale sites/posturacorretta_en
```

Cataloghi Content, eventi, settimane, Accademia e dati operativi non vengono
spostati in `sites`: appartengono all'architettura dinamica o alle fonti già
esistenti e verranno collegati in seguito tramite sorgenti autorizzate.

## Decisione 3 — schema di `site.yml`

**Stato: confermata.**

`site.yml` contiene l'identità editoriale del Site, non replica la
configurazione degli hostname. `config/domains.yml` rimane la fonte di verità
per dominio canonico, alias e redirect e collegherà progressivamente ciascun
dominio al Site tramite `site_key`.

Schema minimo:

```yml
schema_version: 1

site:
  key: posturacorretta_it
  node_slug: posturacorretta
  locale: it
  theme: posturacorretta

  entrypoint:
    mount: home

  navigation:
    items:
      - label: Home
        page: home
      - label: Lezioni
        route: /posturacorretta/lezioni
      - label: Contenuti
        route: /posturacorretta/contenuti

  footer:
    tagline: Conosci il corpo, amplia il tuo punto di vista.
    items:
      - label: Contatti
        page: contatti
```

Responsabilità dei campi:

- `schema_version`: versione verificabile del formato;
- `key`: coincide con il nome della cartella del Site;
- `node_slug`: Node proprietario;
- `locale`: lingua editoriale;
- `theme`: tema registrato;
- `entrypoint`: Mount aperto come ingresso principale del Site;
- `navigation` e `footer`: elementi comuni alle pagine del Site.

Un elemento di navigazione può puntare a una pagina del Site, a una route Rails
esistente o, in futuro, a un Track registrato. Non può dichiarare liberamente
controller e action.

Esempio di associazione nel registro domini:

```yml
posturacorretta.org:
  site_key: posturacorretta_it
  node_slug: posturacorretta
  primary: true

www.posturacorretta.org:
  canonical_host: posturacorretta.org
```

### Compatibilità durante la migrazione

L'introduzione di `site_key` è incrementale. I domini che non sono ancora
migrati continuano a usare `target_controller` e `target_action`. Il resolver
del Site verrà attivato un Brand alla volta e il comportamento corrente rimane
il fallback fino alla verifica della nuova pagina.

`site.yml` non contiene componenti delle singole pagine, contenuti, eventi,
Session, permessi delle pagine né una copia degli hostname.

## Decisione 4 — schema di una pagina YAML

**Stato: confermata.**

Ogni file in `pages/` descrive esclusivamente una pagina costruita dal Page
Builder. Il nome del file coincide con `page.key`.

Schema minimo:

```yml
schema_version: 1

page:
  key: home
  owner_node_slug: markpostura
  kind: landing
  renderer: builder
  title: Mark Postura
  description: Tre progetti, una visione.
  status: published
  visibility: public

components:
  - id: introduzione
    type: hero
    variant: split
    data:
      eyebrow: postura · natura · tecnologia
      title: Tre progetti, una visione.
      description: ...

  - id: progetti
    type: project_cards
    variant: three_columns
    items: []
```

Regole:

- `key` è l'identificatore interno stabile e coincide con il nome del file;
- `owner_node_slug` è obbligatorio anche quando coincide con il Node del Site;
- `kind` è inizialmente `landing`, `static`, `track` o `catalog`;
- `renderer` per i file dentro `pages/` è `builder`;
- `status` è inizialmente `draft`, `published` o `archived`;
- `visibility` è inizialmente `public` o `superadmin`;
- ogni componente possiede un `id` stabile e un `type` registrato;
- `variant`, `data`, `items` e `source` dipendono dal componente.

L'ID del componente può essere usato come ancora, riferimento di navigazione,
selettore nei test e identificatore per un futuro editor.

Una pagina di tipo Track rimane una pagina Builder e incorpora il relativo
indice tramite una sorgente autorizzata:

```yml
page:
  key: percorso
  owner_node_slug: posturacorretta
  kind: track
  renderer: builder
  title: Percorso PosturaCorretta
  description: ...
  status: published
  visibility: public

components:
  - id: indice
    type: track_index
    source:
      type: track
      key: percorso-posturacorretta
```

Dominio, URL, alias, locale, tema e controller/action non appartengono al file
della pagina. Vengono risolti rispettivamente da Mount, Site e registri
applicativi autorizzati.

## Decisione 5 — proprietà e pubblicazione

**Stato: confermata.**

Ogni pagina ha un solo Node proprietario, dichiarato tramite
`owner_node_slug`. Il Site stabilisce l'identità grafica e il Mount assegna
l'indirizzo: nessuno dei due modifica la proprietà.

```text
owner_node_slug → responsabilità della pagina
Site            → identità editoriale e grafica
Mount           → indirizzo di pubblicazione
```

Nella prima versione un Site può pubblicare soltanto:

1. pagine possedute dal proprio Node;
2. pagine possedute da un Node discendente del proprio Node.

Esempio valido:

```text
PosturaCorretta
└── Canale YouTube PosturaCorretta
    └── pagina pubblicata nel Site posturacorretta_it
```

La relazione `professional_owner_node_id` non autorizza automaticamente la
pubblicazione incrociata tra Brand differenti. Una pagina appartenente a un
altro Brand viene inizialmente collegata tramite il suo URL canonico, non
duplicata o rimontata. Eventuali concessioni esplicite verranno valutate dopo
l'MVP.

L'identità editoriale globale di una pagina è composta da:

```text
site_key + page.key
```

Per esempio `markpostura_it:home` e `posturacorretta_it:home` sono pagine
distinte anche se condividono la stessa chiave locale.

Regole confermate:

- un solo `owner_node_slug` per pagina;
- il Site ha un solo Node principale;
- il proprietario deve essere il Node del Site o un suo discendente;
- cambiare Site, dominio o URL non trasferisce la proprietà;
- una pagina ha un solo Mount canonico;
- alias e redirect non duplicano la pagina;
- il Site non può ampliare la visibilità dichiarata dalla pagina.

## Decisione 6 — Mount e indirizzi

**Stato: confermata.**

Gli indirizzi editoriali di un Site sono dichiarati nel file separato
`mounts.yml`. La pagina descrive il contenuto, il Mount decide dove
pubblicarlo e `config/domains.yml` determina su quale dominio viene esposto il
Site.

```text
Domain → Site → Mount → Page
```

Schema iniziale:

```yml
schema_version: 1
site_key: markpostura_it

mounts:
  - key: home
    path: /
    resource:
      type: page
      key: home

  - key: chi-sono
    path: /chi-sono
    resource:
      type: page
      key: chi-sono

redirects:
  - from: /about
    to: /chi-sono
    status: moved_permanently
```

Ogni Mount possiede:

- una `key` stabile e univoca nel Site;
- un `path` normalizzato e univoco nel Site;
- una risorsa identificata tramite `type` e `key`.

Nell'MVP il solo tipo montabile è `page`. Le pagine di tipo `track` e
`catalog` restano pagine Builder: sono i loro componenti a caricare le fonti
editoriali autorizzate. Le applicazioni operative conservano invece route,
controller e action Rails espliciti.

### Indirizzo canonico e alias

L'URL canonico viene derivato da:

```text
dominio primario in config/domains.yml + path del Mount
```

Non viene scritto manualmente nella pagina. Ogni pagina ha un solo Mount
canonico. Gli altri indirizzi sono redirect e non copie della pagina:

- gli alias di dominio vengono gestiti tramite `canonical_host` nel registro
  domini;
- gli alias di percorso vengono dichiarati in `redirects` dentro
  `mounts.yml`;
- un redirect deve terminare su un Mount canonico dello stesso Site;
- i redirect permanenti usano `moved_permanently`.

### Regole per i percorsi

- iniziano sempre con `/`;
- la radice è esattamente `/`;
- non terminano con `/`, eccetto la radice;
- usano lettere minuscole e parole separate da trattini;
- non contengono dominio, query string o frammento;
- la coppia `site_key + path` deve essere univoca;
- non possono entrare in conflitto con route Rails riservate o già
  esistenti.

Il resolver editoriale generico verrà collocato dopo tutte le route Rails
esplicite. In questo modo dashboard, amministrazione e strumenti operativi
mantengono la precedenza.

### Ingresso e anteprima locale

`site.yml` individua l'ingresso attraverso la chiave del Mount, senza
duplicare pagina e percorso:

```yml
entrypoint:
  mount: home
```

Per l'anteprima locale verrà usato lo stesso registro dei Mount, con un
prefisso tecnico:

```text
/sites/markpostura_it
/sites/markpostura_it/chi-sono
```

L'anteprima non crea URL canonici alternativi e rispetta stato e visibilità
della pagina. Prima del rendering devono essere verificati esistenza della
risorsa, proprietà, stato e permessi.

## Decisione 7 — responsabilità del Page Builder

**Stato: confermata.**

Il Page Builder è un renderer, non un router, un sistema di autorizzazione o
un caricatore generico di file. Riceve una pagina già risolta, caricata,
validata e autorizzata e ne renderizza esclusivamente i componenti registrati.

La sequenza di responsabilità è:

```text
SiteResolver  → identifica il Site dal dominio
MountResolver → identifica il Mount e la risorsa
PageLoader    → carica e valida la pagina YAML
AccessPolicy  → verifica proprietà, stato e visibilità
PageBuilder   → renderizza i componenti registrati
Theme/Layout  → applica l'identità grafica del Site
```

Il Page Builder può:

- renderizzare i componenti presenti nel registro applicativo;
- passare al componente soltanto i dati previsti dal suo schema;
- comporre componenti annidati quando il tipo lo consente;
- usare sorgenti editoriali esplicitamente registrate, per esempio `track` e
  `shared` e, in futuro, cataloghi Content controllati;
- produrre informazioni diagnostiche utili in anteprima e nei log.

Il Page Builder non può:

- scegliere dominio, URL, Mount, redirect o pagina canonica;
- decidere proprietà, stato, visibilità o permessi;
- caricare un file da un percorso arbitrario scritto nello YAML;
- eseguire nomi liberi di partial, classi, controller o action;
- interrogare direttamente modelli o servizi non registrati;
- modificare file, database o stato applicativo durante il rendering;
- ampliare la visibilità della pagina o della sua sorgente.

Layout, navigazione, footer, lingua e tema provengono dal Site. Titolo,
metadati e sequenza dei componenti provengono dalla pagina. URL e canonical
provengono dal Mount e dal registro domini.

Un componente o una sorgente sconosciuti non vengono ignorati né interpretati
liberamente: generano un errore controllato. In anteprima l'errore deve essere
descrittivo; in produzione verrà gestito secondo la strategia definita nelle
decisioni 12 e 13.

Questa separazione permette di riutilizzare lo stesso Builder tra Brand
diversi senza accoppiare i loro contenuti alle route o alle regole operative.

## Decisione 8 — registro dei componenti

**Stato: confermata.**

I componenti utilizzabili dal Page Builder appartengono a un registro
applicativo esplicito. Il valore `type` presente nello YAML è una chiave
pubblica stabile: non viene mai trasformato direttamente nel nome di una
partial o di una classe.

Esempio concettuale:

```ruby
{
  "hero" => {
    partial: "components/hero",
    variants: %w[default split compact],
    allowed_sources: []
  },
  "track_index" => {
    partial: "components/track_index",
    variants: %w[sidebar stepper],
    allowed_sources: %w[track]
  }
}
```

Per ciascun tipo il registro definisce:

- chiave pubblica `type`;
- partial Rails autorizzata;
- varianti consentite;
- campi obbligatori e facoltativi;
- possibilità e regole di annidamento;
- sorgenti dati autorizzate;
- eventuali limiti sul numero di elementi.

Il registro risiede nel codice Rails e non nei file YAML editoriali. Gli
editor possono scegliere soltanto componenti, varianti e sorgenti già
registrati. Aggiungere un nuovo tipo richiede quindi una modifica applicativa,
la sua partial, la validazione e i relativi test.

I primi candidati generici, già presenti o ricavabili dai componenti
esistenti, sono:

```text
hero
title
text
image
markdown
section_header
card
feature_grid
accordion
url_tabs
brand
```

I componenti specifici, per esempio `project_cards`, vengono registrati solo
dopo aver verificato che abbiano un contratto stabile e riutilizzabile. Un
componente specifico di un solo Brand non deve diventare automaticamente parte
del nucleo comune.

Restano tre registri distinti:

```text
ComponentRegistry → componenti, partial, campi e annidamento
SourceRegistry    → fonti editoriali o dinamiche consultabili
ThemeRegistry     → temi e varianti grafiche disponibili
```

Un tipo, una variante o una sorgente non registrati producono un errore
controllato. Il fallback grafico non può essere usato per aggirare una
validazione mancante.

## Decisione 9 — temi e varianti grafiche

**Stato: confermata.**

Il tema definisce l'identità grafica dell'intero Site. La variante definisce
invece una presentazione autorizzata di un singolo componente.

```text
Theme   → identità dell'intero Site
Variant → presentazione consentita di un componente
```

Il tema viene scelto una sola volta in `site.yml`:

```yml
site:
  theme: markpostura
```

Il `ThemeRegistry` associa una chiave registrata a:

- layout Rails;
- fogli di stile e token grafici;
- colori e tipografia;
- logo, favicon e asset istituzionali;
- larghezza e spaziatura dei contenuti;
- navigazione e footer;
- stati interattivi comuni.

La pagina non può cambiare liberamente il tema del Site. Un componente può
scegliere soltanto una variante ammessa dal `ComponentRegistry`:

```yml
- id: introduzione
  type: hero
  variant: split
```

Regole confermate:

- niente classi CSS o Tailwind arbitrarie nei file editoriali;
- niente colori esadecimali o font dichiarati nelle singole pagine;
- le varianti usano nomi funzionali, per esempio `split`, `compact` o
  `stepper`;
- colori, font, spaziature e stati focus derivano dai token del tema;
- ogni tema deve supportare layout responsive e accessibilità;
- nell'MVP ogni Site utilizza un solo tema principale;
- una modalità scura viene introdotta solo per un'esigenza esplicita;
- il codice dei temi può condividere una base comune, ma gli YAML non
  configurano catene di ereditarietà;
- logo e favicon appartengono al tema, mentre le immagini editoriali
  appartengono alle pagine o alle loro fonti.

Lo stesso componente può quindi essere riutilizzato con identità differenti:

```text
hero + tema markpostura
hero + tema posturacorretta
hero + tema rails4b
```

La struttura HTML e il contratto dei dati restano comuni; il tema ne determina
la presentazione senza duplicare la pagina.

## Decisione 10 — fonti editoriali

**Stato: confermata.**

Il Page Builder può utilizzare soltanto fonti riconosciute dal
`SourceRegistry`. Le prime quattro fonti editoriali sono:

```text
inline   → dati scritti direttamente nel componente
shared   → dati riutilizzabili nello stesso Site
track    → sequenza editoriale ordinata
document → testo Markdown editoriale
```

Esempi di riferimenti:

```yml
source:
  type: track
  key: voglio-collaborare
```

```yml
source:
  type: shared
  key: contatti
```

```yml
source:
  type: document
  key: guarda-flowpulse
```

Le chiavi vengono risolte internamente e non sono percorsi:

```text
track: voglio-collaborare  → tracks/voglio-collaborare.yml
shared: contatti           → shared/contatti.yml
document: guarda-flowpulse → documents/guarda-flowpulse.md
```

Non sono consentiti separatori di directory, percorsi assoluti o segmenti
come `..` nelle chiavi delle sorgenti.

### Schema iniziale di un Track

```yml
schema_version: 1

track:
  key: voglio-collaborare
  owner_node_slug: rails4b
  title: Voglio collaborare
  status: published
  visibility: public

items:
  - id: guarda-flowpulse
    position: 1
    title: Guarda Flowpulse
    document: guarda-flowpulse

  - id: installa-dash
    position: 2
    title: Installa Dash Wallet
    document: installa-dash
```

Il Track ordina i passi e conserva le informazioni necessarie all'indice; il
testo esteso rimane nel relativo documento. Ogni `id` e ogni `position` devono
essere univoci nel Track.

Regole confermate:

- una pagina può leggere soltanto fonti appartenenti al proprio Site;
- `shared` contiene piccoli blocchi riutilizzabili, non pagine complete;
- `documents` contiene Markdown editoriale, non HTML arbitrario;
- `tracks` ordina documenti o collegamenti senza duplicarne il testo;
- nessun file può indicare liberamente un percorso del filesystem;
- la visibilità effettiva è sempre quella più restrittiva tra pagina e
  sorgenti incorporate;
- non sono ammessi riferimenti diretti tra cartelle di Site differenti;
- immagini e link sono sottoposti a validazione dedicata;
- una sorgente mancante o non registrata genera un errore controllato.

I futuri Content provenienti dal database saranno esposti come una nuova
sorgente registrata. Questo permetterà di sostituire progressivamente un
documento editoriale con un Content senza modificare il contratto del
componente che lo visualizza.

## Decisione 11 — stato e visibilità

**Stato: confermata.**

Stato editoriale e visibilità rispondono a due domande distinte:

```text
status     → a che punto è la risorsa editoriale?
visibility → chi può visualizzarla?
```

Gli stati iniziali sono:

- `draft`: risorsa in lavorazione, disponibile soltanto in anteprima
  amministrativa;
- `published`: risorsa utilizzabile secondo la visibilità dichiarata;
- `archived`: risorsa ritirata dal Site, disponibile soltanto in anteprima
  amministrativa.

Le visibilità iniziali sono:

- `public`: accessibile a tutti quando la risorsa è pubblicata;
- `superadmin`: accessibile esclusivamente a un superadmin autenticato.

La matrice risultante è:

| Stato e visibilità | Accesso pubblico | Accesso superadmin |
| --- | --- | --- |
| `draft` | no | solo anteprima |
| `published` + `public` | sì | sì |
| `published` + `superadmin` | no | sì |
| `archived` | no | solo anteprima |

Regole confermate:

- Mount, Site e parametri della richiesta non possono ampliare la visibilità;
- una risorsa non accessibile pubblicamente risponde con `404`, senza
  confermarne l'esistenza;
- bozze e risorse archiviate non entrano in navigazione, sitemap, cataloghi o
  ricerca pubblica;
- le pagine `superadmin` inviano `noindex, nofollow` e non vengono conservate
  in cache pubbliche;
- in produzione l'anteprima passa da una route amministrativa autenticata;
- il prefisso tecnico `/sites/...` è disponibile soltanto in sviluppo;
- nell'MVP non vengono aggiunte visibilità intermedie come `member`, `creator`
  o `operator`;
- non vengono introdotte pubblicazioni programmate: un file diventa pubblico
  tramite `status: published` e relativo deploy;
- pagina e Track dichiarano stato e visibilità propri;
- `shared` e `document` non sono montabili direttamente e ricevono le
  restrizioni della risorsa che li incorpora;
- quando più risorse partecipano al rendering prevalgono stato e visibilità
  più restrittivi.

L'accesso amministrativo non rende canonica o indicizzabile un'anteprima. Le
future autorizzazioni di Content, servizi e partecipazioni resteranno parte
dell'architettura dinamica e non verranno simulate con nuove visibilità YAML.

## Decisione 12 — validazione

**Stato: confermata.**

Site e risorse editoriali vengono verificati prima del deploy attraverso un
validatore unico:

```bash
bin/rails sites:validate
```

La validazione procede per livelli:

```text
1. sintassi YAML e Markdown
2. schema del singolo file
3. riferimenti tra risorse
4. regole complessive del Site
5. compatibilità con domini e route Rails
```

Sono errori bloccanti:

- YAML non valido o `schema_version` sconosciuta;
- `site.key` diverso dal nome della cartella;
- chiavi duplicate;
- pagina, Track, documento o dato condiviso referenziati ma inesistenti;
- `page.key` diverso dal nome del file;
- Node proprietario mancante o non autorizzato;
- tema, componente, variante o sorgente non registrati;
- campo obbligatorio assente o campo non consentito;
- ID di componenti o posizioni di Track duplicate;
- Mount duplicati o percorsi non normalizzati;
- conflitti con route Rails esplicite;
- entrypoint inesistente;
- redirect circolari o diretti a destinazioni inesistenti;
- combinazioni incoerenti di stato o visibilità;
- HTML arbitrario nei documenti Markdown;
- immagini pubblicate prive di testo alternativo, salvo quelle dichiarate
  decorative.

Sono avvisi non bloccanti:

- pagina valida ma non montata;
- documento o dato `shared` non utilizzato;
- metadati SEO facoltativi mancanti;
- collegamento esterno non verificabile;
- asset potenzialmente troppo pesante;
- Track privo di descrizione;
- redirect temporaneo rimasto configurato a lungo.

Il comando restituisce un riepilogo adatto sia alla lettura sia
all'automazione:

```text
Sites: 3
Pages: 12
Mounts: 15
Errors: 0
Warnings: 4
```

Sono previste due modalità:

```bash
bin/rails sites:validate
bin/rails sites:validate STRICT=1
```

La modalità normale fallisce in presenza di errori; la modalità `STRICT=1`
fallisce anche in presenza di avvisi.

Regole operative:

- tutti i file, incluse bozze e risorse `superadmin`, devono essere
  strutturalmente validi;
- il deploy esegue almeno la modalità normale;
- la prima richiesta web non deve essere il momento in cui si scopre un
  errore editoriale;
- il runtime mantiene comunque controlli difensivi;
- il validatore non modifica automaticamente i file;
- i collegamenti esterni non vengono contattati durante il deploy, evitando
  che la rete renda instabile la pubblicazione.

## Decisione 13 — gestione degli errori a runtime

**Stato: confermata.**

Il runtime fallisce in modo chiuso e prevedibile. Gli errori editoriali non
devono esporre informazioni interne né produrre silenziosamente pagine
incomplete.

Comportamenti HTTP pubblici:

| Condizione | Risposta |
| --- | --- |
| dominio o percorso sconosciuto | `404` |
| pagina inesistente, non pubblicata o non autorizzata | `404` |
| redirect valido | codice configurato |
| pagina configurata ma non renderizzabile | `500` generico |
| registro editoriale indisponibile | `503` |

Le risposte pubbliche non mostrano percorsi dei file, chiavi private,
contenuto YAML grezzo, stack trace o dettagli sull'esistenza di risorse
`superadmin`.

Un errore strutturale in un componente o in una sorgente obbligatoria
interrompe il rendering dell'intera pagina. Il Builder non salta
silenziosamente la parte difettosa, perché una pagina apparentemente valida ma
incompleta potrebbe comunicare informazioni errate.

Gli errori vengono registrati in forma strutturata, per esempio:

```json
{
  "event": "editorial_render_error",
  "site_key": "markpostura_it",
  "mount_key": "home",
  "page_key": "home",
  "component_id": "progetti",
  "error_code": "unknown_variant",
  "request_id": "..."
}
```

Regole confermate:

- l'anteprima superadmin mostra una spiegazione utile senza rivelare dati
  sensibili;
- in produzione gli YAML provengono dalla versione deployata e non vengono
  ricaricati a caldo;
- in sviluppo un reload non valido mostra chiaramente l'errore;
- un asset esterno irraggiungibile utilizza il fallback grafico previsto e
  non manda in errore Rails;
- una sorgente editoriale obbligatoria mancante interrompe il rendering;
- il controller precedente rimane fallback soltanto per domini privi di
  `site_key`;
- dopo l'assegnazione di `site_key`, un errore non viene nascosto tornando
  silenziosamente alla pagina precedente;
- gli errori ripetuti possono essere aggregati nei log per evitare ulteriore
  sovraccarico;
- health check e pagine di errore non dipendono dal Page Builder.

Il validatore rimane la difesa principale; questi comportamenti proteggono
l'applicazione quando un errore sfugge ai controlli preventivi o si manifesta
soltanto a runtime.

## Decisione 14 — migrazione dei file esistenti

**Stato: confermata.**

La migrazione procede in modo incrementale, un Site alla volta. Non viene
effettuato uno spostamento massivo dei file esistenti.

Per ciascun dominio il flusso è:

```text
1. inventario delle sorgenti attuali
2. creazione della nuova cartella Site
3. conversione manuale della pagina principale
4. anteprima amministrativa protetta
5. confronto visivo e funzionale
6. validazione del Site
7. associazione del site_key al dominio
8. verifica in produzione
9. rimozione successiva delle vecchie sorgenti
```

Durante la preparazione:

- il dominio continua a utilizzare controller e file correnti;
- il nuovo Site è raggiungibile soltanto tramite anteprima autorizzata;
- i file originali non vengono subito spostati o cancellati;
- non vengono modificati database e modelli;
- non viene costruito un convertitore automatico prima di aver verificato il
  pilota.

L'attivazione avviene aggiungendo il riferimento nel registro domini:

```yml
posturacorretta.org:
  site_key: posturacorretta_it
```

Da quel momento il dominio utilizza il nuovo Site. Il codice precedente può
restare temporaneamente nel repository per consentire un rollback tramite
Git, ma non viene utilizzato come fallback silenzioso a runtime.

Ordine iniziale di migrazione:

1. MarkPostura, come pilota semplice;
2. Rails4Business, per verificare Track e documenti Markdown;
3. Flowpulse, come landing istituzionale;
4. Percorso Integrato e Radioestesia, come Site distinti;
5. PosturaCorretta, per ultimo, perché unisce percorso editoriale e funzioni
   operative.

Ogni migrazione verifica almeno:

- URL canonici e redirect;
- navigazione e footer;
- testi, immagini e asset;
- resa mobile e accessibilità essenziale;
- metadati e indicizzazione;
- pagine riservate al superadmin;
- funzionamento delle route operative esistenti;
- confronto con la versione precedente.

La conversione è intenzionalmente manuale nella prima fase: devono essere
trasferiti i contenuti e i comportamenti utili, non le duplicazioni o gli
accoppiamenti specifici accumulati nel sistema precedente.

## Decisione 15 — pilota MarkPostura

**Stato: confermata.**

MarkPostura è il primo Site usato per verificare l'architettura editoriale. Il
pilota viene costruito e provato senza modificare inizialmente la pagina
pubblica.

La struttura prevista è:

```text
config/data/sites/markpostura_it/
├── site.yml
├── mounts.yml
├── pages/
│   └── home.yml
├── tracks/
├── documents/
└── shared/
```

La pagina `home.yml` riprende le sezioni statiche già presenti:

- introduzione con immagine;
- presentazione personale;
- i tre progetti;
- organizzazione tra Brand, progetti e processi;
- passi per entrare;
- presentazione di Flowpulse;
- libro;
- contatti.

Il tema `markpostura` mantiene l'attuale impostazione chiara.

### Funzioni escluse dal Builder nel pilota

Week Plan, contenuti, eventi, dettagli dei contenuti, cataloghi dinamici e
route amministrative non vengono trasferiti nel Page Builder. Continuano a
funzionare tramite le route Rails esistenti:

```text
/markpostura/weekplan
/markpostura/contenuti
/markpostura/eventi
```

La nuova pagina può collegare queste funzioni dalla navigazione, senza
incorporarne ancora la logica.

### Componenti iniziali

Il registro del pilota comprende soltanto componenti generici:

```text
hero
section_header
text
image
card
feature_grid
steps
call_to_action
```

`steps` rappresenta sequenze ordinate come “Come si entra”;
`call_to_action` copre inviti come Flowpulse e contatti. Non vengono creati
componenti con nomi o contratti specifici di MarkPostura.

### Nucleo da implementare

Il pilota comprende:

1. repository sicuro dei Site;
2. caricamento di `site.yml`, `mounts.yml` e pagine;
3. registri iniziali di componenti e tema;
4. validazione eseguibile;
5. Page Builder basato sul registro;
6. anteprima protetta per il superadmin;
7. anteprima locale in sviluppo;
8. test di caricamento, visibilità e rendering;
9. confronto con la pagina attuale.

Non vengono modificati database o modelli.

### Attivazione

**Stato: implementata.**

Il dominio utilizza il Site editoriale:

```yml
site_key: markpostura_it
```

La route locale `/markpostura` utilizza la stessa pagina YAML del dominio. La
vecchia sorgente `config/data/markpostura/home.json`, il relativo servizio e
la vista duplicata sono stati rimossi.

La configurazione del Week Plan vive in:

```text
config/data/sites/markpostura_it/shared/week_plan.yml
```

Le singole settimane restano dati operativi separati in:

```text
config/data/markpostura/settimane/*.yml
```

Il deploy importa automaticamente `config/domains.yml` nel database tramite
l'hook `.kamal/hooks/post-deploy`, rendendo effettivo `site_key` anche in
produzione.
