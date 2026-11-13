# Home PosturaCorretta organizzata per corsi

## Obiettivo

Trasformare `/posturacorretta` nel punto principale dal quale una persona sceglie un corso e consulta tutte le informazioni collegate, senza duplicare i contenuti già presenti nelle pagine dedicate.

La selezione viene conservata nell'URL:

```text
/posturacorretta?tappa=la-prima-settimana-con-posturacorretta&tab=online
```

## Navigazione principale

La linea metropolitana rappresenta il percorso didattico attraverso i Node. È contenuta nella linguetta attiva: ogni pallino seleziona un Node e aggiorna il contenuto della stessa linguetta.

- `Percorso online` mostra la disponibilità dei materiali registrati.
- `Programma lezioni` mostra la disponibilità degli incontri guidati.
- `Centri` e `Insegnanti` permettono di selezionare una risorsa e mostrano sulla linea in quali tappe il corso è disponibile; le altre stazioni diventano tratteggiate.
- In futuro `Tirocinio` riutilizzerà lo stesso componente con una sorgente dedicata e sarà visibile soltanto agli utenti abilitati.

Un Node della linea può essere contemporaneamente:

- un corso direttamente fruibile;
- un contenitore che introduce e organizza altri corsi;
- entrambe le cose.

Un Node contenitore non viene quindi escluso dalla linea quando possiede una propria esperienza didattica. Per esempio **Area Massaggio e recupero** può essere una tappa/corso introduttiva e, contemporaneamente, contenere i corsi successivi della propria area.

### Node contenitore con modulo introduttivo

Un Node contenitore presente nella linea non deve essere una tappa vuota. Può avere un **modulo introduttivo dell'area**, breve e distinto dai corsi completi contenuti.

Struttura confermata per **Area Massaggio e recupero**:

```text
Area Massaggio e recupero
├─ Lezione 1 · Orientarsi nell'area Massaggio e recupero
│  └─ capitoli/materiali introduttivi
├─ Igiene Posturale
├─ Principi di Fisioterapia
├─ Introduzione alla biomeccanica comportamentale (GDS)
├─ Principi di Osteopatia
├─ Introduzione al metodo Corpo e Coscienza
├─ Introduzione alla Kinesiologia Applicata
└─ Altre metodiche posturali
```

Comportamento:

- la linguetta Percorso online presenta il modulo introduttivo dell'area;
- la stessa vista permette poi di raggiungere i corsi contenuti;
- la linguetta Programma lezioni potrà mostrare l'incontro guidato introduttivo dell'area;
- ogni corso contenuto rimane un Node e una tappa autonoma;
- il modulo introduttivo non viene presentato come un corso completo separato, ma come ingresso didattico al Node contenitore.

Titolo confermato per il Node lezione/sezione introduttivo:

```text
Lezione 1 · Orientarsi nell'area Massaggio e recupero
```

La lezione serve a comprendere l'area e a scegliere consapevolmente uno dei corsi contenuti; non presenta una singola metodica come formazione completa.

Contenuto previsto, da sviluppare in seguito:

- orientare nella scelta delle metodiche e dei corsi dell'area;
- partire dalle pratiche più semplici e dagli esercizi già comunemente utilizzati, raccolti e ordinati nel corso di Igiene Posturale;
- distinguere il ruolo della Fisioterapia nei percorsi di recupero;
- introdurre progressivamente Osteopatia, GDS, Corpo e Coscienza, Kinesiologia Applicata e le altre metodiche;
- aiutare la persona a capire da quale proposta iniziare senza presentare la lezione come formazione professionale.

Per ora non vengono fissati i titoli dei capitoli né creati nuovi contenuti. La lezione può esistere come Node/sezione predisposta e verrà popolata in una fase successiva.

I corsi mantengono i titoli già utilizzati da `/percorso-posturacorretta`. Non viene applicata una denominazione artificiale comune. Sono corsi introduttivi rivolti agli utenti PosturaCorretta e non devono essere confusi con la formazione professionale completa della scuola o della metodica corrispondente.

