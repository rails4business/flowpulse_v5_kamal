# Architettura comune — contenuti, sessioni e servizi

> **Fonte di verità corrente.** Sostituisce per le decisioni future i modelli
> `DataEvent`, `EventFormat`, `Occurrence` e `Slot` precedenti. Non vengono
> reintrodotti modelli soltanto dopo la validazione nella vista. Il
> primo nucleo confermato è `DataExperience → DataSession → DataSlot →
> DataCommitment`, affiancato da `ProfessionalCalendar`, `Service` e
> `BrandProcess`.

Questo è il **documento tecnico principale che tiene le fila dello sviluppo**.
Le nuove decisioni operative vengono prima riportate qui e poi implementate un
passaggio alla volta.

I principi organizzativi, i tre canali e la divisione della settimana sono in
[PRINCIPI_FLOWPULSE_E_ORGANIZZAZIONE_SETTIMANALE.md](PRINCIPI_FLOWPULSE_E_ORGANIZZAZIONE_SETTIMANALE.md).

Le landing, le pagine YAML, i componenti e i Track editoriali sono definiti
separatamente in
[ARCHITETTURA_PAGINE_STATICHE_YML_E_COMPONENTI.md](ARCHITETTURA_PAGINE_STATICHE_YML_E_COMPONENTI.md).

## Scopo

Tutti i brand possono usare la stessa struttura, mantenendo nav, CSS e parole
pubbliche proprie. Durante il pilota la creazione e la modifica di servizi,
processi, Esperienze, Session e Slot sono riservate al `superadmin`. I permessi
di Ideatore, Creator e Operator verranno aperti soltanto dopo casi reali;
Cycle e le regole commerciali avanzate dei Service restano in standby.

Il contenitore comune è `Node`: può essere dichiarato professional anche prima
dell'iscrizione e viene collegato successivamente al profilo tramite
`primary_node_id`; è Brand quando possiede Domain ed è comunque utilizzabile
come progetto. La gerarchia organizzativa usa `parent_node_id`;
la futura responsabilità professionale usa `professional_owner_node_id`, che
può puntare soltanto a un Node professional. Non si aggiungono ora relazioni
anticipate verso Content, Session o Slot.

## I due alberi

```text
EDITORIALE                         OPERATIVO
Percorso                           DataSession
└── Section                        ├── DataCommitment
    └── Corso                      └── DataSlot
        └── Contenuto                  └── DataCommitment
```

L'editoriale risponde a **che cosa si legge, apprende o pratica**. La Session
risponde a **che cosa si svolge e come si colloca una persona**.

Il Week Plan assegna spazi reali della settimana e permette di verificare il
ritmo di lavoro. La struttura e le ricorrenze possono ancora arrivare da YAML;
gli appuntamenti concreti possono ora arrivare dalle DataSession pubbliche del
calendario professionale.

## 0. Week Plan YAML — prototipo in uso

MarkPostura carica un file per settimana da:

```text
config/data/markpostura/settimane/YYYY-Www.yml
```

Ogni voce richiede giorno, ora iniziale, ora finale e uno dei cinque `space`
ammessi dal catalogo MarkPostura. `title` e `location` specificano cosa si fa e
dove; se manca il titolo viene mostrato il nome dello spazio. Questa struttura
resta il livello editoriale facilmente modificabile. La vista unisce le sue
voci alle DataSession presenti nel database senza duplicarle nel file
settimanale.

La vista è un calendario settimanale dalle 08:00 alle 22:00, ispirato al
prototipo `docs/private_prototypes/viste_html/6_weekplan.html`. Non presenta una
lista separata: colloca ogni voce YAML nel giorno e nell'orario corretti. Il
blocco apre un dettaglio in modale senza cambiare pagina.

La pagina dedicata usa parametri condivisibili:

```text
/markpostura/weekplan?week=2026-W38&calendars=postura-gruppo,postura-app
```

`week` identifica il file settimanale; `calendars` contiene uno o più calendari
selezionati. Il vecchio parametro `spaces` resta temporaneamente accettato per
non rompere i link già condivisi. Soltanto il superadmin può aprire la sorgente YAML da
`/admin/markpostura/settimane/YYYY-Www`.

I cinque calendari iniziali sono dichiarati nel registro
`config/professional_calendars.yml` e si importano in modo idempotente con
`bin/rails professional_calendars:import`. Ogni record collega il Node
professionale, qualsiasi Node di contesto, lo slug usato da `calendars=`, l'etichetta e
il colore. Una DataSession può indicare `professional_calendar_id`,
`service_id` facoltativo e `visibility: private | public`. Una Session
pubblica deve avere un calendario; una bozza privata può ancora esserne priva.
Il Week Plan pubblico di MarkPostura legge soltanto le Session pubbliche dei
suoi calendari; il superadmin può vedere anche quelle private.

