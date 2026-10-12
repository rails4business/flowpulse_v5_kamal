# GeneraImpresa, Rails4Business e metodo della soluzione atomica

> **Documento di lavoro.** Questa è la base concettuale da verificare prima
> dell'implementazione nel database e nelle interfacce. Distingue il ruolo
> dell'imprenditore, quello dei professionisti digitali, lo sviluppo di una
> soluzione e l'esecuzione di un programma da parte di una persona.

## 1. Distinzione essenziale

### GeneraImpresa: l'imprenditore che porta l'idea

GeneraImpresa è lo spazio dell'imprenditore, dell'ideatore o del proprietario
del Brand. Serve a:

- partire da un bisogno o da un problema;
- formulare un'idea;
- creare il Brand e i suoi progetti;
- scegliere priorità e risorse;
- assegnare un responsabile a ogni progetto;
- decidere quale problema affrontare per primo;
- verificare se la soluzione può diventare sostenibile.

GeneraImpresa risponde alla domanda:

> Che cosa vogliamo costruire, perché e sotto la responsabilità di chi?

### Rails4Business: i professionisti digitali che lavorano

Rails4Business è lo spazio dei professionisti digitali che collaborano alla
realizzazione. Comprende sviluppo software, contenuti, design, marketing,
sicurezza, automazioni, dati e organizzazione dei processi digitali.

Serve a:

- trasformare l'idea in lavoro realizzabile;
- costruire strumenti e processi;
- distribuire il lavoro tra i collaboratori;
- documentare le soluzioni;
- rendere riutilizzabile ciò che ha funzionato;
- applicare una soluzione a uno o più Brand.

Rails4Business risponde alla domanda:

> Come realizziamo la soluzione e quali professionisti digitali servono?

La distinzione non dipende dalla dimensione del progetto. La stessa persona
può inizialmente essere sia imprenditore sia professionista digitale, ma deve
sapere quale ruolo sta svolgendo in quel momento.

```text
GeneraImpresa
Imprenditore → problema → idea → Brand → progetto → responsabile

Rails4Business
Professionisti digitali → lavoro → strumenti → processi → soluzione realizzata
```

## 2. Ruolo di FlowPulse e 1Impegno

FlowPulse è l'infrastruttura comune che collega persone, Node, Brand, progetti,
processi, programmi ed eventi di sviluppo. Non sostituisce GeneraImpresa o
Rails4Business: rende visibili e collegabili le informazioni prodotte dai due
spazi.

1Impegno registra il tempo e gli impegni effettivi con cui le persone eseguono
attività, Session e programmi.

```text
GeneraImpresa   → decide cosa costruire
Rails4Business  → organizza chi e come lo realizza
FlowPulse       → collega e rende visibile il sistema
1Impegno        → registra il lavoro e gli impegni nel tempo
```

## 3. Node, Brand e progetto

`Node` è l'unità organizzativa comune.

- Un Node con un Domain è anche un **Brand** pubblico.
- Un Node senza Domain può rappresentare un progetto, un processo, uno
  strumento o un'altra parte interna.
- Un Brand può contenere più progetti.
- Ogni progetto deve avere un responsabile.
- Una soluzione condivisa può essere collegata a più Brand senza essere
  duplicata.

L'albero dei Node descrive che cosa appartiene a che cosa. Non descrive, da
solo, l'ordine con cui una persona deve attraversare un programma.

## 4. Un solo Node di attenzione

Ogni responsabile sceglie un solo Node come attenzione principale. Gli altri
Node possono essere in attesa, delegati, automatizzati, in mantenimento oppure
chiusi.

Il Node attivo deve mostrare almeno:

- il problema corrente;
- il responsabile;
- il ciclo atomico attivo;
- la fase raggiunta;
- l'ultimo aggiornamento;
- il prossimo passo;
- il criterio necessario per chiudere la fase.

Più responsabili possono lavorare contemporaneamente su Node diversi. Il
vincolo riguarda l'attenzione della singola persona, non l'intero ecosistema.

## 5. Il ciclo della soluzione atomica

Ogni problema apre un ciclo di sviluppo delimitato. La soluzione può essere
considerata valida soltanto se supera tutte le fasi concordate.

