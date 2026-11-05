# Migrazione della home di un dominio verso Node Show

## Obiettivo

Consentire a ogni dominio di scegliere in modo esplicito quale sistema deve
renderizzare la home:

1. una landing/sito editoriale già esistente;
2. un controller legacy;
3. il `Node Show` del Node collegato al dominio.

La prima migrazione sarà `posturacorretta.org`:

- `/` dovrà mostrare il Node `posturacorretta` tramite `nodes/show`;
- la home attuale non verrà eliminata;
- la home attuale diventerà una pagina interna raggiungibile dal menu;
- il passaggio dovrà poter essere annullato cambiando una configurazione, senza
  ripristinare codice o contenuti cancellati.

## Situazione attuale

### Collegamento fra Domain e Node

Il collegamento esiste già:

```text
Domain.node_id -> Node.id
```

Nello YAML viene espresso mediante:

```yaml
node_slug: posturacorretta
```

Il Domain `posturacorretta.org` è quindi già associato al Node
`posturacorretta`.

I suoi discendenti non devono avere un Domain ciascuno. Appartengono al sito
perché risalgono al primo antenato con un dominio attivo (`Node#site_node`).

### Ordine attuale di risoluzione della home

`DomainsController#dispatch_domain_action` applica già questo ordine:

1. sito editoriale indicato da `site_key`;
2. `target_controller` e `target_action`;
3. Node collegato al Domain, renderizzato con `nodes/show`;
4. primo Node root pubblico del Creator;
5. landing FlowPulse di emergenza.

Il principio «se non esiste una landing, usa Node Show» è quindi già presente.
Non è però ancora abbastanza esplicito e controllabile per una migrazione
graduale.

### Eccezione PosturaCorretta

PosturaCorretta non raggiunge normalmente questo resolver, perché nelle route
esiste una regola con priorità maggiore:

```ruby
constraints ->(request) { request.host == "posturacorretta.org" } do
  get "/", to: "posturacorretta/learning#index"
end
```

Inoltre il Domain conserva contemporaneamente:

```yaml
site_key: posturacorretta_it
target_controller: brands/posturacorretta
target_action: home
node_slug: posturacorretta
```

Oggi ci sono quindi tre candidati alla home e una route speciale che decide
prima del Domain.

## Decisione proposta: selettore esplicito della home

Introduciamo nelle impostazioni del Domain un campo `home_mode`.

Valori ammessi:

| Valore | Comportamento |
| --- | --- |
| `auto` | Compatibilità attuale: site, target, Node, fallback |
| `node` | La home è sempre il Node collegato al dominio |
| `site` | La home è il sito editoriale configurato con `site_key` |
| `target` | La home è il controller/action legacy |

Il valore predefinito sarà `auto`, così gli altri domini non cambieranno
comportamento.

Esempio futuro per PosturaCorretta:

```yaml
posturacorretta.org:
  home_mode: node
  node_slug: posturacorretta
  site_key: posturacorretta_it
  target_controller: brands/posturacorretta
  target_action: home
```

`site_key` e `target_*` possono restare temporaneamente configurati. Con
`home_mode: node` non controllano più `/`, ma restano disponibili per rollback
e per la migrazione della vecchia pagina.

Questa soluzione è preferibile alla cancellazione immediata di `site_key` e
`target_*`, perché rende il passaggio reversibile e documenta chiaramente
l'intenzione.

## Regola definitiva della home

Il resolver dovrà funzionare così:

```text
richiesta GET /
        |
        v
Domain attivo e canonico
        |
        v
home_mode
  |-- node   -> render nodes/show con Domain.node
  |-- site   -> render sito indicato da site_key
  |-- target -> esegui target_controller/target_action
  `-- auto   -> site > target > node > fallback
```

Se viene richiesto `node` ma il Domain non possiede un Node pubblico valido,
la risposta non deve cadere silenziosamente su una landing differente. Deve
produrre un errore di configurazione visibile agli amministratori e una
risposta pubblica sicura.

## Nuova home di PosturaCorretta

Con `home_mode: node`:

```text
https://posturacorretta.org/
```

renderizzerà:

```text
Node posturacorretta
-> PublicNodePresentation
-> app/views/nodes/show.html.erb
-> layout public_node
```

Il Node continuerà a fornire:

- identità e navigazione del dominio;
- breadcrumb e figli;
- contenuto Lexxy/Action Text;
- copia Markdown derivata;
- sezioni determinate da `view_type`;
- accesso alla rete contestuale;
- stato e visibilità pubblica.

La route specifica di `/` per `posturacorretta.org` dovrà essere rimossa. Tutte
le home dei domini passeranno così dallo stesso `DomainsController`.

## Destinazione della home attuale

La home attuale non deve essere cancellata né copiata subito dentro un nuovo
template. Nella prima fase diventa una pagina interna stabile.

Slug consigliato:

```text
/percorso-posturacorretta
```

Titolo della pagina e voce menu confermati:

```text
Percorso
```

La navigazione principale conterrà due voci distinte:

```text
Home       -> /
Percorso   -> /percorso-posturacorretta
```

`Home` indica la nuova home basata sul Node `posturacorretta`. `Percorso`
indica la pagina che conserva l'attuale home educativa caricata da
`Posturacorretta::LearningController#index`.