Calendari, servizi e processi si amministrano nelle rispettive tab dello show
del Node. Il calendario appartiene al professionista e punta al Node preciso
per cui viene usato. Brand e Domain si ricavano risalendo `parent_node_id`
fino al primo antenato dotato di dominio. Un Service appartiene direttamente a
un Node e resta facoltativo sulla Session. Un `BrandProcess` appartiene a un Node e può raccogliere più
`DataExperience`; eliminare il processo conserva le Esperienze scollegandole.

La pagina MarkPostura mantiene due livelli distinti:

- la **settimana pubblica**, filtrabile attraverso le cinque categorie;
- sotto il calendario, soltanto per il superadmin, il **promemoria da
  collocare** e il **programma operativo dettagliato**.

Il programma privato comprende lezioni di gruppo, slot appuntamenti,
pubblicazioni YouTube e piattaforma, capitoli e metodiche, produzione e
scrittura, registrazione con Fabrizio, dirette YouTube Rails4Business,
PosturaCorretta e Giardino del Corpo, camminate, programma salute, musica,
pazienti domiciliari, processi Rails4Business, Colazione Rails4Business,
lettura, eventi, meditazione, spiritualità, conferenze e filosofia. I dati
privati vengono rimossi dal servizio prima del rendering pubblico: non sono
semplicemente nascosti tramite CSS.

Dal **21 settembre 2026** il pilota applica un ritmo settimanale:

- lunedì mattina: pubblicazione della teoria del corso della settimana;
- lunedì 14:00–17:00: scrittura e preparazione privata del materiale della
  settimana successiva;
- mercoledì e venerdì: pratica nelle lezioni di gruppo;
- venerdì pomeriggio: slot per gli appuntamenti individuali.

La regola del pilota è **un corso completo alla settimana e una lezione di
gruppo alla settimana**. I capitoli e le schede appartenenti al corso vengono
svolti dentro quella lezione: non occupano settimane separate. Il calendario
parte da `Inizia con PosturaCorretta`, prosegue con `Postura e Fisiologia` e
con i corsi di recupero, quindi percorre uno alla volta i corsi delle aree
`Muoviti ed esplora`, `Ascolta gli aspetti vitali`, `Nutri il corpo` e `Regola
con le piante officinali`. L'ordine e le date sono conservati in
`config/data/posturacorretta/programmi/calendario_lezioni_gruppo.yml` e
alimentano il Week Plan MarkPostura.

La data è anche un vincolo di pubblicazione: prima dell'inizio della propria
settimana il corso resta visibile come bloccato nella home e nella pagina
Lezioni, e non è apribile neppure tramite URL diretto. La pagina pubblica
`/posturacorretta/lezioni` elenca inoltre i professionisti che hanno attivato
il programma con giorno, orario e luogo; il primo pilota è MarkPostura.

Prima della data si mostrano i titoli e le date di uscita, ma nessuno — incluso
il superadmin — può aprire gli show futuri. L'unica eccezione esplicita è il
primo capitolo marcato `demo: true`; alla data del corso si sbloccano insieme
tutti i suoi capitoli.

Ogni settimana MarkPostura prevede tre elementi distinti: la lezione di gruppo
pubblica, uno slot privato di correzione e pubblicazione e una diretta YouTube
pubblica. La diretta viene generata nel Week Plan soltanto quando giorno e
orario sono compilati nel calendario YAML, per evitare appuntamenti fittizi.

## 1. Albero editoriale e Creator

```text
Percorso → Section → Corso → Capitolo
```

- **Percorso**: file YAML e pagina indice della home; ordina le section e i
  corsi di un Brand.
- **Section**: raggruppamento editoriale di corsi coerenti.
- **Corso**: contenuto padre, con `format: course` o `format: masterclass`.
- **Contenuto**: unità editoriale con un formato: `course`, `masterclass`,
  `chapter`, `article`, `video`, `exercise`. Una scheda pratica inserita in un
  corso usa `format: chapter`.

Non esiste il livello editoriale “approfondimento isolato”. Nel pilot pubblico
la gerarchia è soltanto **Corso → Capitolo** e ciascuno dichiara autonomamente
`access: free | paid`. Un corso libero può quindi contenere in futuro un
capitolo a pagamento e viceversa, purché la pagina renda sempre visibile la
condizione prima dell'apertura. Prezzo, acquisto e abilitazione dell'accesso
saranno introdotti dopo aver definito Service e pagamenti; fino ad allora i
contenuti pilota restano `free`.

Un capitolo è un'unità unica: non viene spezzato internamente in una parte base
e in un “approfondimento avanzato”. Se una parte richiede un accesso differente,
deve diventare un altro capitolo con la propria `content_key` e il proprio
valore `access`.