```text
1. Trova un problema risolvibile
2. Isola il problema
3. Definiscilo chiaramente
4. Progetta la soluzione più semplice
5. Provala su di te
6. Provala con 1, 3 e 7 persone
7. Raccogli feedback e correggi
8. Valida la soluzione
9. Raccontala e passala a chi ha lo stesso problema
10. Diffondila gradualmente: 8, 16, 32, 64
11. Standardizza, delega o automatizza
12. Chiudi il ciclo e passa al problema successivo
```

### Diffondere non significa soltanto fare pubblicità

Dopo la validazione bisogna trovare le persone che hanno realmente quel
problema. Il primo strumento è il passaparola:

- descrivere il problema con parole riconoscibili;
- spiegare la soluzione senza promettere più di ciò che è stato verificato;
- consegnarla alle prime persone interessate;
- permettere loro di raccontare l'esperienza;
- osservare se la soluzione funziona fuori dal gruppo iniziale;
- aumentare il numero di persone gradualmente.

Il passaggio `8 → 16 → 32 → 64` non è soltanto crescita numerica. Verifica se
la soluzione continua a funzionare quando aumenta il numero di persone e
diminuisce il controllo diretto dell'ideatore.

## 6. Esiti del ciclo

Un ciclo iniziato non deve rimanere indefinitamente aperto. Deve arrivare a un
esito esplicito.

### Validato

La soluzione ha superato tutte le fasi e può diventare un servizio, uno
strumento, un processo o un programma ripetibile.

### Aperto

Mancano ancora prove, correzioni o fasi. La soluzione non può essere presentata
come validata.

### Chiuso senza validazione

La soluzione non ha funzionato, il problema non è più prioritario oppure le
risorse necessarie non sono disponibili. Si conserva ciò che è stato imparato
e si registra il motivo della chiusura.

Se nasce una nuova ipotesi, si apre un nuovo ciclo invece di riscrivere la
storia del precedente.

## 7. Che cosa significa atomicità

Atomicità non significa completare tutto senza pause. Significa che ogni ciclo
ha confini ed esiti riconoscibili:

- un punto di inizio;
- un problema delimitato;
- un responsabile;
- ingressi necessari;
- fasi definite;
- criteri per superare ogni fase;
- un risultato atteso;
- una modalità di chiusura anche in caso di insuccesso.

Una fase può essere sospesa, ma non deve scomparire in uno stato ambiguo. Deve
essere ripresa oppure chiusa dichiarando il motivo.

## 8. Atomicità dei processi

Il principio deve essere discusso anche quando si definisce un processo. Prima
di avviarlo bisogna stabilire:

- quando comincia;
- che cosa riceve in ingresso;
- quali passaggi contiene;
- chi è responsabile di ogni passaggio;
- quali condizioni determinano i rami;
- che cosa significa completato;
- che cosa succede se un passaggio fallisce;
- quali dati, materiali o risultati rimangono alla chiusura.

Esempio:

```text
Pubblicare un contenuto
→ proposta
→ bozza
→ revisione
→ approvazione
→ programmazione
→ pubblicazione
→ verifica
→ chiusura
```

Se il contenuto non viene pubblicato, il processo termina comunque con un
esito: respinto, rinviato, archiviato oppure sostituito.

## 9. Processo, algoritmo e ricetta

Un processo è una ricetta riutilizzabile formata da una serie di passaggi. Può
essere lineare oppure contenere rami e condizioni.

```text
Inizio
  ↓
Valutazione
  ├── condizione A → percorso A
  ├── condizione B → percorso B
  └── condizione C → intervento professionale
                           ↓
                         Esito
```

La definizione conserva la ricetta generale. Ogni esecuzione conserva ciò che
è realmente successo in quel caso.

Una soluzione validata può diventare una nuova ricetta. La ricetta può essere
applicata da persone e Brand diversi senza duplicare la sua definizione.

## 10. Albero del Brand e programma della persona

Sono due rappresentazioni differenti.

### Albero del Brand

Mostra la struttura di ciò che l'imprenditore sta costruendo.

```text
PosturaCorretta
├── Percorso online
├── Programma lezioni
├── Contenuti
├── Eventi sportivi
└── Percorso Integrato
```

Serve a vedere:

- quali progetti esistono;
- chi ne è responsabile;
- quale Node richiede attenzione;
- quali soluzioni e processi vengono utilizzati;
- quali parti sono interne e quali possiedono un Domain.

### Programma della persona

Mostra il percorso seguito da una persona.

