# Schema — Skill, prodotti, catene produttive e 1impegno

**Data:** 19 ottobre 2026  
**Stato:** schema concettuale corrente; non richiede nuovi modelli per il primo incremento
**Obiettivo:** distinguere ciò che esiste, ciò che si vuole produrre e il lavoro
necessario per produrlo.

**Piano di implementazione:**
[`2026-10-19-PIANO_IMPLEMENTAZIONE_DASHBOARD_CONDIVISA.md`](./2026-10-19-PIANO_IMPLEMENTAZIONE_DASHBOARD_CONDIVISA.md)

## Idea centrale

Una Skill mette a disposizione una funzione software. Più Skill possono
essere montate sullo stesso Node e ordinate da una catena produttiva per
costruire un risultato più ampio. 1impegno porta nel tempo il lavoro concreto
delle persone.

La nuova dashboard condivisa usa i modelli esistenti e li presenta nelle aree
che ne sono responsabili. Non introduce un modello `Dashboard`, un nuovo
archivio produttivo o copie dei dati.

```text
Generaimpresa               Rails4Business               1impegno

Brand / progetto            Catena produttiva            Persone e calendario
Node                        NodeProcess                   Commitment
Skill attivate              ricetta e cicli              scadenze ed eventi
       │                            │                          │
       └─────────── produce e pubblica SkillProduct ──────────┘
```

## 1. Le parti da non confondere

### DataCommitment e soggetti dello scambio

Un `DataCommitment` non rappresenta soltanto un task nel calendario. Può
descrivere un'attività, una partecipazione, un accordo, un pagamento o un altro
scambio riferito a una persona.

| Ruolo UI | Campo corrente | Significato |
| --- | --- | --- |
| Proprietario | `profile` | profilo nel cui spazio vive il DataCommitment |
| Creato da | `created_by_profile` | autore del record; informazione di audit |
| Destinatario | `participant_contact` | contatto al quale l'impegno o lo scambio è riferito |
| Responsabile | `responsible_profile` | persona che governa l'esecuzione |
| Assegnatario | `assignee_profile` | persona o calendario a cui il lavoro è assegnato |

Più ruoli possono coincidere, ma restano semanticamente distinti. In
particolare il destinatario non deve essere dedotto dal proprietario o dal
responsabile.

L'export/import deve conservare anche il destinatario. Il servizio attuale
`DataCommitmentTransfer` trasferisce i profili ma non ancora
`participant_contact`: questa lacuna va risolta prima del passaggio completo
develop → production.

### Node

È il Brand, il progetto, il sottoprogetto o il canale sul quale si lavora.
Può avere un Domain, ma non è obbligatorio.

Esempi:

- PosturaCorretta;
- percorso online PosturaCorretta;
- canale YouTube PosturaCorretta.

### Skill

È il supporto software riutilizzabile che permette di gestire un tipo di
prodotto o funzione.

Esempi:

- Contenuti;
- Corsi;
- Percorsi;
- Eventi;
- Luoghi;
- Servizi.

La Skill viene attivata su un Node tramite `ReusableSkillNode`. Attivare la
Skill Contenuti su PosturaCorretta significa dare a quel Brand la possibilità
di creare e pubblicare contenuti.

Una Skill non coincide necessariamente con il risultato finale. È un modulo
che può essere combinato con altri moduli:

```text
Corso online
Contenuti → Media → Corsi → Accessi

Evento
Contenuti → Eventi → Calendario

Formazione
Contenuti → Percorso → Corsi → Lezioni → Calendario
```

L'ordine non deve essere salvato globalmente sulla Skill attivata. Dipende
dal risultato da costruire e vive nella catena produttiva. Le stesse Skill
possono quindi essere montate in ordini differenti su processi differenti.

### SkillProduct

È il prodotto concreto gestito da una Skill attiva su un Node.

Esempi:

- un articolo;
- un video;
- un capitolo di un corso;
- un corso;
- la scheda pubblica di un evento;
- un servizio.

Un prodotto può essere creato direttamente, senza registrare come è stato
realizzato. La produzione tracciata è utile, ma **non è obbligatoria per fare
esistere uno SkillProduct**.

### NodeProcess

