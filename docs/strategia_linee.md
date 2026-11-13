# Strategia per landing, linee e offerte

## Stato del documento

Bozza di architettura del **12 novembre 2026** da verificare un punto alla volta prima di introdurre nuove tabelle o migrazioni definitive.

### Decisione MVP implementata

La prima implementazione usa un modello ibrido, compatibile con il catalogo YAML dei Node:

```text
Node
├─ lane_container  → contenitore/sezione già esistente
├─ line_slugs[]    → linee alle quali appartiene
└─ offer_slugs[]   → offerte nelle quali è compreso

MetroLine
└─ identità, dominio, Node iniziale e Node finale

Offer
└─ linea, Node iniziale/finale, offerte incluse e regola sul precedente acquisto
```

I due array sono gli unici nuovi campi introdotti sul Node. Linee e offerte vengono definite rispettivamente in `config/metro_lines.yml` e `config/offers.yml`, validate insieme a `config/nodes.yml` e importate con `bin/rails nodes:import`.

L'ordine della prima linea continuerà inizialmente a essere ricavato dalla struttura e dai collegamenti dei Node. Se una futura linea risultasse ambigua, verrà introdotta una relazione esplicita senza modificare i due campi di appartenenza.

Per la linea `postura-recupero` è stata adottata una catena seriale unica: corsi e lezioni si alternano lungo i `parent` e i ponti già esistenti. Gli otto Node tecnici `programma-*` dell'Area Massaggio sono stati rimossi; la distinzione fra corso, lezione e valutazione continua a dipendere da `view_type`. `MetroLine#ordered_nodes` verifica che dalla stazione iniziale a quella finale esista un solo percorso completo, senza cicli, interruzioni o diramazioni ambigue.

La mappa amministrativa salva inoltre per ogni coppia mappa/Node lo stato `collapsed`. In modalità Modifica, `+ / −` mostra o nasconde l'intera prosecuzione del Node, inclusi i ponti coinvolti. Lo spostamento di un Node trascina tutte le stazioni successive mantenendone le distanze relative; la vista normale rispetta la configurazione standard salvata dal superadmin.

`Altre metodiche posturali` incorpora ora anche la funzione di sintesi conclusiva: il precedente Node separato `altre-metodiche-posturali-sintesi-percorso` è stato rimosso ed `Altre metodiche posturali` è la stazione finale della linea. I binari che condividono una stazione usano porte sfalsate per aprirsi su corsie parallele e non sovrapporsi sullo stesso tratto iniziale o finale.

Il routing definitivo della mappa valuta l'intera rete e non più un collegamento isolato alla volta. Ogni arco può usare più curve; il calcolo penalizza sovrapposizioni, incroci, binari paralleli troppo vicini e passaggi accanto a stazioni estranee. Durante il trascinamento viene usato temporaneamente un percorso rapido per mantenere l'interazione fluida; al rilascio viene ricalcolato il routing completo.

Il primo prototipo sarà costruito con la home di PosturaCorretta e con una sola linea funzionante. La strategia deve però restare riutilizzabile dagli altri domini.

### Flusso visuale Superadmin

Dalla mappa metropolitana del dominio il superadmin può creare una linea selezionando le stazioni
nell'ordine, quindi creare un'offerta scegliendo linea, stazione iniziale/finale, offerte incluse e
regola `none`, `credit` o `discount`. Al termine scarica `metro_maps.yml`, `metro_lines.yml`,
`offers.yml` e `nodes.yml`.

Coordinate e stato `+ / −` appartengono a `MetroMapPlacement` e sono catalogati in
`metro_maps.yml` per hostname: lo stesso Node può quindi avere posizioni diverse nelle mappe dei
diversi domini. Linee, offerte e appartenenze `line_slugs`/`offer_slugs` dei Node restano globali.
In development, la creazione visuale aggiorna anche le voci Node interessate in `config/nodes.yml`.

## Obiettivo

Una landing deve poter:

1. essere divisa in sezioni editoriali;
2. presentare Node, linee e offerte senza duplicarli;
3. mostrare una linea come sequenza ordinata di stazioni;
4. proporre ingressi progressivi nella stessa linea;
5. riconoscere automaticamente le parti già acquistate o completate;
6. permettere in futuro a centri e professionisti di pubblicare offerte concrete della stessa linea.

La home non coincide con la linea e la linea non coincide con l'offerta.