Sottotitolo comune consigliato:

> Corso introduttivo per utenti: concetti fondamentali, approccio e campo di applicazione.

### Ordine didattico confermato dell'area

L'ordine non è alfabetico e deve essere conservato esplicitamente tramite `position`:

1. Igiene Posturale — pratiche semplici e ordinate;
2. Principi di Fisioterapia — recupero;
3. Introduzione alla biomeccanica comportamentale (GDS);
4. Principi di Osteopatia;
5. Introduzione al metodo Corpo e Coscienza;
6. Introduzione alla Kinesiologia Applicata;
7. Altre metodiche posturali.

La linea metropolitana e gli elenchi dei corsi contenuti devono rispettare lo stesso ordine.

**Introduzione alla Kinesiologia Applicata** viene promossa a corso/Node autonomo. Non rimane soltanto una sequenza interna ad Altre metodiche posturali.

### Node lezione dei corsi introduttivi

Per questa fase vengono creati esclusivamente i **Node lezione/sezione** sotto i rispettivi Node corso:

```text
Node corso
└─ Node Lezione 1 · Introduzione a…
```

Regole:

- inizialmente ogni corso introduttivo possiede un solo Node lezione;
- non vengono ancora creati, spostati o associati capitoli;
- titoli, ordine e contenuti dei capitoli verranno definiti in seguito, un corso alla volta;
- la presenza del Node lezione permette già di predisporre il Programma lezioni e il futuro collegamento alle lezioni programmate;
- il Node lezione potrà ricevere capitoli YAML/Markdown o contenuti tramite DataCommitment senza cambiare la gerarchia del corso.

### Orientamento e tracciato base

La presentazione e l'orientamento alle singole metodiche avvengono già in:

```text
Area Massaggio e recupero
└─ Lezione 1 · Orientarsi nell'area Massaggio e recupero
```

I corsi successivi formano il segmento base dell'**Area Massaggio e recupero**, cioè la sequenza più semplice per attraversare progressivamente quest'area. La linea metropolitana principale li mostra quindi in ordine lineare.

I futuri giri alternativi riguarderanno il **percorso completo**, non varianti interne a questa singola area. Potranno collegare e attraversare:

- le altre aree di Postura e fisiologia;
- Percorso Integrato;
- Stato di Salute;
- altri Node e domini dell'ecosistema.

Questi giri generali verranno progettati in una fase successiva e non modificano l'ordine interno confermato dell'Area Massaggio e recupero.

### Limite della fase attuale

Per ora il tracciato implementato si conclude con:

```text
Altre metodiche posturali
└─ Sintesi del percorso
```

Non viene ancora creato il collegamento successivo verso Area Movimento, le altre aree, Percorso Integrato o Stato di Salute. La struttura resta estendibile, ma tali collegamenti saranno decisi separatamente.

### Prima linea confermata

Ordine definitivo della prima linea:

1. La prima settimana con PosturaCorretta;
2. Area Massaggio e recupero;
3. Igiene Posturale;
4. Principi di Fisioterapia;
5. Biomeccanica comportamentale GDS;
6. Principi di Osteopatia;
7. Corpo e Coscienza;
8. Introduzione alla Kinesiologia Applicata;
9. Altre metodiche posturali.

La prima implementazione riallinea in quest'ordine la gerarchia dei Node, i Node lezione e la nuova home `/posturacorretta`. La pagina storica `/percorso-posturacorretta` verrà aggiornata soltanto dopo la verifica della nuova struttura e dovrà consumare le stesse sorgenti, senza introdurre un secondo ordinamento manuale.

## Audit tecnico prima dell'implementazione

Controllo effettuato su `config/nodes.yml` e `config/data/posturacorretta/programmi/programma_lezioni_posturacorretta.yml`.

### Struttura già presente