### Fase transitoria

La pagina:

```text
https://posturacorretta.org/percorso-posturacorretta
```

continua a usare:

```text
Posturacorretta::LearningController#index
```

con tutti i dati e i partial già esistenti. Non si duplica il codice della
landing.

### Rappresentazione come Node

Creiamo anche un Node pubblico:

```yaml
percorso-posturacorretta:
  title: Percorso PosturaCorretta
  parent_slug: posturacorretta
  status: published
  visibility: public
```

Durante la transizione, lo slug viene intercettato da un renderer legacy
controllato. Successivamente il contenuto può essere trasferito nel Node e la
stessa URL inizierà a usare il normale `Node Show`.

Non conviene salvare nel database nomi arbitrari di controller o partial.
Meglio utilizzare un `view_type` ammesso da una lista chiusa, per esempio:

```text
legacy_posturacorretta_path
```

Il dispatcher associa esplicitamente quel valore all'action esistente. In
questo modo non introduciamo un sistema di rendering dinamico insicuro.

Quando la migrazione del contenuto sarà terminata:

1. il Node passa a un normale `view_type` (`landing`, `index` o `default`);
2. si rimuove il renderer legacy;
3. URL e voce di menu restano identiche;
4. non servono redirect aggiuntivi.

## Navigazione

Il Node `posturacorretta` possiede o eredita la configurazione del menu. Le
due voci saranno basate sui Node:

```yaml
posturacorretta: Home
percorso-posturacorretta: Percorso
```

Il menu non dovrebbe contenere direttamente un path hardcoded. Lo slug viene
risolto nel Node appartenente allo stesso Creator e poi trasformato nell'URL
pubblico del dominio.

Questo mantiene il menu valido anche quando la pagina smette di usare il
renderer legacy.

## URL pubblici basati sugli slug

La root del Brand usa `/`. I discendenti usano lo slug:

```text
posturacorretta.org/
posturacorretta.org/percorso-posturacorretta
posturacorretta.org/apprendimento-1-espressione
posturacorretta.org/igiene-posturale
```

La ricerca di `/:slug` deve essere limitata all'albero del Node associato al
Domain corrente. Non deve usare un semplice `Node.find_by(slug:)` globale.

Algoritmo:

```text
Domain corrente
-> Domain.node (confine del sito)
-> discendenti pubblici e accessibili
-> ricerca dello slug
-> risoluzione di eventuale Node ponte
-> Node Show oppure renderer legacy ammesso
```

### Unicità degli slug

Oggi `nodes.slug` non possiede un indice univoco. Prima di rendere `/:slug`
canonico bisogna garantire che lo slug sia univoco almeno dentro il Brand.

Regola consigliata:

```text
unicità di slug nell'albero del Domain/Brand
```

Un vincolo applicativo deve impedire due pagine pubbliche con lo stesso slug
nello stesso sito. Se in futuro servissero slug ripetuti, potremo introdurre
URL gerarchici, ma non è necessario per la prima migrazione.

## Compatibilità con le route esistenti

PosturaCorretta possiede molte route specifiche (`/posturacorretta/lezioni`,
`/posturacorretta/metodiche`, accademia, professionisti e altre funzioni).
Queste route devono continuare ad avere precedenza sul resolver generico degli
slug.

Il resolver `/:slug` va quindi collocato dopo le route applicative esplicite e
deve accettare soltanto slug nel formato previsto.

Non vanno trasformate immediatamente in Node le pagine operative che gestiscono:

- autenticazione;
- iscrizioni;
- avanzamento dei corsi;
- dashboard studente o insegnante;
- form e operazioni POST/PATCH/DELETE.

Il Node può diventare il punto di ingresso editoriale, mentre le azioni
operative restano controller Rails dedicati.

## SEO e continuità degli indirizzi

Per ogni Node pubblico dovremo generare:

- URL canonico sul dominio del Brand;
- title e description dal Node/Domain;
- Open Graph e immagine sociale;
- breadcrumb con URL a slug;
- sitemap del dominio;
- eventuale `noindex` secondo stato e visibilità.

Gli URL `/nodes/:id` resteranno temporaneamente funzionanti, ma quando esiste
un URL di dominio dovranno fare redirect `301` verso quello canonico.