Nel primo pilota `course` e `chapter` sono voci dello stesso albero editoriale
descritto dai file: il corso non ha padre e ogni capitolo usa `parent_id` verso
il corso. Non si crea ancora una tabella `contents`.
Le schede pratiche non costituiscono una struttura o una tab separata: quando
fanno parte di un corso sono normali capitoli, descritti dal titolo e dal loro
contenuto. La sorgente YAML pilota è
`config/data/posturacorretta/contenuti/contents.yml`.

Un capitolo può essere teorico o pratico. Gli esercizi semplici restano nel
corpo del capitolo; diventano contenuti autonomi solo se riusabili o dotati di
istruzioni, video o varianti proprie.

Ogni contenuto ha un solo padre strutturale e ne eredita Brand e visibilità. Un
figlio può essere più ristretto, mai più pubblico. Per riusare un contenuto si
crea un **ponte** figlio del nuovo corso, con `link_content_id` verso
l'originale; il ponte non ha figli e non può ampliare la visibilità.

La funzione Contenuti è attivabile per Brand e affidata al ruolo `creator` nel
contesto di quel Brand. Il catalogo pubblico mostra contenuti datati, corsi e
masterclass; il Percorso resta invece l'indice YAML ordinato della home.

Course e Chapter possono dichiarare `published_at`. Prima di quella data non
appaiono nel Percorso e non sono apribili dal pubblico; il superadmin può
vederli e revisionarli in anteprima. La pubblicazione non dipende da CSS o
JavaScript, ma dal repository che filtra i dati prima del rendering.

Il precedente corso **PosturaCorretta in un mese** è stato trasformato in libro
pubblicato. Il suo indice si trova in
`config/data/brands/posturacorretta/books/postura-corretta-in-un-mese/index.yml`
e i suoi capitoli vivono nella stessa cartella del Brand, senza duplicare i
testi. Il nuovo corso
breve **Inizia con PosturaCorretta** resta invece il primo pilota dell'albero
`Content course → chapter`.

### Sorgenti e futura gestione dall'app

La fase corrente usa:

- file Markdown per articoli, capitoli e schede; i video sono metadati/media
  del rispettivo file e non una categoria autonoma;
- `course.yml` o il catalogo equivalente per ordinare i capitoli;
- `percorso.yml` per ordinare Section e corsi;
- una `content_key` stabile per ogni contenuto.

Esempio:

```yaml
content_key: benefici-postura-corretta
source: brands/posturacorretta/books/postura-corretta-in-un-mese/chapters/benefici-postura-corretta.md
```

La prima interfaccia editoriale dell'app dovrà poter creare titolo, formato,
Brand, stato e data; modificare Markdown; salvare il file in modo controllato;
aggiornare gli indici YAML e mostrare un'anteprima. In seguito aggiungerà
ordinamento dei capitoli, composizione del Percorso, collegamento a DataSession,
creazione di Slot e Commitment editoriali e proposta al responsabile per
l'approvazione pubblica. La chiave stabile permetterà di migrare eventualmente
al database senza rompere i collegamenti esistenti.

## 2. DataSession e DataSlot — primo nucleo di 1Impegno

### Programma lezioni PosturaCorretta — pilot precedente ai model

Prima di creare DataSession e DataSlot nel database, il programma didattico
stabile viene provato in:

```text
config/data/posturacorretta/programmi/programma_lezioni_posturacorretta.yml
```

Il file non stabilisce se una lezione sarà individuale o di gruppo e non
contiene date: per ogni lezione conserva soltanto numero, titolo, descrizione,
riferimento al capitolo teorico e riferimenti alle schede pratiche, che
diventeranno capitoli con `content_key` stabile. Modalità individuale/gruppo,
data, luogo e operatori appartengono alla futura DataSession reale. Il pilot
contiene 34 lezioni: le prime seguono il programma introduttivo già definito e
le successive usano il titolo composto `Corso · Capitolo`. Ogni lezione espone
un elenco `practical_chapters`, inizialmente anche vuoto, che permette di
aggiungere progressivamente una o più schede senza cambiare struttura.

Nel **Programma lezioni ogni voce mostrata è una scheda pratica**. La regola è
dichiarata una volta con `sheet_type: practical`. Il corso editoriale conserva
invece sia capitoli teorici sia capitoli pratici: il programma può richiamare il
capitolo pertinente, ma lo presenta sempre come materiale operativo della
lezione. Quando una scheda avrà un contenuto autonomo, userà una propria
`content_key` senza eliminare il capitolo teorico collegato.

Restano separati e saranno modellati in seguito nei file MarkPostura:

- date delle lezioni di gruppo;
- slot dei trattamenti individuali;
- calendario di registrazione con il video maker;
- calendario di pubblicazione YouTube, distinguendo presentazione delle
  metodiche e implementazione di capitoli/schede;
- Colazioni Rails4Business;
- camminate in montagna;
- lezioni di musica;
- letture e meditazioni.