- tutti i Node corso della prima linea esistono già;
- Igiene Posturale possiede già quattro Node lezione concatenati in ordine seriale;
- Principi di Fisioterapia possiede già cinque Node lezione sui sistemi, più la voce da escludere `Scopri di più sulla metodica`;
- GDS possiede già i sei Node lezione confermati, più la voce da escludere;
- Osteopatia possiede già cinque Node lezione, ma richiede rinomina della prima e modifiche alle ultime lezioni;
- Corpo e Coscienza possiede già i sei Node lezione confermati, più la voce da escludere;
- le lezioni esistenti sono generalmente organizzate come catena seriale sotto un Node `Programma`, non come figli paralleli del corso;
- il prototipo Prima settimana possiede già `Lezione 1 · Inizia con PosturaCorretta` con `view_type: course_lesson`.

### Modifiche necessarie

- rinominare i Node corso che usano ancora `Primo incontro con…` con i titoli confermati;
- aggiungere il Node lezione `Orientarsi nell'area Massaggio e recupero`;
- aggiungere la lezione introduttiva di Fisioterapia;
- rinominare la prima lezione di Osteopatia;
- estendere la lezione sul sistema neurovegetativo includendo il nervo vago;
- aggiungere la lezione conclusiva PNEI;
- rendere autonomo il corso `Introduzione alla Kinesiologia Applicata` e creare/associare `Sequenza di Kinesiologia Applicata` come suo Node lezione;
- creare `Sintesi del percorso` come unico Node lezione di Altre metodiche posturali;
- escludere dal Programma lezioni tutti i Node `Scopri di più sulla metodica`;
- non creare Node lezione per Feldenkrais e Alexander in questa fase;
- assegnare ai Node lezione confermati un tipo coerente, senza duplicare quelli esistenti;
- aggiungere i riferimenti `course_key` e, quando disponibili, `academy_module_key` ai Node corso che devono popolare le linguette della home.

### Relazione da confermare

Attualmente **Area Massaggio e recupero** è figlia di `Educazione 1 · Capire come si esprime il corpo e come funziona la tua fisiologia`. La Prima settimana la raggiunge tramite un Node ponte `Accesso all'Area Massaggio dalla Prima settimana`; non è il suo parent gerarchico diretto.

La linea metropolitana può mostrare comunque Prima settimana → Area Massaggio senza cambiare la gerarchia, ma occorre decidere se mantenere il ponte oppure trasformare Area Massaggio in figlia diretta della Prima settimana.

Decisione confermata: la gerarchia attuale viene mantenuta. **Area Massaggio e recupero** resta figlia di Educazione 1 e la Prima settimana la raggiunge tramite il Node ponte esistente. La linea metropolitana può rappresentare il passaggio Prima settimana → Area Massaggio senza trasformarlo in una relazione parent/child.

### Struttura seriale dei programmi

Decisione confermata:

```text
Node corso
└─ Node Programma
   └─ Node Lezione 1
      └─ Node Lezione 2
         └─ Node Lezione 3
```

- il Node Programma viene mantenuto come contenitore;
- le lezioni restano collegate in catena seriale per rappresentarne l'ordine;
- i Node lezione confermati ricevono `view_type: course_lesson`;
- la home può mostrarli come elenco ordinato senza modificare la loro gerarchia nella rete.

### Node `Scopri di più sulla metodica`

I Node esistenti non vengono cancellati immediatamente. In questa fase:

- vengono scollegati dalla catena pubblica del Programma lezioni;
- non vengono mostrati nella nuova home;
- vengono impostati come non pubblicati, conservandoli temporaneamente come materiale recuperabile;
- l'eventuale eliminazione definitiva verrà valutata soltanto dopo la verifica della nuova struttura.

### Slug definitivi e aggiornamento atomico

Gli slug già coerenti vengono mantenuti:

- `principi-di-fisioterapia`;
- `biomeccanica-comportamentale-gds`;
- `principi-di-osteopatia`;
- `introduzione-al-metodo-corpo-e-coscienza`;
- `altre-metodiche-posturali`.

