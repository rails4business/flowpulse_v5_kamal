# Node Show come landing e articolo — progetto PosturaCorretta

## Obiettivo

Trasformare `Node#show` in una pagina pubblica componibile, capace di funzionare
con lo stesso impianto come:

- home/landing di un Brand con dominio;
- pagina di presentazione di un progetto, corso o metodica;
- articolo editoriale;
- punto di accesso alla rete dei Node collegati.

Il primo caso pilota è il Node `posturacorretta`.

## Riferimenti canonici

### Rete da integrare

L’indirizzo corretto della rappresentazione iniziale è:

```text
/flowpulse/rete/globale/centralita/only/posturacorretta?livelli=1&vista=brand
```

URL locale completo:

```text
http://localhost:3000/flowpulse/rete/globale/centralita/only/posturacorretta?livelli=1&vista=brand
```

Configurazione iniziale:

- Node centrale: `posturacorretta`;
- modalità: `only`;
- livelli: `1`;
- vista: `brand`.

### Prototipo editoriale

Il riferimento visivo e contenutistico iniziale è:

```text
public/posturacorretta_landing_page_perfetta.html
```

Il prototipo non deve diventare una seconda pagina indipendente. Le parti utili
devono essere estratte e trasformate in partial/componenti riutilizzabili nel
nuovo `Node#show`.

## Principio architetturale

Non devono esistere due sistemi separati, uno per le landing e uno per gli
articoli. Deve esistere un solo layout pubblico per i Node, composto da sezioni
opzionali.

```text
Node pubblico
├─ configurazione della presentazione
├─ contenuto editoriale
├─ sezioni/componenti opzionali
├─ rete contestuale opzionale
└─ navigazione tra Node
```

La differenza fra landing e articolo deriva dalla configurazione e dalle sezioni
attive, non da una seconda view monolitica.

## Struttura proposta del layout

### 1. Header e navigazione del dominio

- identità del Brand/dominio;
- navigazione principale configurabile;
- accesso/autenticazione;
- comportamento mobile con menu compatto;
- nessuna duplicazione con la navigazione interna del contenuto.

Il layout espone un solo nav principale. La sua configurazione appartiene a un
Node e viene ereditata dai discendenti fino al primo override.

Le modalità disponibili nell’Edit del Node sono:

- `Eredita dal parent`: configurazione `null`, risale al primo antenato che ne
  possiede una;
- `Personalizza`: salva un elenco ordinato di voci;
- `Nessun nav`: salva esplicitamente un elenco vuoto e interrompe
  l’ereditarietà.

L’input editoriale usa un hash YAML semplificato:

```yaml
posturacorretta: Home
metodiche-posturali:
  label: Metodiche
  children:
    gds: GDS
    osteopatia: Osteopatia
```

Lo slug identifica il Node; il valore o `label` determina il testo visibile. Il
sistema normalizza l’hash in un array JSON ordinato, valida gli slug nello stesso
mondo del creatore e rende `children` come dropdown.

Il layout contiene un solo elemento `nav`. Il `Node Show` prepara le voci con
`content_for :public_node_navigation`; il nav condiviso le riceve mediante
`yield`. La stessa struttura DOM si adatta a desktop e mobile, senza duplicare
il menu. Breadcrumb e navigazione padre/figli restano strumenti editoriali
distinti e non generano un secondo menu principale.

### 2. Hero

Sezione adatta soprattutto a landing e pagine di presentazione:

- titolo;
- sottotitolo/descrizione;
- immagine o visual principale;
- CTA primaria e secondaria;
- eventuale identità grafica del dominio.

Per un articolo può ridursi a titolo, sommario, autore, data e immagine di
copertina.

### 3. Rete contestuale

La rete viene collocata subito dopo l’hero nel primo prototipo PosturaCorretta.
Deve usare lo stesso motore della pagina Centralità, non un iframe e non una
copia dell’algoritmo.

Configurazione minima prevista per la sezione:

```yaml
network:
  enabled: true
  center_node_slug: posturacorretta
  mode: only
  depth: 1
  view: brand
```

La rete incorporata deve poter avere una UX più compatta della pagina completa,
con un collegamento esplicito per aprire la mappa a schermo intero.

### 4. Introduzione editoriale

- descrizione estesa del Node;
- contenuto Markdown o HTML sanitizzato;
- eventuale indice interno per testi lunghi.

Questa è la sezione principale nella variante articolo.

### 5. Blocchi modulari della landing

Dal prototipo PosturaCorretta vanno estratti gradualmente:

- presentazione del percorso;
- stazioni/fasi del percorso;
- modalità online, lezioni, tirocinio e insegnanti;
- eventi e date;
- CTA contestuali;
- sequenza «scopri, pratichi, insegni»;
- footer e collegamenti di servizio.

Ogni blocco deve poter essere attivato, ordinato e riutilizzato senza copiare
l’intera pagina HTML.

### 6. Contenuti collegati

La stessa pagina deve poter mostrare, quando pertinenti:

- figli del Node;
- articoli collegati;
- corsi e programmi;
- eventi;
- metodiche;
- collegamenti Node Link;
- contenuti correlati dello stesso dominio.

### 7. Navigazione di lettura

La navigazione attuale tra padre, figli e fratelli deve rimanere disponibile per
articoli e percorsi seriali, ma può essere disattivata o resa più discreta nelle
landing.

## Varianti di presentazione

### Landing

- hero esteso;
- rete contestuale;
- più sezioni modulari;
- CTA evidenti;
- contenuti collegati;
- navigazione di lettura secondaria o assente.

