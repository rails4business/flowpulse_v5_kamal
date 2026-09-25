# Flowpulse — principi, brand e organizzazione settimanale

> **Fonte organizzativa corrente.** Questo documento definisce chi fa cosa,
> come si distinguono i tre canali principali e in quale ordine procedere. La
> struttura tecnica di contenuti e attività resta descritta in
> [ARCHITETTURA_CICLI_CONTENUTI_E_SERVIZI.md](ARCHITETTURA_CICLI_CONTENUTI_E_SERVIZI.md).

## 1. Ruolo di Flowpulse

Flowpulse è la piattaforma comune creata da Rails4Business per collegare
persone, brand, contenuti, eventi, processi e impegni.

Flowpulse non sostituisce i singoli brand e non deve renderli indistinguibili.
Ogni brand conserva identità, linguaggio, responsabili, pubblico e dominio.
La piattaforma fornisce una struttura condivisa per evitare di ricostruire ogni
volta gli stessi strumenti.

## 2. Le aree principali

```text
Flowpulse — piattaforma e principi comuni
│
├── Rails4Business — linee guida, collaborazione e costruzione dei processi
├── GeneraImpresa — dall'idea al progetto sostenibile
├── 1Impegno — uso quotidiano dei processi e organizzazione del tempo
├── PosturaCorretta — educazione, pratica e formazione posturale
└── Il Giardino del Corpo — natura, musica e filosofia
```

### Rails4Business

Rails4Business raccoglie linee guida, consigli e modalità di collaborazione.
Costruisce la piattaforma e aiuta i brand a rendere più chiari, semplici e
sostenibili i propri processi. Ruby on Rails è il framework di punta e la sua
filosofia ispira il nome e il modo di lavorare.

Può lavorare:

- sui propri prodotti, tra cui Flowpulse e 1Impegno;
- sui processi di PosturaCorretta e del Giardino del Corpo;
- sui progetti di professionisti esterni, come Radioestesia;
- sull'organizzazione dei collaboratori digitali e della produzione di
  contenuti.

Rails4Business aiuta un progetto, ma non ne assume automaticamente la
responsabilità editoriale o professionale.

### GeneraImpresa

GeneraImpresa accompagna il passaggio da un bisogno o un'idea a un progetto
sostenibile. Serve a chiarire obiettivi, priorità, risorse, responsabilità e
modello economico prima di trasformarli in attività operative.

### 1Impegno

1Impegno è il punto in cui i processi vengono usati: organizza il tempo, le
Session, gli Slot, i luoghi, le persone e gli impegni effettivi.

La distinzione guida è semplice:

```text
Rails4Business + professionisti digitali → costruiscono la macchina
Professionisti + utenti in 1Impegno      → la pilotano e la usano
GeneraImpresa                             → chiarisce cosa costruire e con quali risorse
Flowpulse                                 → rende visibile e governa l'insieme
```

La dashboard gestionale appartiene quindi a Flowpulse. Rails4Business può
condurre alla dashboard, ma non deve duplicarla: rimane l'area per comprendere,
progettare e migliorare business e processi.

### PosturaCorretta

PosturaCorretta organizza:

- il percorso educativo sulla postura;
- lezioni e appuntamenti individuali;
- lezioni e percorsi di gruppo;
- centri e luoghi affiliati;
- formazione e tirocinio dei professionisti;
- contenuti, schede e video collegati al percorso.

### Il Giardino del Corpo

Il Giardino del Corpo organizza contenuti ed eventi legati a:

- natura;
- musica;
- filosofia sul valore, sulla ricchezza e sulla spiritualità;
- comunità, territorio e qualità della vita.

## 3. Responsabilità iniziali

Nella fase pilota il fondatore è responsabile dei contenuti di:

- Rails4Business;
- PosturaCorretta;
- Il Giardino del Corpo.

Questa è una condizione iniziale, non il modello definitivo. L'obiettivo è
creare tre gruppi di collaboratori e individuare per ciascuno un referente che
aiuti lo sviluppo del brand, dei processi, delle risorse e della sostenibilità
economica.

La produzione contenuti è un **processo trasversale**, non un quarto brand. Può
avere un proprio responsabile operativo e viene applicata separatamente ai
diversi brand:

```text
Rails4Business / processo contenuti
├── contenuti Rails4Business
├── contenuti PosturaCorretta
└── contenuti Il Giardino del Corpo
```

Finché non viene assegnato un responsabile dedicato, il fondatore mantiene la
responsabilità dei tre rami.

## 4. Professionisti e progetti esterni

Un professionista che entra nell'ecosistema conserva la responsabilità del
proprio progetto, dei propri contenuti e dei propri eventi.

Rails4Business può aiutarlo a:

- chiarire il processo;
- organizzare contenuti ed eventi;
- costruire o adattare il software;
- coordinare collaboratori digitali;
- misurare tempi, costi e risorse;
- migliorare progressivamente il funzionamento del progetto.

Radioestesia è il primo esempio di questa relazione: è un progetto autonomo
del professionista, sostenuto da Rails4Business per struttura, contenuti e
strumenti digitali.

## 5. Node, professionista, Brand e progetto

`Node` è l'elemento organizzativo comune. Professionista, Brand e progetto non
richiedono tre alberi o tre tabelle separate. `node_type` è un enum con due
valori: `professional` e `project`.

- un Node è **professional** quando è dichiarato esplicitamente tale, anche se
  il professionista non si è ancora iscritto;