Lo slug della Kinesiologia Applicata viene corretto definitivamente:

```text
primo-incontro-kinesiologia-applicata
→ introduzione-alla-kinesiologia-applicata
```

La modifica deve essere atomica e comprendere:

- `config/nodes.yml`;
- tutti i file YAML che usano lo slug come chiave, parent, riferimento al corso o collegamento;
- i file Markdown che contengono link o riferimenti espliciti;
- la configurazione della linea metropolitana e i partial della home;
- Node ponte e link interni;
- test e fixture;
- canonical e metadati SEO pertinenti;
- redirect permanente dal vecchio slug al nuovo, quando applicabile.

Il documento corrente deve utilizzare soltanto il nuovo slug dopo la migrazione. Prima della modifica va eseguita una ricerca completa delle referenze, così da non lasciare collegamenti misti.

Le voci ripetute **Scopri di più sulla metodica** non vengono trasformate in Node lezione e non compaiono nel Programma lezioni. L'eventuale collegamento alla scheda professionale della metodica resta una risorsa o una CTA separata, non una lezione.

La regola si applica a Principi di Fisioterapia, GDS, Osteopatia, Corpo e Coscienza e agli altri corsi specifici dell'area.

### Lezioni confermate · Principi di Fisioterapia

```text
Principi di Fisioterapia
├─ Introduzione · Fisioterapia, riabilitazione e cinque sistemi fisiologici
├─ Sistema respiratorio
├─ Sistema nervoso e urogenitale
├─ Sistema muscolo-scheletrico
├─ Sistema cardiocircolatorio
└─ Sistema linfatico e digerente
```

Le sei voci diventano Node lezione nell'ordine indicato. La prima fornisce la cornice specifica della Fisioterapia e della riabilitazione prima di affrontare separatamente i cinque sistemi. **Scopri di più sulla metodica** viene esclusa. Capitoli, schede e materiali verranno associati successivamente.

### Lezioni confermate · Igiene Posturale

```text
Igiene Posturale
├─ Mobilità articolare
├─ Punti di tensione
├─ Vie di discesa
└─ Recettori sensoriali
```

Le quattro voci diventano Node lezione nell'ordine indicato. Non viene aggiunta una lezione introduttiva separata: l'orientamento generale è già svolto dalla lezione del Node **Area Massaggio e recupero**. Capitoli, schede e materiali verranno associati successivamente.

### Lezioni confermate · Biomeccanica comportamentale GDS

```text
Biomeccanica comportamentale GDS
├─ Le 5 direzioni di movimento
├─ Catena AM
├─ Catena AL
├─ Catena PM
├─ Catena PL
└─ Catene PA/AP
```

Le sei voci diventano Node lezione nell'ordine indicato. **Scopri di più sulla metodica** viene esclusa. Capitoli, schede e materiali verranno associati successivamente.

**Le 5 direzioni di movimento** è anche la lezione introduttiva del corso GDS. Non viene aggiunta un'ulteriore introduzione separata.

### Lezioni confermate · Principi di Osteopatia

```text
Principi di Osteopatia
├─ Osteopatia e disfunzioni: che cosa sono?
├─ Il sistema fasciale
├─ Il sistema viscerale
├─ Il sistema cranio-sacrale
├─ Il sistema neurovegetativo e il nervo vago
└─ Introduzione alla PNEI · Corpo, emozioni e sistemi di regolazione
```

La prima lezione presenta l'Osteopatia e sostituisce il precedente titolo assoluto **Eliminare le disfunzioni**. Il nervo vago viene trattato all'interno del sistema neurovegetativo, evitando un Node separato ridondante. La PNEI chiude il corso come cornice educativa sulle connessioni fra sistemi e crea un ponte verso mente e consapevolezza, senza formulare promesse cliniche automatiche.

**Scopri di più sulla metodica** viene esclusa. Capitoli, schede e materiali verranno associati successivamente.

### Lezioni confermate · Corpo e Coscienza