Il programma didattico può diventare una dima `DataCycle` con `mode: template`.
Le date reali generano un `DataCycle` con `mode: instance`; le schede della
lezione sono DataSlot collegati ai rispettivi contenuti.

```text
Cycle
├── DataCommitment
└── DataSession
    ├── DataCommitment
    └── DataSlot
        └── DataCommitment
```

### Regola fondamentale di DataCommitment

`DataCommitment` registra l'impegno di una persona. Quando l'impegno nasce da
un processo organizzato appartiene a una `DataActivity` e può conservare il
ramo completo `DataCycle → DataSession → DataSlot`. Il livello operativo è il
collegamento più specifico presente: Slot, altrimenti Session, altrimenti Cycle.

- sul **Cycle** descrive un impegno valido per l'intero processo: coordinare un
  corso, produrre una serie di video o seguire tutto il percorso di una persona;
- sulla **DataSession** descrive un impegno relativo a un incontro o a un'uscita
  editoriale: condurre una masterclass, pubblicare un articolo, registrare una
  lezione o partecipare a un incontro;
- sul **DataSlot** descrive una parte precisa: preparare una scheda, revisionare
  un capitolo, condurre la pratica o gestire una singola prenotazione.

Un'attività svolta in autonomia può invece esistere senza Cycle, DataSession o
DataSlot: per esempio leggere un capitolo, completare una scheda o vedere un
video per conto proprio. Questo caso dovrà essere dichiarato esplicitamente
come `kind: self_directed` e collegato al contenuto tramite `content_key`; non
va creata una Session artificiale soltanto per registrare l'avanzamento.

DataActivity, DataCycle, DataSession e DataSlot sono una proposta da validare
prima con una vista/YAML. Nessuna migrazione di questa gerarchia è mantenuta
finché non avremo verificato casi reali e vocabolario.

Uno Slot è una posizione dentro una Session, non un task per definizione:

- **slot contenuto**: link a scheda, capitolo, video o esercizio;
- **slot prenotazione**: appuntamento di un Contact/User;
- **slot operativo**: preparazione, coordinamento o chiusura;
- **slot task**: azione assegnata o tracciata, soltanto quando serve davvero.

Una Session di gruppo contiene più DataCommitment partecipanti e uno o più
slot contenuto. Una Session individuale seriale ha slot prenotazione in orari
successivi. Una Session individuale parallela potrà avere slot contemporanei
solo quando esistono operatori e risorse sufficienti.

La Session può essere mostrata al pubblico come lezione, incontro,
appuntamento o evento. Non serve un modello tecnico `Event` separato.

### Esempio: pubblicazione di un articolo

```text
DataSession
kind: editorial_release
title: Pubblicazione “I benefici di una postura corretta”
content_key: benefici-postura-corretta
starts_at: data di pubblicazione

├── DataSlot: scrittura
│   └── DataCommitment del creator
├── DataSlot: revisione
│   └── DataCommitment del responsabile
└── DataSlot: pubblicazione
    └── DataCommitment del creator
```

Nel caso semplice gli Slot non sono obbligatori:

```text
DataSession: pubblicazione articolo
└── DataCommitment: scrivere e pubblicare
```

### Esempio: masterclass

```text
DataSession: Masterclass dal vivo
├── DataSlot: introduzione
├── DataSlot: lezione
├── DataSlot: pratica
└── DataSlot: conclusione
```

I professionisti che conducono e i partecipanti iscritti hanno Commitment
sulla Session. Creator del materiale, operatori delle singole parti e
responsabili della revisione possono avere Commitment sugli Slot.

### Ipotesi di schema database — da validare

Quando verrà implementata, `data_commitments` potrà usare chiavi esterne
esplicite:

```text
data_activity_id
data_cycle_id
data_session_id
data_slot_id
content_key
```

Slot, Session e Cycle possono essere memorizzati insieme per mantenere il
contesto completo e interrogabile. Le validazioni verificano che appartengano
alla stessa DataActivity. Per `kind: self_directed` il ramo può essere vuoto e
`content_key` identifica il capitolo o contenuto svolto. Le chiavi esplicite
restano preferibili a un'associazione polimorfica perché mantengono foreign key
reali e controllabili. Il futuro `service_id` sarà opzionale e non sostituirà
il collegamento strutturale.

### Avanzamento utente: tre usi di DataCommitment

`DataCommitment` non serve soltanto per prenotare: è il registro personale di
ciò che una persona ha scelto, svolto o completato.

1. **Contenuto online svolto in autonomia**

   ```text
   kind: self_directed
   content_key: corso/capitolo o scheda
   data_cycle_id, data_session_id, data_slot_id: vuoti
   status: completed
   ```

   Permette all'utente di marcare un capitolo letto, una scheda praticata o un
   video visto. Non inventa una Session fittizia.