### Articolo

- hero editoriale compatto;
- corpo del contenuto centrale;
- indice opzionale;
- rete contestuale compatta o assente;
- correlati e navigazione di lettura.

### Pagina di presentazione

È la variante intermedia per corso, metodica o progetto:

- hero medio;
- descrizione e contenuto;
- rete contestuale;
- figli/programma;
- CTA specifiche.

## Dati da definire

La configurazione non deve essere codificata esclusivamente nella view. Va
stabilito quali campi appartengono a `NodeContent#data` e quali richiedono un
modello strutturato.

Prima ipotesi, da validare:

```yaml
presentation:
  template: landing
  hero:
    enabled: true
    image_url:
    primary_cta:
    secondary_cta:
  network:
    enabled: true
    mode: only
    depth: 1
    view: brand
  sections:
    - type: editorial
    - type: journey
    - type: related_nodes
```

Valori ammessi inizialmente per `template`:

- `landing`;
- `article`;
- `presentation`.

## Regola del dominio

Comportamento obiettivo:

1. se il dominio ha una landing pubblica esplicitamente collegata, apre quel
   Node con la sua configurazione di presentazione;
2. se il dominio è pubblicato ma non possiede una landing dedicata, apre il
   `Node#show` del Node proprietario;
3. un Node ponte non genera una pagina pubblica autonoma ma risolve verso il
   proprio obiettivo;
4. URL canonico, metadata e redirect devono evitare contenuti duplicati.

## Requisiti tecnici

- un solo renderer della rete condiviso fra Centralità e Node Show;
- nessun iframe;
- nessuna duplicazione dei dati del grafo;
- parametri della rete validati server-side;
- supporto responsive e accessibile;
- progressive enhancement: il contenuto essenziale resta fruibile senza JS;
- metadata SEO derivati dal Node e dalla sua configurazione;
- compatibilità con i Node che possiedono solo contenuto editoriale;
- partial piccole, con responsabilità definite;
- test per landing, articolo, dominio e ponte.

## Fasi di implementazione

### Workflow catalogo prima del deploy

L’editing strutturale dei Node è disponibile soltanto in development/test e può
essere disattivato con:

```text
NODE_CATALOG_EDITOR_ENABLED=false
```

In produzione rimane sempre disabilitato. Il flusso previsto è:

```text
modifica locale → anteprima nella rete → Aggiorna YAML → git diff → deploy → import YAML
```

La Centralità espone soltanto al superadmin le azioni per modificare il Node,
aggiungere un figlio e aggiungere un Node link. L’editor conserva nell’URL la
mappa di provenienza e vi ritorna dopo il salvataggio. La route breve
`/nodes/:id/edit` richiede il superadmin e inoltra all’unico editor Creator.

### Fase 1 — Estrarre la rete riutilizzabile

- separare preparazione dati, markup e controller della rete dalla pagina
  Centralità;
- creare una modalità `embedded`;
- renderizzare il caso canonico PosturaCorretta con `only`, livello `1` e vista
  `brand`;
- mantenere il collegamento alla mappa completa.

### Fase 2 — Comporre il nuovo Node Show

- dividere la view attuale in partial;
- introdurre le tre varianti di presentazione;
- collocare hero, rete e contenuto editoriale;
- preservare sidebar e navigazione di lettura quando necessarie.

### Fase 3 — Migrare la landing PosturaCorretta

- censire le sezioni del prototipo HTML;
- trasformarle in partial/configurazioni;
- trasferire testi, CTA e dati senza duplicarli;
- usare `posturacorretta` come prima landing basata su Node Show.

### Fase 4 — Nav, dominio e SEO

- progettare il nav condiviso desktop/mobile;
- applicare la regola di ingresso del dominio;
- impostare canonical URL, title, description e dati strutturati;
- creare redirect dalle pagine sostituite;
- verificare accessibilità, responsive e indicizzazione.

## Prima decisione operativa

Partire dalla **Fase 1**, estraendo la rete Centralità in un componente
riutilizzabile e introducendo la variante incorporata per PosturaCorretta.

Il nav non viene ancora modificato: sarà progettato quando hero, rete e sezioni
avranno una gerarchia stabile.

## Decisioni confermate

- [x] URL canonico di riferimento della rete corretto.
- [x] Node centrale `posturacorretta`.
- [x] Modalità iniziale `only`.
- [x] Un solo livello iniziale.
- [x] Vista `brand`.
- [x] Rete subito dopo l’hero nel primo prototipo.
- [x] Un solo Node Show componibile per landing, presentazione e articolo.
- [x] Il prototipo HTML è una sorgente da migrare, non una seconda architettura.
- [x] Prima iterazione del nav condiviso applicata al `Node#show`: identità del
      Brand, menu desktop/mobile e breadcrumb editoriale separato.
- [x] Configurazione del nav salvata sul Node e ereditata dai discendenti.
- [x] Form strutturale e route breve riservati al superadmin.
- [x] Supporto a link, dropdown, override locale e disattivazione esplicita.

## Decisioni ancora aperte

- [ ] schema definitivo della configurazione `presentation`;
- [ ] altezza e controlli della rete incorporata;
- [ ] quali sezioni del prototipo migrare per prime;
- [ ] relazione fra sidebar editoriale e landing;
- [ ] contenuto definitivo del nav PosturaCorretta;
- [ ] URL pubblico canonico della landing PosturaCorretta;
- [ ] strategia di redirect e migrazione SEO.