```text
Corpo e Coscienza
├─ Le 2 circolazioni
├─ I 3 centri di gravità
├─ I 4 tipi di movimento
├─ I 5 elementi
├─ Le 6 coppie di meridiani
└─ I 7 centri neurolinfatici
```

La progressione esistente viene mantenuta. **Le 2 circolazioni** funziona anche come ingresso al corso, quindi non viene aggiunta una presentazione generale separata. **Scopri di più sulla metodica** viene esclusa. Capitoli, schede e materiali verranno associati successivamente.

### Lezione confermata · Introduzione alla Kinesiologia Applicata

```text
Introduzione alla Kinesiologia Applicata
└─ Sequenza di Kinesiologia Applicata
```

Il contenuto esistente diventa l'unico Node lezione iniziale del corso. Altre lezioni potranno essere aggiunte in seguito senza modificare la struttura. Capitoli, schede e materiali verranno associati successivamente.

### Corso conclusivo · Altre metodiche posturali

**Altre metodiche posturali** è un corso conclusivo dell'area, non un semplice contenitore o catalogo.

Obiettivi confermati:

- spiegare che esistono molte altre metodiche oltre a quelle presentate nei corsi precedenti;
- chiarire l'importanza delle metodiche e il motivo per cui ciascuna possiede un proprio approccio e un proprio campo di esperienza;
- evitare di presentare una metodica come universalmente migliore delle altre;
- invitare la persona a conoscere, scegliere e praticare una disciplina adatta al proprio percorso;
- evidenziare che la continuità della pratica e l'esperienza vissuta possono fare più differenza della sola etichetta della metodica.

Il corso può utilizzare schede introduttive sulle metodiche come materiali di esplorazione, mantenendo distinta questa esperienza educativa dalla formazione professionale delle rispettive scuole.

Il corso possiede anche una voce nel **Programma lezioni**:

```text
Incontro conclusivo · Scegli come proseguire
```

Funzioni dell'incontro:

- concludere e rileggere il percorso svolto nell'area;
- confrontare le esperienze e le metodiche conosciute;
- aiutare la persona a individuare la pratica o la direzione più adatta per proseguire;
- collegare, quando utile, la persona a un corso, un insegnante, un centro o una pratica continuativa.

L'incontro conclusivo non stabilisce una metodica migliore in assoluto e non sostituisce una valutazione professionale quando necessaria.

Struttura Node confermata:

```text
Altre metodiche posturali
└─ Sintesi del percorso
```

**Sintesi del percorso** è l'unico Node lezione del corso conclusivo. Feldenkrais, Alexander e le altre metodiche possono essere presentate come schede, esempi o materiali di esplorazione, ma non diventano lezioni del Programma in questa fase. La Sequenza di Kinesiologia Applicata appartiene invece al corso autonomo **Introduzione alla Kinesiologia Applicata**.

Il Node/corso selezionato deve essere l'unica sorgente del contesto: programma, lezioni, centri e insegnanti devono riferirsi a quel corso.

## Struttura didattica confermata

La struttura di riferimento è:

```text
Node corso
└─ Node lezione, che funziona da sezione
   ├─ capitolo 1
   ├─ capitolo 2
   ├─ capitolo 3
   └─ capitoli successivi
```

Regole confermate:

- ogni tappa della metropolitana è un Node;
- un Node tappa può essere sia corso sia contenitore di corsi;
- il figlio del Node corso è un **Node lezione** che svolge anche la funzione di sezione didattica;
- i capitoli YAML e Markdown vengono associati al Node lezione e non diventano automaticamente altri Node;
- un corso potrà avere una o più lezioni/sezioni, ciascuna con i propri capitoli;
- per la Prima settimana viene creato un solo Node lezione/sezione al quale sono associati i sette capitoli esistenti;
- il Programma lezioni mostra il Node lezione come unità guidata con l'operatore;
- il Percorso online mostra i capitoli e i materiali associati allo stesso Node lezione;
- la futura lezione programmata farà riferimento al Node lezione, aggiungendo insegnante, data e modalità.