2. **Lezione con insegnante prenotata o svolta**

   ```text
   data_session_id: lezione singola o gruppo
   profile/contact: partecipante
   status: requested | confirmed | completed | cancelled
   ```

   Nella sua area l'utente vede prossime lezioni, storico, insegnante, sede e
   avanzamento del Programma lezioni. Un eventuale DataSlot identifica una
   parte specifica o una prenotazione individuale dentro una Session.

3. **Tirocinio insegnante**

   ```text
   data_session_id oppure data_slot_id
   role: trainee
   status: completed | approved
   evidence/notes: da definire
   ```

   Il tirocinante vede soltanto le attività richieste dal proprio scaglione:
   presenze, affiancamenti, compresenze e autorizzazioni. L'abilitazione non
   deriva dalla sola spunta dell'utente: richiede la conferma dell'insegnante
   responsabile.

## 3. Permessi del pilota e futuro Operator

Nel pilota soltanto il `superadmin` può creare o modificare
`ProfessionalCalendar`, `Service`, `BrandProcess`, `DataExperience`,
`DataSession` e `DataSlot`. Le pagine
pubbliche hanno accesso esclusivamente alle DataSession con `visibility:
public`. Il ruolo `operator` non riceve ancora permessi operativi.

La matrice futura, ancora da verificare, distingue:

- **Ideatore**: governa servizi e processi del proprio Node;
- **Creator**: propone Session editoriali e lavora sui contenuti assegnati;
- **Operator**: organizza o conduce Session operative autorizzate;
- **Utente**: visualizza, richiede o partecipa tramite DataCommitment.

### Operator e funzione nel Brand

`operator` abilita una persona a lavorare in Impegno nel contesto di un Brand.
`role_operator` ne definisce la funzione concreta.

```text
RoleAssignment
role: operator
role_operator: insegnante | professionista | segreteria | ...
context: Node del Brand
parent: ideatore del Brand
```

Ogni Brand possiede `operator_roles`, la propria lista di funzioni. Assigned
roles deve far scegliere: Brand → utente → operator → role_operator.
La stessa persona può avere più funzioni nello stesso Brand; l'unicità deve
includere `role_operator`.

In seguito si potranno aggiungere tutor, segreteria, responsabile del luogo e
altri operatori come assegnazioni multiple. Non vengono anticipati ora campi o
permessi specifici.

## 3.1 1Impegno: motore comune, non un Brand

La struttura `DataSession → DataSlot → DataCommitment` è il nucleo operativo
di **1Impegno**. Non appartiene a PosturaCorretta: ogni Brand, Project o
professionista la può usare per pianificare e tracciare il proprio lavoro.

`ProfessionalCalendar` organizza le Session nel tempo di un professionista e
nel contesto esatto di un Node, che può essere Brand, Project o nodo interno.
`Service` descrive facoltativamente ciò che quel Node offre. Non è un calendario
e non è un quarto livello della gerarchia. `DataExperience`
rimane il contenitore operativo, mentre `BrandProcess` descrive il processo
ripetibile a cui un'Esperienza può appartenere.

```text
Node professionale
└── ProfessionalCalendar  # calendario del professionista per un Node
    └── DataSession       # occorrenza concreta
        ├── DataCommitment
        └── DataSlot
            └── DataCommitment

Node
├── Service               # offerta facoltativa collegata alla Session
└── BrandProcess          # processo organizzativo ripetibile
    └── DataExperience    # applicazione concreta del processo
```

Regole di contesto:

- un **Brand** può avere un dominio, ma non è obbligatorio per usare
  Session/Slot/Commitment;
- un **Project** è un Node senza dominio e usa esattamente lo stesso flusso;
- un **professionista** può avere un Node professionale proprio, con o senza
  dominio. `markpostura` è un esempio: può creare attività personali o
  lavorare come operatore per PosturaCorretta;
- se una persona non ha ancora un Node professionale, l'attività resta privata
  con `created_by_user`; quando verrà creato il Node personale potrà diventare
  il `context_node`, senza cambiare gli impegni già registrati.

Esempi:

```text
Lezione di gruppo PosturaCorretta
creator_node: markpostura
content_owner_node: posturacorretta
responsible_operator: insegnante
content_key: corso/igiene-posturale/capitolo/punti-di-tensione

Video di MarkPostura
creator_node: markpostura (Node professionale)
responsible_operator: creator
content_key: contenuto editoriale di MarkPostura

Sessione privata di un nuovo professionista
creator_node: assente inizialmente
created_by_user: utente proprietario
visibility: private
```

Se verrà confermato, `DataCycle` terrà insieme più Session. Una dima potrà
essere un altro `DataCycle` con `mode: template`; un ciclo reale userà
`mode: instance` e potrà indicare `template_cycle_id`. Del Service sono ora
presenti soltanto identità e appartenenza; prezzo, capienza, luogo, ruoli e
regole di partecipazione restano futuri.