```text
Landing
└─ Sezioni di presentazione
   ├─ Node o contenuti editoriali
   ├─ Linee suggerite
   └─ Offerte di ingresso

Linea
└─ Stazioni ordinate che fanno riferimento ai Node

Pacchetto o tratto
└─ Parte riutilizzabile della linea

Offerta
└─ Ciò che una persona può scegliere, prenotare o acquistare
```

## 1. Vocabolario definitivo

### Node

Il Node mantiene l'identità stabile di un concetto, corso, lezione, valutazione, progetto o contenitore.

Il Node non deve contenere da solo tutta la logica commerciale e non deve essere duplicato quando compare:

- in più sezioni della landing;
- in più linee;
- in offerte differenti;
- più volte nella storia di una persona.

### Landing

La landing è la pagina di ingresso di un dominio o di un Node. Organizza la presentazione, ma non definisce da sola la gerarchia dei Node.

### Sezione della landing

Una sezione è un blocco editoriale ordinato della landing. Può contenere:

- titolo, testo, immagine e CTA;
- uno o più Node;
- una linea;
- una o più offerte;
- un contenuto `coming soon`.

Una sezione non deve essere obbligatoriamente un Node. Può però avere un `node_slug` quando deve possedere identità pubblica, contenuti propri o collegamenti nella rete.

### Linea

Una linea è una dima ordinata e versionabile di un percorso. Appartiene a un dominio proprietario e contiene occorrenze di stazioni.

La linea non è un semplice booleano sul Node perché:

- lo stesso Node può apparire in linee diverse;
- una linea possiede nome, slug, versione e stato;
- l'ordine delle stazioni dipende dalla linea, non dalla gerarchia editoriale;
- una stazione può essere un ingresso, un'uscita o un interscambio;
- il percorso personale deve continuare a riferirsi alla versione iniziata.

### Stazione

Una stazione è la presenza di un Node all'interno di una linea. È quindi una relazione ordinata, non una nuova copia del Node.

Una stazione deve poter dichiarare:

- `node_slug`;
- posizione nella linea;
- tipo visivo: normale, ingresso, uscita, interscambio o stazione tronca;
- eventuale etichetta specifica della linea;
- disponibilità attuale;
- appartenenza a uno o più tratti.

### Tratto o pacchetto

Un tratto raggruppa stazioni consecutive o esplicitamente elencate. Serve a descrivere una parte riutilizzabile della linea.

Il tratto non contiene prezzo, calendario o insegnante. Può essere incluso in più offerte.

### Offerta

L'offerta è la proposta che una persona può scegliere. Nella prima fase può essere soltanto una CTA editoriale; in seguito conterrà:

- tratto o stazioni comprese;
- offerte precedenti incluse;
- prezzo e regole di accesso;
- centro e insegnante;
- modalità in presenza, online o ibrida;
- calendario, disponibilità e posti;
- eventuale versione della linea.

### Viaggio personale

Il viaggio è l'istanza appartenente alla persona. Registra ciò che è stato aperto, acquistato, programmato e completato senza modificare la linea originale.

## 2. Offerte progressive e cumulative

La prima regola commerciale è:

> Scegliendo un'offerta successiva, la persona riceve anche i diritti previsti dalle offerte precedenti, ma non deve ripetere ciò che ha già completato.

Occorre distinguere tre concetti:

- `includes`: ciò che l'offerta comprende realmente;
- `requires`: ciò che deve essere completato prima, se esiste un prerequisito;
- `recommended_after`: la prosecuzione suggerita, senza obbligo.

Non bisogna dedurre automaticamente l'inclusione soltanto dalla posizione grafica. Deve essere dichiarata esplicitamente per evitare errori quando la linea si ramifica.

Esempio:

```text
Offerta A · Inizia con PosturaCorretta
└─ tratto: avvio

Offerta B · Igiene Posturale
├─ includes: Offerta A
└─ tratto: igiene-posturale

Offerta C · Area Massaggio e recupero
├─ includes: Offerta A
├─ includes: Offerta B
└─ tratto: recupero-completo
```

Se la persona ha già completato A e acquista B:

- A rimane completata;
- B abilita anche A, ma non crea una seconda copia del viaggio;
- la linea evidenzia la prima parte come già percorsa;
- il nuovo lavoro parte dalla prima stazione non completata di B.

## 3. Perché `lane_container` non basta