### Distinzione fondamentale

**Percorso online** e **Programma lezioni** non sono due rappresentazioni dello stesso elenco.

- Il Percorso online contiene materiali da consultare e svolgere autonomamente.
- Il Programma lezioni descrive gli incontri guidati che un operatore potrà programmare.
- Il Node lezione collega i due contesti: nel Percorso online organizza i capitoli; nel Programma lezioni rappresenta l'unità che l'operatore potrà condurre.
- I sette capitoli della Prima settimana non generano sette lezioni: appartengono a un'unica lezione/sezione.

## Prototipo iniziale

Il primo prototipo viene realizzato sul Node **La prima settimana con PosturaCorretta**.

Il suo primo Node lezione/sezione è confermato come:

```text
Titolo: Lezione 1 · Inizia con PosturaCorretta
Slug:   lezione-1-inizia-con-posturacorretta
```

Gerarchia del prototipo:

```text
La prima settimana con PosturaCorretta
└─ Lezione 1 · Inizia con PosturaCorretta
   └─ sette capitoli associati
```

I capitoli mantengono il proprio `parent_id` storico per non modificare la vecchia pagina e dichiarano inoltre il Node lezione tramite `lesson_node_slug`:

```yaml
parent_id: inizia-con-posturacorretta
lesson_node_slug: lezione-1-inizia-con-posturacorretta
```

Regole:

- il `parent_id` storico resta invariato;
- `lesson_node_slug` viene aggiunto a tutti i sette capitoli;
- la vecchia pagina continua a leggere la gerarchia corso → capitoli;
- la nuova home raggruppa i capitoli sotto il Node lezione;
- i Markdown non vengono copiati o spostati.

Per questa fase:

- si riutilizzano i file YAML e Markdown già presenti;
- non si introducono ancora nuovi DataCommitment;
- non si ristruttura ancora il sistema Eventi;
- YAML e Markdown vengono letti attraverso un adattatore unico, in modo da non legare la nuova interfaccia alla loro struttura interna;
- il Node selezionato rimane il punto di partenza per risolvere corso, sezioni e dati mostrati.
- non vengono ancora spostati o riorganizzati gli altri corsi attualmente raccolti sotto Postura e fisiologia;
- il riallineamento degli altri corsi verrà affrontato soltanto dopo la verifica del prototipo della Prima settimana.

In futuro contenuti, impegni e lezioni verranno formalizzati tramite DataCommitment ed Eventi a partire dal Node e dalle sue sezioni. Il prototipo deve quindi poter cambiare sorgente senza dover riscrivere la home.

### Backup della versione precedente

La pagina `/percorso-posturacorretta` e la precedente esperienza del Percorso online restano disponibili come backup durante la ricostruzione.

La nuova home non deve modificare o eliminare la versione precedente finché il nuovo flusso non è completo e verificato. Il backup può essere usato per confrontare contenuti, ordine e funzionalità mancanti, ma non deve diventare una seconda sorgente da mantenere manualmente.

### Sorgente autorevole del Percorso online

Per il prototipo della Prima settimana la sorgente autorevole è:

```text
config/data/brands/posturacorretta/courses/inizia-con-posturacorretta/course.yml
```

Il record con `format: course` descrive il corso. I sette record figli con `format: chapter`, ordinati tramite `position`, descrivono i capitoli associati all'unico Node lezione/sezione del prototipo. Ogni `content_path` indica il Markdown del relativo capitolo.

Gli altri cataloghi che ripetono il corso non sono sorgenti primarie della nuova home:

- `contenuti/contents.yml` rimane un catalogo storico o di compatibilità;
- `contenuti/percorso.yml` continua a descrivere l'ordine generale del percorso;
- i file dell'Accademia e dei programmi continuano a descrivere i rispettivi contesti finché non verranno riallineati.

### Collegamento esplicito Node → corso YAML