## 3.2 Basi comuni: Impegno, calendari, servizi, contenuto e Node

`ProfessionalCalendar` non sostituisce `Node`: collega il calendario di un
professionista al Node preciso per cui viene usato. Il Node continua a
rappresentare Brand, progetto o professionista. Il relativo Brand/sito viene
ricavato automaticamente dal primo antenato con Domain. `Service` descrive
invece un'offerta facoltativa appartenente esattamente a un Node.

```text
1Impegno (motore operativo comune)
  DataSession → DataSlot → DataCommitment

ProfessionalCalendar
  appartiene a un Node professionale e punta a un context Node
  colloca una DataSession nel Week Plan del professionista

Service
  appartiene a un Node
  descrive facoltativamente l'offerta associata a una DataSession

Contenuto (editoriale)
  Markdown + YAML oggi; content_key stabile per i legami futuri

Brand (Node organizzativo/editoriale)
  può avere domini, contenuti, operatori, servizi e attività figlie
```

### Ruoli delle basi

| Base | Responsabilità | Esempio |
| --- | --- | --- |
| **1Impegno** | Organizza ciò che accade, le sue parti e chi è coinvolto. | Lezione, video, riunione, pubblicazione. |
| **ProfessionalCalendar** | Colloca la Session nel calendario del professionista per uno specifico Node. | PosturaCorretta · Gruppo, progetto YouTube · Produzione. |
| **Service** | Descrive facoltativamente ciò che il Node offre attraverso la Session. | Lezione individuale, gruppo, masterclass. |
| **Node professionale** | Identifica il professionista proprietario dei suoi calendari. | MarkPostura. |
| **Contenuto** | È il materiale editoriale leggibile o guardabile. | Capitolo, scheda, articolo, video associato. |
| **Brand** | È il contesto organizzativo e di pubblicazione; il dominio è soltanto una sua possibile porta d'ingresso. | PosturaCorretta, Percorso Integrato, Il Giardino del Corpo. |

Un professionista può avere un proprio Node anche senza dominio. Quando il
Node è il suo riferimento può essere `professional`; quando pubblica o
organizza per un Brand o un suo Project, la DataSession collega il
`ProfessionalCalendar` e può aggiungere un `Service`, senza duplicare persone
o contenuti.

**MarkPostura** è l'esempio: è il Node professionale principale di Mark; può
avere o non avere un dominio e coordina le attività personali. I contenuti o le
lezioni pubblicati per PosturaCorretta restano del Brand PosturaCorretta, ma
possono dichiarare MarkPostura come autore, creatore o operatore responsabile.

`Cycle` resta un livello successivo e raggruppa più Session. Il Service minimo
è già presente; le sue regole commerciali e di partecipazione verranno
aggiunte dopo la validazione del pilota. Non sostituisce né un Contenuto né un
Node.

## Base comune di 1Impegno e dei Brand

La struttura minima di **1Impegno** è comune e non contiene parole specifiche
di PosturaCorretta:

```text
DataSession  → cosa succede e quando
DataSlot     → parte opzionale della Session
DataCommitment → chi partecipa, svolge o completa un'azione
```

PosturaCorretta la userà per lezioni, schede, presenze e tirocinio; Percorso
Integrato per appuntamenti e percorsi personali; Il Giardino del Corpo per
eventi e attività; Rails4Business per riunioni, produzioni e pubblicazioni.

Ogni record dovrà avere un contesto `brand/node` ereditato dalla Session, senza
duplicare modelli diversi per ogni progetto. Il Brand decide soltanto le
etichette, i ruoli operativi consentiti e quali Session rendere pubbliche.
Così 1Impegno resta lo strumento operativo condiviso e i Brand restano liberi
di presentare la stessa struttura nel loro linguaggio.

## 4. Catalogo e calendario pubblico

La pagina pubblica unica è **Contenuti ed eventi**, con filtri prossimi/passati:

- contenuti, corsi e masterclass usano la data editoriale;
- una DataSession pubblicata e datata appare come evento;
- bozze, contenuti privati e Session private restano a superadmin e addetti.

Un contenuto non è mai un evento. Una Session usa contenuti tramite i suoi
slot e può essere presentata come evento quando è pubblica e datata.

La pubblicazione nel calendario appartiene soprattutto alla DataSession:

```text
starts_at
visibility
approval_status
public_calendar
```

Il Commitment stabilisce chi deve svolgere l'azione; la Session stabilisce che
cosa accade, quando accade e quando diventa visibile. Il calendario personale
può mostrare subito il lavoro interno, mentre quello pubblico del Brand richiede
l'approvazione del responsabile.

### DataCommitment: significato operativo unico