È la catena di montaggio, ricetta o algoritmo riutilizzabile.

Non è il prodotto e non è un evento in calendario. Descrive i passaggi che
possono essere ripetuti per produrre nel tempo molti prodotti, usando una o
più Skill attivate sul Brand.

```text
Node: PosturaCorretta
└── Skill attiva: Contenuti
    └── NodeProcess: pubblicare un contenuto educativo
        ├── ciclo 1 → contenuto A
        ├── ciclo 2 → contenuto B
        ├── ciclo 3 → contenuto C
        └── ciclo 4 → ancora da programmare
```

La catena conserva la dima aggiornata. I prodotti già realizzati non cambiano
se in seguito viene migliorata la ricetta.

### ProcessRun — nome proposto al posto di DataExperience

`DataExperience` non descrive abbastanza chiaramente il suo nuovo compito. Il
nome proposto per il modello è `ProcessRun`; nella UI viene mostrato come
**Ciclo di lavoro**.

È un'esecuzione concreta avviata a partire da una catena.

```text
NodeProcess = come produciamo i contenuti
ProcessRun = questa lavorazione concreta
SkillProduct = ciò che rimane ed è utilizzabile o pubblicabile
```

Un ciclo può essere:

- soltanto pensato o programmato;
- avviato e non ancora concluso;
- concluso con un prodotto;
- concluso senza prodotto;
- usato per creare o aggiornare un prodotto già esistente.

Nella forma più semplice, ogni ciclo produce un prodotto principale. Una
catena composta può però utilizzare prodotti già esistenti e generare prodotti
intermedi oltre al risultato finale.

```text
ProcessRun: costruire il capitolo 3
├── usa il testo già esistente
├── genera o aggiorna il video
├── aggiorna il contenuto del capitolo
└── aggiorna l'indice del corso
```

Nel tempo la stessa catena genera molti prodotti attraverso molti cicli.

Il collegamento deve restare facoltativo in entrambe le situazioni importanti:

```text
SkillProduct senza ProcessRun
→ il prodotto esiste, ma il processo produttivo non è stato registrato

ProcessRun senza SkillProduct
→ il lavoro è ancora in corso oppure non ha prodotto un risultato pubblicabile
```

Uno stesso SkillProduct può avere più cicli nel corso della propria vita:

```text
Articolo “Conoscere il corpo”
├── ciclo: prima creazione
├── ciclo: aggiornamento del testo
└── ciclo: correzione dei link
```

## 2. Relazione essenziale

```text
Node
├── ReusableSkillNode 0..n: Skill disponibili sul Brand
│   └── SkillProduct 0..n: prodotti semplici o composti
│
└── NodeProcess 0..n
    ├── ordina l'uso di una o più Skill attive
    ├── NodeProcessStep 1..n
    ├── conserva la ricetta
    └── ProcessRun 0..n
        ├── esegue un ciclo della ricetta
        ├── usa Commitment, Slot e Session
        └── usa, crea o aggiorna SkillProduct
```

`SkillProductLink` collega i prodotti che compongono risultati più ampi. Il
collegamento tra ProcessRun e SkillProduct dovrà distinguere almeno prodotti
usati, prodotti aggiornati e prodotti generati. Il modello preciso verrà
deciso dopo il test del prototipo, senza mantenere l'attuale relazione univoca
tra DataExperience e SkillProduct.

### Esempi di composizione

```text
Contenuto
├── prodotto testuale
└── video collegato prodotto da una seconda catena

Corso
├── Node progetto del corso
├── contenuti indicizzati e ordinati
├── video e materiali
└── avanzamento e accessi

Percorso online
└── più corsi collegati in una progressione

Evento
├── contenuto pubblico che lo presenta
└── una o più date organizzate da 1impegno

Formazione
├── contenuti e percorso
├── corsi
└── lezioni organizzate come eventi con programma
```

## 3. Dima e ciclo non sono la stessa cosa

Nella UI di Rails4Business la versione corrente della ricetta viene chiamata
**Dima attiva**. È un nome più preciso di “Ultimo ciclo”:

- la **Dima attiva** appartiene al `NodeProcess` e descrive come ripetere il lavoro;
- un **Ciclo di lavoro** è una singola esecuzione della dima;
- persone, date, stati e avanzamento del ciclo appartengono a 1impegno;
- una modifica alla dima non riscrive i cicli già conclusi.