```text
Persona
└── Programma PosturaCorretta
    ├── incontro iniziale
    ├── prima scheda
    ├── pratica personale
    ├── verifica
    ├── eventuale insegnante
    └── eventuale professionista
```

Due persone possono attraversare rami differenti dello stesso programma.
L'albero del Brand non deve essere usato come se fosse l'avanzamento della
persona.

## 11. Definizione ed esecuzione del programma

La definizione del programma contiene:

- punto di ingresso;
- passaggi;
- condizioni;
- rami;
- eventuali ritorni;
- criteri di completamento;
- esiti possibili.

L'esecuzione personale contiene:

- persona o gruppo coinvolto;
- data di inizio;
- passaggi completati;
- posizione corrente;
- risposte e materiali prodotti;
- professionisti coinvolti;
- esito finale.

La definizione non deve essere duplicata per ogni persona. Ogni persona riceve
un'istanza che registra il proprio avanzamento.

## 12. Soluzioni condivise tra più Brand

Una soluzione come la produzione dei contenuti può avere una sola definizione
e servire più Brand.

```text
Processo editoriale
├── responsabile
├── versione
├── fasi e atomicità
└── utilizzato da
    ├── PosturaCorretta
    ├── Rails4Business
    └── Il Giardino del Corpo
```

Ogni Brand mantiene il proprio progetto editoriale e i propri contenuti, ma
utilizza la stessa ricetta. Un Node ponte può rappresentare il collegamento
senza copiare il processo.

## 13. Presentazione di Mark Postura

La presentazione pubblica è divisa in tre tab principali: chi sono, metodo di
lavoro e ambiti di applicazione.

### Chi sono

Mark Postura non viene presentato soltanto come fisioterapista, ma come
esploratore e iniziatore di soluzioni. I suoi punti di forza sono:

- immaginare una possibilità partendo da un problema;
- muoversi tra discipline differenti;
- entrare spontaneamente in relazione con le persone;
- ascoltare chi vive il problema;
- trasformare un'idea in una prima prova;
- correggere attraverso il feedback;
- riunire le persone necessarie per dare il primo impulso.

Il contributo principale si trova nel fuoco iniziale. Quando un progetto
diventa continuativo, segreteria, amministrazione, coordinamento e gestione
quotidiana devono essere affidati a persone adatte a quei ruoli.

Tre immagini dei tarocchi possono raccontare questa indole senza trasformare
la presentazione pubblica in una procedura meccanica:

- **Il Matto** parte, esplora, incontra persone e lascia spazio all'imprevisto;
- **L'Eremita** si ferma, osserva, studia e cerca ciò che conta davvero;
- **Il Mago** riconosce le risorse disponibili e le combina per dare una prima
  forma concreta all'idea.

Non significano rifiutare tutte le regole, ma non accettare automaticamente
una strada soltanto perché convenzionale. Le regole utili restano; quelle che
stringono senza risolvere il problema vengono rimesse alla prova.

### Metodo di lavoro

La soluzione atomica viene presentata prima della linea del metodo. Il termine
si ispira all'atomicità nella programmazione: un'operazione viene trattata come
un insieme unico e non è completata se rimane a metà. Nei progetti questo
significa che una soluzione è validata soltanto quando tutti i passaggi
concordati sono stati conclusi.

Se il ciclo si interrompe, la soluzione rimane aperta oppure viene chiusa senza
validazione. Ciò che è stato imparato non viene cancellato e può essere usato
in un nuovo ciclo.

La pagina pubblica può riassumere il metodo, mentre la scheda operativa di
Rails4Business conserva tutti i passaggi: definire il problema, isolarlo,
immaginare più soluzioni possibili, scegliere la soluzione minima, provarla su
di sé, provarla con poche persone, raccogliere feedback e correggere,
verificarla, diffonderla e infine chiudere, automatizzare oppure riaprire il
ciclo.

### Dalla soluzione a FlowPulse

Dopo la linea del metodo, la pagina pubblica mostra come una soluzione entra
nell'ecosistema. FlowPulse è la piattaforma comune; persone e progetti vi
entrano con responsabilità differenti.

```text
FlowPulse — piattaforma
│
└── Brand
    ├── tipo: Brand professionista oppure Brand progetto
    ├── progetti
    │   ├── un responsabile per ogni progetto
    │   └── più ruoli ricoperti dagli operatori
    ├── Skill installate
    │   ├── Contenuti
    │   ├── Corsi
    │   └── Eventi
    └── utenti che utilizzano ciò che i progetti rendono disponibile
```