`DataCommitment` non significa solo prenotazione. Esprime il rapporto fra una
persona e un'azione concreta: **partecipazione, attività autonoma o incarico**.

| Caso | Session / Slot | DataCommitment |
| --- | --- | --- |
| Capitolo online letto o completato | Non obbligatorio | `kind: self_directed`, persona + `content_key` + stato/completato il |
| Lezione con insegnante prenotata | DataSession della lezione | partecipante + stato richiesta/confermata/svolta |
| Parte di una lezione | DataSlot, se serve distinguere una fase | insegnante, partecipante o operatore assegnato a quella parte |
| Tirocinio insegnante | Session o Slot della pratica assistita | tirocinante + attività svolta + conferma del supervisore |
| Articolo/video editoriale | DataSession della pubblicazione; Slot opzionali scrittura/revisione/pubblicazione | creator, revisore o responsabile con il proprio incarico |

Questa regola permette alla pagina personale di mostrare nello stesso posto:

- capitoli online avanzati in autonomia;
- lezioni con insegnante richieste, prenotate e svolte;
- tirocinio completato e, in futuro, validato dal supervisore.

`DataCommitment` non sostituisce la data editoriale: la data della pubblicazione
appartiene alla DataSession. I Commitment editoriali indicano invece chi ha
scritto, revisionato o pubblicato e con quale stato.

Per il futuro profilo utente serviranno almeno un'iscrizione al Brand e una
vista personale che raggruppa i Commitment per **online**, **lezioni con
insegnante** e **formazione insegnante**. Per il tirocinio sarà necessario
aggiungere una conferma del supervisore (`verified_by`, `verified_at`) prima di
calcolare un'abilitazione.

### 1Impegno: nucleo comune e contesti

`DataSession → DataSlot → DataCommitment` è il nucleo operativo di **1Impegno**
e deve poter essere usato da tutti i Brand, non soltanto da PosturaCorretta.
1Impegno è la vista e lo strumento che organizza il lavoro; non è il
proprietario editoriale o commerciale dell'attività.

```text
Attività di un Brand / professionista / utente
        │
        ├── DataSession  cosa accade e quando
        │     ├── DataSlot  parti eventuali
        │     │     └── DataCommitment  chi fa/partecipa
        │     └── DataCommitment  partecipazione o incarico sulla Session
        │
        ├── contenuto collegato (opzionale, oggi content_key)
        └── Brand/Node collegato (opzionale secondo il contesto)
```

Ogni Session dovrà distinguere quattro riferimenti, senza trasformarli subito
in quattro modelli rigidi:

| Riferimento | Funzione |
| --- | --- |
| `owner_profile_id` | Chi crea e gestisce l'attività: MarkPostura, un altro professionista o un utente normale. È il riferimento sempre presente. |
| `node_id` | Brand, progetto o nodo professionale nel cui contesto si svolge. È facoltativo: un utente senza dominio può avere un'attività personale. |
| `content_key` | Articolo, capitolo, scheda o video collegato alla Session. È facoltativo e oggi punta ai file Markdown/YAML. |
| `brand/domain` derivato dal Node | Serve per calendario, tema, permessi e pubblicazione; non va duplicato se il Node lo determina già. |

Esempi:

- **Lezione PosturaCorretta**: owner Mark, Node PosturaCorretta, Session
  pubblica; insegnante e partecipanti sono Commitment.
- **Video di MarkPostura**: owner Mark, Node MarkPostura o progetto YouTube,
  `content_key` dell'articolo/video; Slot scrittura, registrazione e
  pubblicazione.
- **Impegno personale di un utente senza dominio**: owner dell'utente, senza
  Node, visibilità privata; può avere Slot e Commitment personali.
- **Articolo per Rails4Business**: owner creator, Node Rails4Business,
  `content_key` dell'articolo; la Session reca la data editoriale pubblica.

`Cycle` e `Service` verranno sopra questo nucleo solo dopo il pilota: Cycle
raggruppa Session ripetibili; Service aggiunge prezzo, capienza e regole di
accesso. Non sono necessari per iniziare a usare 1Impegno.

## 5. Cycle e Service

**DataCycle** è un'ipotesi per l'insieme reale di Session, ad esempio un gruppo
di quattro lezioni, una formazione insegnanti o una produzione video. Una dima
potrà usare lo stesso modello con `mode: template`.

**Service** sarà la configurazione commerciale/organizzativa: prezzo,
capienza, luogo/online, operatori e prenotazione. Un prezzo su un contenuto
online non crea automaticamente un Service. Il Service verrà valutato solo
dopo Cycle e casi reali di partecipazione.

Service potrà avere come target Cycle, DataSession oppure DataSlot e dichiarare
prezzo, capienza, ruoli richiesti, modalità di partecipazione e luogo/online.
Applicato al Cycle potrà valere per tutto il ramo, salvo configurazioni più
specifiche su Session o Slot.