Il Node selezionato nella metropolitana deve dichiarare esplicitamente il corso YAML associato tramite `course_key`.

Esempio:

```yaml
la-prima-settimana-con-posturacorretta:
  course_key: inizia-con-posturacorretta
```

Regole:

- il collegamento non viene dedotto dal titolo;
- lo slug del Node e la chiave del corso possono essere differenti;
- l'adattatore parte dal Node, legge `course_key` e risolve corso, sezioni e Markdown;
- un Node senza `course_key` mostra uno stato non configurato senza tentare associazioni implicite;
- in futuro lo stesso riferimento potrà essere usato durante la migrazione verso il nuovo modello dati.

### Collegamento esplicito Node → modulo Accademia

Centri e Insegnanti sono già gestiti da `AcademyCurriculum` attraverso i `moduli` attivi. Poiché la chiave del corso online e quella del modulo Accademia possono essere differenti, il Node dichiara anche `academy_module_key`.

Esempio completo:

```yaml
la-prima-settimana-con-posturacorretta:
  course_key: inizia-con-posturacorretta
  academy_module_key: introduzione
```

Responsabilità:

- `course_key` risolve corso, sezioni e Markdown del Percorso online;
- `academy_module_key` risolve Centri e Insegnanti tramite `AcademyCurriculum`;
- i due riferimenti restano separati perché descrivono cataloghi e funzioni differenti;
- non vengono create associazioni implicite confrontando titoli o slug.

## Linguette confermate

### 1. Percorso online

Mostra per il corso selezionato:

- presentazione e stato del corso;
- programma;
- capitoli e attività;
- avanzamento della persona autenticata;
- azione per iniziare o continuare.

Nel prototipo i contenuti provengono dagli YAML e Markdown oggi utilizzati da `/percorso-posturacorretta`. Non devono essere copiati: vanno letti tramite un adattatore ed esposti in componenti Rails riutilizzabili, filtrati per Node corso e sezione.

### 2. Programma lezioni

Mostra per il corso selezionato il programma degli incontri guidati con un operatore:

- titolo, ordine e obiettivo delle lezioni previste;
- eventuali materiali online consigliati prima o dopo l'incontro;
- eventuali attività previste dal programma.

Nel prototipo i dati provengono dagli YAML oggi utilizzati da `/posturacorretta/lezioni`. Vanno filtrati per Node corso, senza generare una lezione per ogni sezione online.

In questa fase il pannello mostra **soltanto il programma**. Non mostra date, luoghi, disponibilità, prenotazioni, partecipazione, avanzamento personale o stati degli incontri.

In futuro gli insegnanti creeranno gli incontri reali a partire da una voce del programma. Eventi e DataCommitment verranno progettati in una fase successiva senza modificare la struttura della home.

### Lezione programmata futura

L'Aula online non è un Centro e non appartiene al Percorso online. Viene configurata sotto la singola **lezione programmata**.

Una futura lezione programmata collegherà:

- una voce del Programma lezioni;
- un insegnante o operatore;
- data e orario;
- modalità `in presenza`, `online` oppure `ibrida`;
- un Centro o luogo fisico quando la modalità comprende la presenza;
- un'Aula online quando la modalità comprende la diretta online;
- disponibilità e prenotazioni, in una fase successiva.

Regole:

- `in presenza`: richiede il luogo fisico, non richiede l'Aula online;
- `online`: richiede l'Aula online, non richiede un Centro fisico;
- `ibrida`: richiede sia il luogo fisico sia l'Aula online;
- le credenziali o il collegamento riservato dell'Aula online non vengono esposti nei file o nelle pagine pubbliche;
- questa struttura verrà implementata quando saranno affrontati Eventi e DataCommitment, non nel primo prototipo.

### 3. Centri

Sostituisce la linguetta **Tirocinio**.

Nel prototipo mostra i luoghi fisici nei quali il corso selezionato può essere proposto. Le Aule online non vengono elencate come Centri: saranno configurate nelle future lezioni programmate.