Un possibile esempio, legato alla configurazione di Mark Postura, è:

```text
FlowPulse
→ Brand professionale: MarkPostura
→ PosturaCorretta
→ Percorso educativo
→ Insegnante
→ Utente
```

È soltanto un esempio: non tutti i Brand devono avere la stessa struttura o
attraversare gli stessi passaggi.

`ReusableSkill` è il modello che registra una capacità riutilizzabile. La
stessa Skill può essere collegata a più Node senza duplicarne la definizione.
Una Skill e un problema restano oggetti separati: il collegamento fra loro è
facoltativo e viene creato soltanto quando serve.

### Due tipi di Brand

La distinzione si ottiene combinando il tipo del Node con la presenza del
Domain:

- **Brand professionista**: un Node `professional` con Domain, per esempio
  MarkPostura;
- **Brand progetto**: un Node `project` con Domain, per esempio
  PosturaCorretta.

Ogni Brand contiene progetti che ne realizzano concretamente lo scopo. I
progetti possono essere percorsi, servizi, contenuti, eventi, strumenti o
processi. L'insieme organizzato dei Brand e dei loro progetti forma l'impresa.

### Skill comuni in Rails4Business

Le Skill comuni funzionano come plugin e vengono definite e mantenute in
Rails4Business. Esempi di Skill sono `Contenuti`, `Corsi` ed `Eventi`. Una
Skill raccoglie al proprio interno:

- il processo;
- le istruzioni;
- i contenuti necessari;
- materiali e modelli;
- criteri per avvio e chiusura.

Quando un Brand ne ha bisogno, non copia la Skill: la attiva collegandola a uno
o più progetti o Node. La definizione rimane unica in Rails4Business; ogni
Brand conserva responsabile, esecuzioni, contenuti specifici e risultati.

Il processo e i materiali della Skill non diventano automaticamente progetti
o rami dell'albero del Brand. Rimangono parti interne del plugin; l'albero del
Brand mostra i progetti, i loro responsabili e i ruoli necessari.

```text
Rails4Business
→ Skill comune
→ attivazione in PosturaCorretta
→ attivazione nel Giardino del Corpo
→ attivazione nel Brand di un professionista
```

## Mappa amministrativa di Brand e Node

La visione globale appartiene a FlowPulse, perché attraversa tutti i Brand
dell'ecosistema. La creazione e lo sviluppo di problemi e Skill rimangono
invece in Rails4Business.

La pagina superadmin globale deve mostrare inizialmente soltanto i Node che
possiedono almeno un Domain. Non deve caricare nello stesso albero ogni Node
del database.

```text
FlowPulse superadmin
├── vista: Brand progetto con dominio
└── vista: Brand professionali con dominio
```

Queste due voci sono filtri della vista e **non sono Node contenitore**. La
distinzione esiste già in `node_type`; creare due ulteriori Node duplicherebbe
un'informazione presente nel modello e produrrebbe appartenenze artificiali.

I due tipi devono rimanere distinti:

- un **Brand progetto** è un Node `project` con Domain e può essere aperto per
  consultarne l'albero di progetti e sottoprogetti;
- un **Brand professionale** è un Node `professional` con Domain e viene
  mostrato in un elenco personale separato;
- il rapporto fra un professionista e un Brand progetto viene espresso con
  ruoli e relazioni, non inserendo il Brand professionale nell'albero del
  progetto.

### Vista globale

Percorso previsto:

```text
/flowpulse/admin/brands
```

La prima schermata mostra solo:

- nome del Brand;
- tipo: progetto oppure professionale;
- dominio o domini collegati;
- stato;
- proprietario;
- collegamento alla scheda del Brand.

Non mostra ancora i figli. In questo modo la mappa generale rimane leggibile
anche quando aumentano progetti e sottoprogetti.

### Apertura di un Brand progetto

Aprendo un Brand progetto si vede il suo albero interno:

```text
PosturaCorretta
├── Percorso online
├── Programma lezioni
├── Contenuti
└── Eventi
```

L'albero usa `parent_id` soltanto per rappresentare la struttura interna del
Brand. Un Brand professionale non viene inserito in questo albero per indicare
una collaborazione.