- un Node è **Brand** quando possiede uno o più Domain;
- un Brand è anche un progetto;
- un Node figlio privo di Domain è un progetto o processo interno;
- un Node figlio che acquisisce un Domain diventa anche un sub-brand, senza
  dover essere ricreato.

Il tipo e la presenza del dominio rispondono quindi a domande diverse:

```text
node_type → che cosa rappresenta il Node
Domain    → se il Node è pubblicato anche come Brand
```

Radioestesia viene inizialmente registrata come Node `professional`, senza
Domain, sotto il contenitore gestionale temporaneo
`GeneraImpresa → Brand in costruzione`. Quando sarà pronta, l'eliminazione del
`parent_id` la renderà indipendente senza modificarne il tipo; l'aggiunta del
Domain la renderà anche un Brand.

Le due relazioni tra Node hanno significati distinti:

```text
parent_node_id
→ appartenenza organizzativa: di quale Brand/progetto/processo fa parte

professional_owner_node_id
→ professionista responsabile: deve puntare a un Node professional
```

Il Node professionale principale non deve necessariamente avere un
`professional_owner_node_id`. Quando il professionista possiede un profilo,
`Profile#primary_node_id` lo collega al Node già dichiarato professional. Il
collegamento è facoltativo, così il Node può essere mostrato inizialmente come
demo e associato alla persona dopo l'iscrizione.

Instagram e YouTube possono essere Node-processo figli del relativo Brand. In
futuro potranno avere Cycle, Session e Slot propri.

Non si introduce ora alcun `primary_content_id`. Contenuti, corsi, capitoli,
DataSession e DataSlot verranno collegati a Node e responsabile soltanto dopo i
prototipi YAML già pianificati.

## 6. Processi e futura traduzione nel software

Un processo reale verrà descritto e gestito con:

```text
Cycle
└── DataSession
    └── DataSlot
```

- **Cycle**: dima o ciclo ripetibile del processo;
- **DataSession**: incontro, blocco di lavoro, lezione o appuntamento;
- **DataSlot**: posizione interna della Session, utilizzabile per contenuti,
  prenotazioni, attività operative o compiti.

Contenuti ed eventi mantengono le regole già definite:

- il contenuto appartiene a un brand e ha un responsabile;
- un evento effettivo è una Session pubblica e datata;
- una Session può collegare contenuti attraverso i suoi Slot;
- Cycle e Service saranno implementati soltanto dopo la prova delle Session e
  degli Slot in YAML.

## 7. Week plan prima dell'automazione

Prima di completare 1Impegno serve un orario settimanale di riferimento. Non è
ancora il calendario degli appuntamenti: stabilisce quanto spazio concedere ai
diversi ambiti e rende visibili limiti, spostamenti e recupero.

Il week plan deve distinguere almeno:

- Rails4Business e sviluppo dei processi;
- PosturaCorretta: gruppi, singoli e formazione;
- Giardino del Corpo: progettazione ed eventi;
- produzione di contenuti, indicando il brand destinatario;
- amministrazione e coordinamento;
- vita personale, pasti, recupero e spostamenti;
- spazi prenotabili o ancora disponibili.

Quando qualcuno chiede disponibilità, questo schema è il primo riferimento.
Gli appuntamenti confermati verranno poi collocati nelle Session disponibili.

## 8. Calendario unico e tre vie editoriali

Contenuti ed eventi devono convivere in un unico calendario, distinguibili per
tipo, data, Brand, professionista responsabile e visibilità. La pagina del
professionista può aggregare gli elementi dei Brand di cui è responsabile;
eventi o contenuti affidati in futuro a un altro professionista restano nel
Brand ma compaiono nella pagina del nuovo responsabile.

Ogni elemento deve avere un brand proprietario e una sola fonte principale.
Gli altri brand possono richiamarlo con un collegamento, senza duplicarlo.

- `rails4b.com`: software, processi, collaborazioni digitali e costruzione dei
  progetti;
- `posturacorretta.org`: postura, percorsi, lezioni, formazione e relativi
  contenuti;
- `ilgiardinodelcorpo.it`: natura, musica, filosofia ed eventi tematici.

L'articolo di presentazione comune dovrà spiegare come queste tre vie
collaborano, mantenendo per ciascun sito un'introduzione e una chiamata
all'azione coerenti con il suo pubblico.

## 9. Ordine operativo confermato

1. Riordinare gli MD esistenti assegnando fonte, brand e stato.
2. Sistemare provvisoriamente i contenuti nei tre canali principali.
3. Provare su MarkPostura un week plan HTML schematico, locale e raggiungibile
   dal solo indice laterale.
4. Scrivere l'articolo comune di presentazione dei tre canali.
5. Proseguire il piano tecnico con `DataSession → DataSlot` in YAML.
6. Provare la gestione contenuti per Brand e ruolo Creator.
7. Unificare la visualizzazione datata di contenuti ed eventi.
8. Solo in seguito creare il registro YAML e la pagina interna dei processi.
9. Soltanto dopo i casi reali, valutare database, Cycle e Service.

## 10. Criterio per non disperdere l'attenzione

In ogni settimana devono essere riconoscibili:

- un brand pilota prioritario;
- un solo risultato principale per ciascun gruppo;
- un responsabile per ogni risultato;
- un prossimo passo osservabile;
- uno spazio massimo assegnato, oltre il quale il lavoro viene rinviato.

Il pilota applicativo rimane PosturaCorretta. Rails4Business può sviluppare e
ottimizzare gli strumenti necessari; Il Giardino del Corpo può preparare i
propri contenuti ed eventi senza aprire contemporaneamente nuovi modelli dati.