Gli indirizzi storici non devono essere eliminati. Verranno mappati verso il
Node equivalente con redirect `301` soltanto dopo aver verificato contenuto e
metadati.

## Piano di implementazione

### Fase 1 — Infrastruttura senza cambi visibili ✅ completata

- aggiungere `home_mode` al Domain e allo YAML;
- mantenere `auto` come default;
- centralizzare la scelta della home in un resolver testato;
- aggiungere test per `auto`, `node`, `site` e `target`;
- non modificare ancora PosturaCorretta.

Risultato: nessun dominio cambia comportamento.

Implementato:

- `Domain#home_mode` salvato nelle impostazioni JSON e importabile/esportabile
  dallo YAML;
- default compatibile `auto`;
- validazione dei valori ammessi;
- `DomainHomeResolver` come unico punto di decisione;
- gestione sicura delle configurazioni esplicite incomplete;
- test di modello, servizio e controller per tutte le modalità.

### Fase 2 — URL Node sul dominio

- aggiungere il resolver pubblico `/:slug` limitato all'albero del Domain;
- generare link a slug nel menu e nei breadcrumb;
- introdurre la validazione di unicità dello slug nel Brand;
- mantenere le route esplicite con priorità maggiore;
- aggiungere test contro accessi a Node di altri domini.

Risultato: le pagine Node possono convivere con il sito attuale.

### Fase 3 — Conservazione della home attuale

- creare il Node `percorso-posturacorretta`;
- pubblicarlo sotto `posturacorretta`;
- associare temporaneamente il renderer legacy controllato;
- esporlo a `/percorso-posturacorretta`;
- configurare la navigazione del Node principale con `Home` e `Percorso`;
- verificare corsi, login, dashboard e link interni.

Risultato: la home attuale è ancora disponibile come pagina del menu.

### Fase 4 — Attivazione di Node Show come home ✅ root attivata

- rimuovere la route host-specifica `GET /` di PosturaCorretta;
- impostare `home_mode: node`;
- verificare che `Domain.node` sia `posturacorretta`;
- mantenere temporaneamente `site_key` e `target_*` per rollback;
- controllare SEO, menu, responsive e autenticazione;
- verificare che `/percorso-posturacorretta` mostri la pagina precedente.

Risultato:

```text
/                             -> Node Show di posturacorretta
/percorso-posturacorretta     -> home/percorso precedente
```

Attivato inizialmente:

- rimossa la route speciale del dominio che forzava la vecchia home su `/`;
- impostato `home_mode: node` per `posturacorretta.org`;
- mantenuta la pagina precedente su `/percorso-posturacorretta`;
- menu a slug rinviato alla Fase 2, perché deve generare URL di dominio e non
  i vecchi `/nodes/:id`.

Convenzione locale:

```text
http://localhost:3000/posturacorretta
  -> Node Show del Node collegato a posturacorretta.org

http://localhost:3000/percorso-posturacorretta
  -> precedente home/percorso educativo
```

Il percorso locale del Brand usa un'azione pubblica dedicata: conserva il
contesto del Domain e renderizza `nodes/show` senza simulare l'host reale e
senza reindirizzare fuori da localhost.

### Fase 5 — Migrazione progressiva dei contenuti

- trasferire nel Node le sezioni della pagina precedente che devono restare;
- trasformare i contenuti editoriali in NodeContent Lexxy;
- mantenere controller dedicati per funzionalità operative;
- eliminare `site_key` e `target_*` solo quando non servono più;
- rimuovere il renderer legacy quando la sua pagina è interamente Node-driven;
- aggiungere redirect `301` dagli URL storici.

## Strategia di rollback

Finché il vecchio renderer rimane disponibile, un rollback richiede soltanto:

```yaml
home_mode: auto
```

oppure:

```yaml
home_mode: site
```

Non vengono cancellati:

- template esistenti;
- YAML editoriali;
- controller dei corsi;
- dati del Node;
- configurazione del dominio.

## Decisioni confermate

1. Il Domain userà `home_mode` con i valori `auto`, `node`, `site` e `target`.
2. L'attuale home verrà conservata all'indirizzo
   `/percorso-posturacorretta`.
3. Il menu mostrerà `Home` per la nuova home Node e `Percorso` per la pagina
   attuale spostata.
4. Il Node principale `posturacorretta` sarà la nuova home del dominio.
5. La prima versione della nuova home corrisponderà esattamente al `Node Show`
   attuale, senza una variante speciale e senza nuove sezioni radiali.

## Raccomandazione

Procedere con le Fasi 1 e 2 prima di cambiare `/`. Consentono di verificare
resolver, URL, navigazione e sicurezza mentre il sito attuale continua a essere
la home. Soltanto dopo aver reso raggiungibile e verificato
`/percorso-posturacorretta` conviene attivare `home_mode: node`.