Un progetto interno può diventare a sua volta un sotto-Brand quando possiede un
Domain. La sua profondità non è prestabilita: fra la radice del Brand e quel
Node possono esistere altri progetti, sottoprogetti e, in futuro, collegamenti
ponte. Per esempio `Igiene Posturale` potrà essere un discendente di
`PosturaCorretta`, ma il suo genitore diretto verrà deciso soltanto quando
l'albero reale sarà stato definito. Il dominio `igieneposturale.it` andrà
collegato al Node che rappresenterà la sua effettiva radice pubblica.

I Node sono quindi una struttura evolutiva: possono essere aggiunti, spostati
o articolati senza cambiare il significato del Domain. `parent_id` descrive la
gerarchia effettiva; un Node ponte descrive invece un collegamento trasversale
e non rende il Node collegato un figlio. Quando l'esplorazione incontra un Node
con Domain, lo mostra come confine navigabile verso il sotto-Brand e non ne
espande automaticamente i discendenti.

### Node, Domain, lingua e Site

Le responsabilità restano separate:

- il **Node** rappresenta identità, appartenenza e struttura;
- il **Domain** rappresenta un indirizzo pubblico del Node;
- la **lingua** descrive la versione linguistica pubblicata dal Domain;
- il **Site** (`site_key`) sceglie struttura editoriale e presentazione.

Un Node può avere più Domain. Più Domain possono condividere lo stesso Site;
lo stesso Node può usare Site diversi soltanto quando serve davvero una
presentazione o una struttura editoriale differente. Gli alias tecnici, come
`www`, puntano al dominio canonico; un dominio in un'altra lingua non è un
alias e conserva canonical, lingua, sitemap e in futuro `hreflang` propri.

Il Domain non ricostruisce né congela l'albero: conserva il riferimento al
proprio Node radice. Di conseguenza la struttura sottostante può evolvere e la
proiezione pubblica viene calcolata ogni volta a partire da quel Node,
applicando stato, visibilità, confini dei sotto-Brand e collegamenti ponte.

### Apertura di un Node

Nella scheda del singolo Node devono essere leggibili progressivamente:

- panoramica e posizione nell'albero;
- sviluppo e NodeEvent;
- problemi collegati;
- Skill collegate;
- processi ed esperienze.

I dati non vengono duplicati:

- FlowPulse mostra la mappa e le associazioni;
- Rails4Business crea e sviluppa `ProblemSolvingCycle` e `ReusableSkill`;
- l'admin del Brand collega problemi e Skill ai propri Node;
- 1Impegno registra il lavoro concreto, il tempo e gli appuntamenti.

### Ordine di implementazione

Si procede un blocco alla volta:

1. **Registro globale dei Brand con dominio**: due elenchi separati, Brand
   progetto e Brand professionali.
2. **Scheda del Brand progetto**: apertura dell'albero interno già esistente,
   senza cambiare ancora le associazioni.
3. **Problemi nel Node**: visualizzazione, collegamento e scollegamento dei
   `ProblemSolvingCycle` disponibili.
4. **Skill nel Node**: visualizzazione, collegamento e scollegamento delle
   `ReusableSkill` disponibili.
5. **Regole strutturali**: impedire gerarchie improprie fra Brand personali e
   Brand progetto, riconoscere i sotto-Brand con Domain e verificare
   l'isolamento amministrativo fra Brand.

Il primo blocco è intenzionalmente piccolo: deve offrire al superadmin una
visione generale dei soli Brand dotati di dominio, senza anticipare tutte le
funzioni della scheda Node.

### Stato dell'implementazione

Il primo blocco è disponibile nell'area superadmin FlowPulse:

```text
/flowpulse/admin/brands
```

Sono già presenti:

- registri separati per Brand progetto e Brand professionali;
- visualizzazione dei soli Brand dotati di dominio;
- rete dei Brand progetto nella scheda di un Brand professionale;
- albero interno del Brand progetto;
- arresto dell'espansione quando l'albero incontra un sotto-Brand con dominio;
- portale per aprire il sotto-Brand come nuovo contesto;
- conteggio dei problemi e delle Skill collegati ai Node.

Lo stesso confine è applicato nell'albero operativo del proprietario:

```text
/:brand_slug/admin/nodes
```

Lista e schema mostrano il sotto-Brand ma non i suoi discendenti. Il
proprietario non può modificare quei discendenti usando il contesto del Brand
padre: deve aprire il sotto-Brand e superare il relativo controllo di accesso.
Nel Brand padre non è inoltre possibile aggiungere nuovi figli direttamente
sotto il portale del sotto-Brand.