La ricetta deve conservare passaggi astratti e ordinati, senza persone, date e
orari obbligatori.

```text
NodeProcess: contenuto settimanale

1. Scegliere il tema
2. Preparare una prima bozza
3. Rivedere il contenuto
4. Preparare immagini o video
5. Programmare la pubblicazione
6. Pubblicare
7. Raccogliere il feedback
```

Quando si apre un ciclo, questi passaggi possono generare il lavoro reale:

```text
Passaggio della dima        Esecuzione in 1impegno

Scegliere il tema       →   DataCommitment, se Mark se ne occupa
Registrare il video     →   DataSlot, se manca ancora l'operatore
Giornata di riprese     →   DataSession con più persone o attività
Pubblicare              →   DataCommitment con data di pubblicazione
```

Per rendere leggibile e stabile questa separazione, il modello minimo da
valutare è `NodeProcessStep`: conserva titolo, descrizione, posizione e tipo di
esecuzione suggerito. Commitment, Slot e Session sono invece le sue eventuali
esecuzioni concrete.

## 4. Le aree di 1impegno

Le tre aree servono soprattutto alla UX. Non è ancora deciso se debbano essere
tre valori rigidi nel database: uno stesso impegno potrebbe cambiare area o
comparire in più viste.

### A. Impegni con scadenza

Attività da completare entro una data oppure da collocare nel calendario.
Possono appartenere a un ciclo produttivo oppure esistere autonomamente.

Esempi:

- rivedere un testo entro venerdì;
- preparare un video;
- pubblicare un contenuto;
- pensare e programmare quale Skill implementare.

### B. Routine e impegni settimanali

Lavoro ricorrente che mantiene in movimento una persona o un progetto.

Esempi:

- un'ora alla settimana per preparare il materiale PosturaCorretta;
- revisione settimanale dei progetti;
- pubblicazione periodica di un contenuto;
- incontro ricorrente del gruppo.

```text
Regola ricorrente
→ genera soltanto le occorrenze necessarie
→ ogni occorrenza diventa Commitment, Slot o Session
→ la singola occorrenza può essere spostata o annullata
```

La ricorrenza non deve creare in anticipo centinaia di record. Conviene
materializzare progressivamente le prossime occorrenze.

### C. Evento singolo

Qualcosa che accade in un giorno e in un orario e che può essere presentato
pubblicamente.

Un evento coinvolge livelli distinti:

```text
Skill Eventi attiva sul Node
└── SkillProduct: scheda pubblica dell'evento
    ├── titolo, descrizione, visibilità e contenuto
    └── DataSession: edizione concreta con data e orari
        ├── DataSlot: posti, ruoli o attività disponibili
        └── DataCommitment: persone che partecipano o lavorano
```

### D. Evento ripetuto

Un evento ripetuto può avere:

- una sola scheda pubblica che descrive il format;
- più DataSession, una per ogni data;
- Commitment e Slot differenti per ogni edizione.

La cadenza può essere:

```text
fissa
→ ogni lunedì alle 18:00
→ ogni primo sabato del mese

variabile
→ più date decise singolarmente
→ nuove edizioni aggiunte quando vengono confermate
```

Il contenuto racconta l'evento; 1impegno organizza quando accade e chi se ne
occupa.

### E. Lavoro da pensare, programmare e creare

Attività ancora da trasformare in un prodotto o in un evento.

Serve per rispondere a domande come:

- che cosa voglio creare?
- per quale Brand o Node?
- quale Skill userò?
- esiste già una catena adatta?
- devo creare un nuovo prodotto o aggiornare quello esistente?
- chi può occuparsene e quando?

```text
Idea o bisogno
→ scelta del Node
→ scelta della Skill
→ prodotto diretto oppure NodeProcess
→ ProcessRun, se voglio tracciare la lavorazione
→ Commitment / Slot / Session
→ SkillProduct finale
```

Questa area viene rappresentata nella dashboard dalla pagina **Tavolo**. Una
voce appena scritta può esistere come Commitment personale in bozza senza data
e senza bloccare il calendario. Soltanto durante lo smistamento si decide se
sia:

- un'attività personale da completare;
- un nuovo progetto o prodotto;
- lavoro necessario per aggiornare un prodotto esistente;
- una Skill da sviluppare;
- un evento con una data;
- un evento ripetuto;
- un'attività da affidare a una catena produttiva.

La tabella di smistamento collega progressivamente:

```text
Voce
→ Che cos'è
→ Brand
→ Progetto / Node
→ Skill
→ Prodotto
→ Responsabile
→ Organizzazione
→ Stato
```

Finché questi dati non sono sufficienti, la voce resta sul Tavolo. Non deve
comparire come una riga vuota nella vista produttiva e non deve generare
automaticamente un Node, uno SkillProduct o un evento.

Prima implementazione (superadmin):

```text
/flowpulse/admin/production?view=table
```

Il record resta un `DataCommitment` in bozza senza data e senza blocco del
calendario. La classificazione vive in `metadata.workbench`; Node, prodotto e
responsabile usano le associazioni reali esistenti. Il passaggio automatico
dallo stato “Pronto da collocare” al sistema proprietario non è ancora attivo.

Questa area non è una raccolta generica di idee: deve aiutare a trasformare
ciò che si vuole fare in lavoro assegnabile e, quando serve, in una catena
ripetibile.

## 5. Esempio completo — contenuti PosturaCorretta

### Preparazione iniziale

```text
Node: PosturaCorretta
→ attivo la Skill Contenuti
→ definisco chi è responsabile dei contenuti
→ creo il NodeProcess “Contenuto educativo PosturaCorretta”
→ preparo i passaggi della ricetta
```

Questa configurazione viene fatta una volta e poi migliorata quando emerge un
modo migliore di lavorare.

### Primo contenuto tracciato

```text
ProcessRun: “I benefici di una postura corretta”
├── Commitment: scegliere il punto centrale
├── Commitment: scrivere la bozza
├── Slot: revisione da assegnare
├── Session: registrazione e immagini
└── Commitment: pubblicare
       ↓
SkillProduct: articolo pubblicato su PosturaCorretta
```

### Contenuto creato senza catena

```text
Creo direttamente lo SkillProduct “Avviso lezioni in arrivo”
→ nessun ProcessRun obbligatorio
→ nessun NodeProcess obbligatorio
→ posso comunque aggiungere un Commitment di pubblicazione
```

### Produzione settimanale

```text
Routine: ogni settimana dedico un'ora alla scelta del contenuto
→ apro o preparo il prossimo ciclo
→ assegno i passaggi necessari
→ pubblico il nuovo SkillProduct
→ il NodeProcess conta un altro ciclo concluso e un altro prodotto
```

### Evento collegato ai contenuti

```text
SkillProduct Contenuto: presentazione dell'incontro
SkillProduct Evento: scheda dell'incontro
DataSession: incontro del 24 ottobre
DataCommitment: Mark presenta
DataSlot: operatore ancora da assegnare
```

I due prodotti possono essere collegati, mentre data, persone e posti restano
gestiti da 1impegno.

## 6. La tabella minima della dashboard

La vista iniziale può essere una tabella con una riga per ogni prodotto sul
quale si sta lavorando, raggruppata per Brand e progetto. L'intestazione ha
due livelli:

```text
┌───────────────────────┬──────────────────────────────┬──────────────────────────────────────────┐
│ Generaimpresa         │ Rails4Business               │ 1impegno                                │
├───────────┬───────────┼──────────────┬───────────────┼────────────┬──────────┬──────────────────┤
│ Progetto  │ Brand     │ Skill        │ Catena        │ Da finire  │ Eventi   │ Eventi ripetuti  │
└───────────┴───────────┴──────────────┴───────────────┴────────────┴──────────┴──────────────────┘
```

| Progetto | Brand | Skill implementate | Catena di montaggio | Impegni da finire | Eventi | Eventi ripetuti |
| --- | --- | --- | --- | --- | --- | --- |
| Contenuti educativi | PosturaCorretta | Contenuti, Media | Contenuto educativo | Revisione venerdì | — | — |
| Corso online | PosturaCorretta | Contenuti, Media, Corsi, Accessi | Costruire un corso | Completare capitolo 3 | — | Fissa: ogni giovedì |
| Eventi sportivi | PosturaCorretta | Contenuti, Eventi, Calendario | Portare PosturaCorretta a un evento | Confermare il materiale | 30 ottobre | — |
| Presentazioni | PosturaCorretta | Contenuti, Eventi, Calendario | Preparare una presentazione | Confermare l'operatore | Prossima: 24 ottobre | Variabile: date confermate singolarmente |