`lane_container` resta temporaneamente utile per la vista a corsie, ma non deve diventare la classificazione universale del Node.

Un Node può contemporaneamente essere:

- contenitore editoriale;
- stazione di una linea;
- corso;
- lezione;
- valutazione;
- ingresso di un'offerta;
- interscambio verso un'altra linea;
- radice o sezione di una landing.

Un singolo enum o booleano renderebbe questi ruoli mutuamente esclusivi quando non lo sono.

### Direzione proposta

Nel prototipo i ruoli vengono ricavati dalle configurazioni che usano il Node:

- `lane_container` continua a governare la vista a corsie esistente;
- `view_type` continua a descrivere la resa principale del Node;
- la configurazione della landing stabilisce dove il Node viene presentato;
- la configurazione della linea stabilisce se e come il Node diventa stazione;
- la configurazione dell'offerta stabilisce quali tratti vengono abilitati.

Solo dopo il prototipo si valuterà una relazione multipla `NodeRole`, evitando di aggiungere ora un altro enum rigido.

## 4. Primo prototipo: PosturaCorretta

### Landing da provare

La home `/posturacorretta` diventa il primo esempio della separazione fra sezioni, linee e offerte.

Ordine iniziale delle sezioni:

1. presentazione e CTA principale;
2. prima linea: scopri come funziona e come riattivare il corpo;
3. offerte progressive della prima linea;
4. Postura e fisiologia come proposta autonoma;
5. Voglio risolvere un problema / Percorso Integrato;
6. servizi e pacchetti;
7. Educazione 2 · Consapevolezza con le metodiche posturali;
8. Educazione 3 · Dalla PosturaCorretta al Giardino del Corpo;
9. percorso per diventare insegnante.

La prima implementazione deve rendere realmente funzionanti soltanto la prima linea e le sue offerte. Le altre sezioni possono rimanere informative o `coming soon`.

### Prima linea funzionante

Nome tecnico provvisorio:

```text
postura-recupero
```

Sequenza iniziale proposta:

```text
La prima settimana con PosturaCorretta
→ Orientarsi nell'Area Massaggio e recupero
→ Valutazione della mobilità articolare
→ Igiene Posturale
→ Principi di Fisioterapia
→ Biomeccanica comportamentale GDS
→ Principi di Osteopatia
→ Corpo e Coscienza
→ Introduzione alla Kinesiologia Applicata
→ Altre metodiche posturali · Sintesi del percorso
```

La gerarchia dei Node può restare diversa. L'ordine sopra appartiene alla linea.

### Prime offerte da testare

#### A. Inizia con PosturaCorretta

Ingresso breve e autonomo. Abilita la Prima settimana con PosturaCorretta.

#### B. Igiene Posturale

Include A e prosegue attraverso:

- Orientarsi nell'Area Massaggio e recupero;
- Valutazione della mobilità articolare;
- corso e programma di Igiene Posturale.

#### C. Percorso Area Massaggio e recupero

Include A e B e prosegue lungo le stazioni restanti fino alla sintesi conclusiva.

Titoli commerciali, durata e prezzi restano da confermare. I codici A, B e C sono soltanto identificatori di progettazione.

### Postura e fisiologia

`Postura e fisiologia` resta un'offerta e una linea autonoma. Può essere suggerita dopo la Prima settimana, ma non deve essere incorporata automaticamente nell'offerta C.

## 5. Configurazione iniziale consigliata

Per il prototipo non serve ancora una migrazione complessa. Si può usare un file dedicato, separato da `config/nodes.yml`, per esempio:

```text
config/data/brands/posturacorretta/lines/postura_recupero.yml
```

Schema indicativo:

```yaml
line:
  key: postura-recupero
  title: Scopri come funziona e come riattivare il corpo
  domain: posturacorretta.org
  status: published
  version: 1

  stations:
    - key: avvio
      node_slug: la-prima-settimana-con-posturacorretta
      position: 1
      roles: [entry]
    - key: orientamento-area
      node_slug: area-massaggio-orientarsi
      position: 2
    - key: valutazione-mobilita
      node_slug: valutazione-mobilita-articolare
      position: 3
    - key: igiene-posturale
      node_slug: igiene-posturale
      position: 4

  segments:
    - key: avvio
      station_keys: [avvio]
    - key: igiene-posturale
      station_keys: [orientamento-area, valutazione-mobilita, igiene-posturale]
    - key: recupero-completo
      from_station: principi-fisioterapia
      through_station: sintesi

  offers:
    - key: inizia-con-posturacorretta
      segment_keys: [avvio]
    - key: pacchetto-igiene-posturale
      includes: [inizia-con-posturacorretta]
      segment_keys: [igiene-posturale]
    - key: percorso-area-massaggio-recupero
      includes: [inizia-con-posturacorretta, pacchetto-igiene-posturale]
      segment_keys: [recupero-completo]
```