La mappa globale rimane riservata al superadmin. La rete personale è
disponibile separatamente:

```text
/flowpulse/rete
```

La pagina applica gli stessi confini ma mostra soltanto:

- Brand professionali appartenenti alla persona;
- Brand progetto posseduti;
- Brand amministrati tramite un ruolo contestuale;
- collaborazioni operative e relativo ruolo.

La rappresentazione è una lista ad albero essenziale: il Brand professionale
fa da radice visiva, sotto compaiono i suoi Brand progetto e ogni riga mostra
soltanto nome e dominio. I Node interni si vedono solo dopo aver aperto il
Brand progetto. Se il collegamento a un Brand professionale non è esplicito o
univoco, il Brand viene conservato in “Altri Brand posseduti” invece di
inventare una gerarchia.

Anche il superadmin vede in questa pagina soltanto la propria rete personale;
per consultare tutto l'ecosistema deve aprire la mappa globale. In questo modo
il privilegio amministrativo non rende ambigua la normale esperienza utente.

### Gli ambiti di applicazione

Il metodo viene applicato in tre campi, ciascuno con pubblico, linguaggio e
confini differenti.

1. **Salute e metodo scientifico** — persone, insegnanti, professionisti ed
   enti. Comprende PosturaCorretta, Percorso Integrato e altri progetti che
   entrano nel mondo dell'educazione alla salute e delle attività
   professionali. Educazione, insegnamento, trattamento e cura devono restare
   distinguibili.
2. **Evoluzione armonica dell'essere umano** — persone, gruppi e comunità.
   Comprende stile di vita, natura, arte, musica, consapevolezza, spiritualità,
   divulgazione ed esperienze come Il Giardino del Corpo. Queste attività
   possono sostenere il benessere, ma non vengono presentate come diagnosi o
   cure.
3. **Lavoro e risorse** — imprenditori, professionisti e collaboratori
   digitali. GeneraImpresa aiuta chi porta l'idea; Rails4Business riunisce i
   professionisti digitali che la realizzano; FlowPulse collega il sistema e
   1Impegno ne registra le attività effettive.

Gli ambiti sono una classificazione editoriale e di pubblico. Non devono
diventare valori di `node_type` e non sostituiscono l'albero dei Brand.

Le tre categorie indicano dove vengono cercati i problemi. Il metodo indica
come vengono affrontati.

> Affronto problemi legati alla salute, al lavoro e al modo in cui viviamo. Li
> isolo, costruisco la soluzione più semplice e la provo gradualmente. Quando
> funziona, la passo alle persone che hanno lo stesso problema e verifico se
> può diventare un progetto, un servizio o un processo ripetibile. Quando non
> funziona, chiudo il ciclo, conservo ciò che ho imparato e passo al problema
> successivo.

Il riferimento alla postura e alla natura non deve rimanere una metafora
generica:

> Il corpo non risolve tutto insieme. Riceve segnali, distribuisce risorse,
> prova adattamenti e continua a correggersi. Applico lo stesso principio ai
> progetti: un problema alla volta, una soluzione verificabile e un ciclo da
> portare a conclusione.

Principi comuni:

- partire dalle risorse disponibili;
- modificare una cosa alla volta;
- osservare la risposta;
- correggere attraverso il feedback;
- aumentare gradualmente la complessità;
- distribuire responsabilità e carichi;
- portare ogni ciclo a un esito esplicito.

## 14. Prima dell'implementazione

Prima di modificare modelli e controller bisogna ancora decidere:

1. se il ciclo atomico è un nuovo modello oppure un tipo di processo;
2. come collegare responsabile, Node e ciclo attivo;
3. quali fasi sono obbligatorie e quali configurabili;
4. come registrare i criteri di superamento delle fasi;
5. come distinguere definizione del processo ed esecuzione;
6. come rappresentare i rami senza confonderli con `parent_node_id`;
7. quali NodeEvent documentano test, feedback, validazione e diffusione;
8. come una soluzione validata diventa un processo condiviso;
9. dove registrare il passaparola e la crescita `8 → 16 → 32 → 64`;
10. quali parti devono essere pubbliche nella presentazione di Mark Postura e
    quali devono restare strumenti operativi.

Queste decisioni devono precedere l'implementazione, per evitare di usare lo
stesso campo sia per la struttura del Brand sia per l'avanzamento delle
persone.