La colonna **Eventi ripetuti** distingue con un'etichetta:

- `Fissa`: segue una regola conosciuta, per esempio ogni giovedì;
- `Variabile`: le date vengono aggiunte e confermate singolarmente.

Nel prototipo aggiornato, gli elenchi completi di impegni ed eventi sono
spostati nella pagina della persona. La vista generale mostra invece
**Persone** e **Ultimo impegno**, così resta leggibile. Cliccando una persona
si apre la sua pagina 1impegno con impegni da finire, eventi ed eventi
ripetuti.

La vista **Settimana** è sempre personale. Mostra insieme, con segni visivi
distinti, gli impegni da fare, gli eventi con data e soltanto le occorrenze
degli eventi ripetuti che ricadono in quella settimana. La regola di
ricorrenza non viene confusa con le singole occorrenze del calendario.

Aprendo una riga si vede il dettaglio completo del prodotto, dei cicli e degli
impegni. In questo modo i tre sistemi restano distinti nel dominio, ma non
obbligano la persona a cambiare continuamente pagina.

La dashboard non viene preceduta da card riepilogative. Una tab permette di
mostrare gli stessi record come `Tabella` oppure come `Elenco` compatto: sono
due rappresentazioni della stessa fonte, non due elenchi indipendenti. Su
smartphone la vista tabellare trasforma inoltre le righe in schede verticali.

## 7. Le quattro domande della dashboard

La dashboard dovrebbe guidare la persona senza mostrarle subito tutti i
modelli:

```text
1. Dove sto lavorando?
   Brand → progetto → Node

2. Che cosa voglio ottenere?
   Skill → nuovo prodotto oppure aggiornamento

3. Come voglio realizzarlo?
   direttamente oppure attraverso una catena e un ciclo

4. Chi fa cosa e quando?
   Commitment → Slot → Session → calendario
```

## 8. Regole già abbastanza chiare

- una Skill è un supporto software, non un processo produttivo;
- uno SkillProduct può esistere senza processo;
- un NodeProcess può produrre molti prodotti attraverso molti cicli;
- la ricetta resta nel NodeProcess, il lavoro reale vive nel ciclo;
- `ProcessRun`, oggi ancora chiamato `DataExperience`, rappresenta il ciclo e
  non il prodotto permanente;
- più Skill possono essere assemblate da un NodeProcess;
- l'ordine delle Skill appartiene alla ricetta e non al Node;
- un ciclo può usare, aggiornare o generare più prodotti;
- Commitment, Slot e Session appartengono a 1impegno;
- 1impegno può essere usato anche senza una catena produttiva;
- un evento pubblico e la sua data concreta non sono la stessa cosa;
- routine, produzione ed eventi possono collaborare senza diventare lo stesso
  modello;
- costi, tempi e quantità verranno calcolati dai cicli reali, non scritti a
  mano quando il dato è già disponibile.

## 9. Questioni da decidere una alla volta

1. La dima del `NodeProcess` richiede `NodeProcessStep` oppure può essere
   rappresentata in modo sufficientemente chiaro dai modelli esistenti?
2. Qual è il collegamento minimo per distinguere prodotti usati, aggiornati e
   generati da un ProcessRun?
3. Come collegare l'esecuzione reale al passaggio della dima?
4. Come rappresentare una routine e una cadenza fissa senza generare troppe
   occorrenze?
5. Quando un evento ripetuto è un unico SkillProduct e quando sono prodotti
   distinti?
6. Quali campi minimi servono per distinguere nella UI routine, produzione e
   evento senza duplicare la fonte di verità?
7. Quale deve essere il primo caso pilota: articolo, video o evento
   PosturaCorretta?

Finché questi punti non vengono confermati, questo documento resta uno schema
di dominio e non autorizza nuove migrazioni.