La landing può avere una seconda configurazione che ordina le sezioni e riferisce `line_key` e `offer_key`, senza copiare le stazioni.

## 6. Evoluzione verso il database

Dopo il prototipo YAML e la verifica della home, il modello potrà diventare:

```text
MetroLine
├─ domain_id
├─ key, title, status, version
└─ MetroLineStation[]
   ├─ node_id
   ├─ position
   ├─ label_override
   └─ roles

LineSegment
└─ LineSegmentStation[]

OfferTemplate
├─ line_id
├─ included_offer_templates[]
└─ included_segments[]

LandingPage
└─ LandingSection[]
   └─ LandingSectionItem[]

Journey
├─ person/profile
├─ line_version
├─ selected_offer
└─ JourneyStationState[]
```

L'offerta concreta di un centro o professionista verrà separata da `OfferTemplate` e potrà collegarsi in seguito a Data Commitment, Data Session, Data Slot ed eventi.

## 7. Fasi di implementazione

### Fase 1 — Catalogo YAML e validazione

- creare la configurazione della prima linea;
- riferire soltanto Node esistenti;
- validare unicità delle chiavi, ordine e riferimenti;
- definire tre offerte cumulative;
- non introdurre ancora acquisti o pagamenti.

### Fase 2 — Home PosturaCorretta

- renderizzare le sezioni da una configurazione ordinata;
- mostrare la prima linea una sola volta;
- mostrare sotto la linea le tre possibilità di ingresso;
- far puntare ogni CTA alla prima stazione utile;
- mantenere le altre sezioni informative.

### Fase 3 — Prima linea realmente percorribile

- riusare `/posturacorretta/percorsi/postura-recupero`;
- leggere stazioni e ordine dal catalogo della linea;
- mantenere `tappa` e `tab` nell'URL;
- distinguere disponibile, selezionata, completata e futura;
- evitare di ricostruire l'ordine dalla gerarchia dei Node.

### Fase 4 — Offerte e riconoscimento del pregresso

- introdurre l'abilitazione dei tratti;
- riconoscere stazioni già completate;
- aprire la prima stazione non completata;
- distinguere acquisto, disponibilità e completamento;
- collegare successivamente centri, insegnanti e calendari.

### Fase 5 — Persistenza e linee personalizzate

- migrare le dime confermate nel database;
- versionare le linee pubblicate;
- creare i viaggi personali;
- consentire protocolli professionali e linee personalizzate;
- usare Data Commitment, Data Session e Data Slot senza creare Node artificiali per ogni tappa personale.

## 8. Regole da non violare

1. Un Node non viene duplicato per comparire in una nuova linea o offerta.
2. L'ordine della linea non modifica automaticamente la gerarchia dei Node.
3. Una sezione della landing non deve essere obbligatoriamente un Node.
4. Un'offerta non è una stazione e non è una linea.
5. Le offerte cumulative dichiarano esplicitamente ciò che includono.
6. Un completamento precedente non viene cancellato né duplicato.
7. Prezzo, centro, insegnante e calendario non appartengono al Node.
8. Le linee pubblicate devono essere versionate prima di essere usate da viaggi reali.
9. `lane_container` resta compatibile con le corsie, ma non governa offerte e linee.
10. Il prototipo deve essere verificato sulla home PosturaCorretta prima di generalizzarlo.

## 9. Decisioni da confermare, una alla volta

1. Confermare la separazione fra sezione, linea, tratto e offerta.
2. Confermare la sequenza della prima linea, inclusa la nuova valutazione della mobilità articolare.
3. Confermare quali stazioni precise appartengono alle offerte A, B e C.
4. Confermare il titolo pubblico delle tre offerte.
5. Confermare se la valutazione è compresa in B oppure resta una prestazione prenotabile separatamente ma necessaria al percorso.
6. Confermare la prima struttura delle sezioni della home.
7. Solo dopo, creare il catalogo YAML eseguibile e collegarlo alla pagina.