DataCycle descriverà anche i processi Rails4Business
applicati a un Brand: per esempio la produzione dei contenuti PosturaCorretta.
Il responsabile del processo e il responsabile editoriale del Brand possono
coincidere nella fase pilota, ma restano concetti distinti.

## Piano di lavoro — viste/YAML prima del database

1. **Operator — completato**: aggiunti `operator`, `role_operator` e
   `operator_roles` al Brand e aggiornati gli Assigned roles.
2. **Programma lezioni PosturaCorretta — completato come struttura YAML**:
   `programma_lezioni_posturacorretta.yml` è l'ordine didattico unico, valido
   sia per lezioni individuali sia per lezioni di gruppo. Ogni riga è una
   lezione e, dopo le due introduzioni, corrisponde a un capitolo/scheda.
   Le sezioni visibili raggruppano le lezioni per corso; il tirocinio resta
   riservato ai tirocinanti e abilita progressivamente a condurre le lezioni.
   Le date effettive restano nel file separato
   `calendario_lezioni_gruppo.yml`.
3. **MarkPostura e Week Plan — subito dopo**: completare le cose già annotate
   per MarkPostura e usare i file settimanali YAML per correggere le cinque
   categorie, i luoghi e gli orari su casi reali. Il Week Plan mostra le sole
   voci pubbliche; rimane però il riferimento temporale con cui in seguito si
   incastreranno lezioni, appuntamenti e lavoro editoriale.
4. **Creator e contenuti — pilota in corso**: provare un unico albero Content
   con `course → chapter` tramite `parent_id`, senza distinguere le schede dai
   capitoli.
5. **Percorso PosturaCorretta**: completare `percorso.yml` con Section e
   riferimenti `content_id` ai corsi, come indice ordinato della home.
6. **Pilota 1Impegno — implementato localmente**: la prima single page usa
   esclusivamente `DataExperience → DataSession → DataSlot → DataCommitment`.
   Esperienza ha nome, descrizione e creatore; Session e Slot hanno nome e
   ordine; DataCommitment appartiene per ora soltanto a uno Slot e mostra nome
   più stato `planned/completed`. La pagina consente aggiunta e modifica inline
   tramite Turbo/Stimulus. Restano fuori date, Brand, contenuti, ruoli, luoghi,
   Service, pagamenti e prenotazioni.
7. **Dima**: valutare se una dima debba essere un Cycle `mode: template` o una
   struttura YAML separata, dopo avere provato la vista.
8. **Catalogo pubblico**: una vista datata Contenuti ed eventi con
   prossimi/passati, visibilità pubblica e privata.
9. **Test reale**: usare YAML e correggere il vocabolario.
10. **Solo dopo**: scegliere schema database, modelli, controller e migrazioni.

## Piano pilota PosturaCorretta — ordine confermato

1. **Completare solo le migrazioni editoriali necessarie al pilota**: corsi,
   capitoli/schede, Programma lezioni e contenuti pubblici imminenti. Lo
   storico rimane censito e si migra in seguito, senza bloccare l'avvio.
2. **Prototipo YAML DataSession → DataSlot → DataCommitment** su tre casi
   reali: lezione singola, gruppo settimanale e pubblicazione editoriale.
3. **Calendari**: il Week Plan di MarkPostura resta il riferimento della
   disponibilità; il calendario del Brand mostra soltanto lezioni e contenuti
   pubblicati.
4. **Tariffe in YAML, senza checkout**: lezione singola, gruppo settimanale e
   pacchetto di quattro lezioni di Igiene Posturale. Il gruppo settimanale è
   una DataSession pubblicata di settimana in settimana, non un abbonamento
   imposto dalla struttura tecnica.
5. **Dopo il test reale**: prenotazione, capienza, conferma e pagamento.
6. **Formazione insegnanti**: per ora candidatura/invito e registro di
   presenze, tirocinio e abilitazioni; non vendere un diploma prima che il
   registro sia verificabile.
7. **Area personale**: dopo il prototipo, mostrare a ogni utente contenuti
   completati, prossime lezioni con insegnante e avanzamento; per i tirocinanti
   aggiungere il registro verificato del tirocinio.

### Confini commerciali dei Brand

- **PosturaCorretta**: persone, Percorso educativo online, lezioni e
  insegnanti.
- **Percorso Integrato**: professionisti e percorsi personali.
- **Il Giardino del Corpo**: eventi e comunità.

## Decisioni ancora aperte

- formato YAML esatto dei ponti e dei riferimenti DataSlot → Contenuto;
- campi minimi della single page DataSession/DataSlot;
- regole definitive per Session di gruppo, seriali e parallele;
- quando una Session datata genera o aggiorna un DataCommitment;
- campi del futuro Cycle e Service, dopo il pilota.