Da definire prima dell'implementazione:

- relazione dati fra Centro e Node/corso;
- ordinamento iniziale dei centri;
- comportamento quando un corso non ha ancora centri associati;
- eventuale filtro futuro per territorio o distanza.

### 4. Insegnanti

Mostra esclusivamente gli insegnanti abilitati sul corso selezionato, con il relativo centro quando disponibile.

La selezione utilizza `academy_module_key` del Node e i profili caricati da `AcademyCurriculum`.

Un insegnante viene mostrato soltanto quando:

- ha `public: true`;
- ha `status: active`;
- il suo elenco `active_modules` contiene `academy_module_key`.

Se non esistono insegnanti idonei viene mostrato uno stato vuoto, senza associazioni dedotte o profili dimostrativi.

Per il prototipo della Prima settimana, associato al modulo `introduzione`, il profilo attualmente idoneo è **Mark Postura**.

## Tirocinio

Il tirocinio non compare nella home pubblica per ora.

In futuro diventerà una funzione condizionale, visibile soltanto quando la persona:

1. ha completato il corso richiesto;
2. ha richiesto o ottenuto l'iscrizione al percorso per diventare insegnante;
3. possiede i permessi necessari.

Non va quindi trattato come una normale linguetta pubblica sempre disponibile.

## Ruolo delle pagine esistenti

- `/posturacorretta`: dashboard contestuale del corso selezionato.
- `/percorso-posturacorretta`: panoramica completa del percorso online.
- `/posturacorretta/lezioni`: programma generale e, in futuro, agenda degli incontri realmente programmati.

Le pagine esistenti restano disponibili, ma condividono partial e query con la home. La home mostra soltanto la porzione relativa al corso selezionato.

## Regole tecniche

- Nessuna duplicazione manuale dei contenuti.
- Il parametro `tappa` identifica lo slug del Node/corso.
- Il Node identificato da `tappa` risolve la sorgente didattica attraverso `course_key`.
- Lo stesso Node risolve Centri e Insegnanti attraverso `academy_module_key`.
- Il parametro `tab` identifica `online`, `lezioni`, `centri` o `insegnanti`; il valore tecnico `lezioni` viene presentato nell'interfaccia come **Programma lezioni**.
- Un URL condiviso deve riaprire corso e linguetta corretti.
- Se lo slug non è valido, si torna al primo corso disponibile.
- La selezione della linguetta non deve ricaricare l'intera pagina.
- Autorizzazioni e dati personali devono essere verificati dal server, non soltanto nascosti nell'interfaccia.

## Fasi proposte

### Fase 1 · Primo corso

- Usare `La prima settimana con PosturaCorretta` come caso pilota.
- Rilevare dagli YAML e Markdown esistenti sezioni, contenuti e lezioni disponibili.
- Creare un adattatore temporaneo che presenti questi dati in base al Node corso.
- Estrarre il pannello Percorso online in un partial riutilizzabile.
- Estrarre il pannello Programma lezioni in un partial riutilizzabile.
- Conservare `/percorso-posturacorretta` come backup invariato durante il prototipo.
- Sostituire Tirocinio con Centri, inizialmente anche con uno stato vuoto esplicativo se il modello Centro non è ancora definito.
- Collegare gli Insegnanti reali del corso.

### Fase 2 · Dati e relazioni

- Definire la relazione Centro ↔ corso.
- Verificare la relazione Insegnante ↔ corso ↔ Centro.
- Aggiungere stati vuoti chiari per corsi privi di lezioni, centri o insegnanti.

### Fase 3 · Tutti i corsi

- Applicare lo stesso componente agli altri pallini della linea.
- Verificare URL, permessi e navigazione avanti/indietro.
- Mantenere le pagine panoramiche senza duplicare le query.

### Fase 4 · Percorso insegnanti

- Definire requisiti di completamento.
- Definire iscrizione e approvazione.
- Rendere disponibile il tirocinio soltanto agli utenti idonei.

