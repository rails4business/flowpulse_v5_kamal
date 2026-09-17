# Architettura comune — contenuti, sessioni e servizi

> **Fonte di verità corrente.** Sostituisce per le decisioni future i modelli
> `DataEvent`, `EventFormat`, `Occurrence` e `Slot` precedenti. Non vengono
> create nuove tabelle finché YAML e viste non sono stati usati davvero.

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
pubbliche proprie. Per ora si sviluppano solo due funzioni: contenuti gestiti
dai Creator e Session/Slot gestiti dagli Operator. Cycle e Service restano in
standby.

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

Il Week Plan viene prima dei due alberi: assegna spazi reali della settimana e
permette di verificare il ritmo di lavoro. Non è ancora una DataSession e non è
un contenuto, ma prepara il luogo in cui entrambi potranno essere programmati.

## 0. Week Plan YAML — prototipo in uso

MarkPostura carica un file per settimana da:

```text
config/data/markpostura/settimane/YYYY-Www.yml
```

Ogni voce richiede giorno, ora iniziale, ora finale e uno dei cinque `space`
ammessi dal catalogo MarkPostura. `title` e `location` specificano cosa si fa e
dove; se manca il titolo viene mostrato il nome dello spazio. Questa struttura
resta distinta dal futuro database di 1Impegno.

La vista è un calendario settimanale dalle 08:00 alle 22:00, ispirato al
prototipo `docs/private_prototypes/viste_html/6_weekplan.html`. Non presenta una
lista separata: colloca ogni voce YAML nel giorno e nell'orario corretti. Il
blocco apre un dettaglio in modale senza cambiare pagina.

La pagina dedicata usa parametri condivisibili:

```text
/markpostura/weekplan?week=2026-W38&spaces=postura-gruppo,postura-app
```

`week` identifica il file settimanale; `spaces` contiene una o più delle cinque
categorie selezionate. Soltanto il superadmin può aprire la sorgente YAML da
`/admin/markpostura/settimane/YYYY-Www`.

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
`config/data/books/postura-corretta-in-un-mese/index.yml` e riusa i Markdown
esistenti tramite riferimenti `source`, senza duplicare i testi. Il nuovo corso
breve **Inizia con PosturaCorretta** resta invece il primo pilota dell'albero
`Content course → chapter`.

### Sorgenti e futura gestione dall'app

La fase corrente usa:

- file Markdown per articoli, capitoli, video descritti e schede;
- `course.yml` o il catalogo equivalente per ordinare i capitoli;
- `percorso.yml` per ordinare Section e corsi;
- una `content_key` stabile per ogni contenuto.

Esempio:

```yaml
content_key: benefici-postura-corretta
source: guide/01_primo_mese/02_benefici.md
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

Il programma didattico diventerà in seguito la dima di un Cycle. Le date reali
genereranno o istanzieranno DataSession; le schede della lezione saranno
DataSlot collegati ai rispettivi contenuti.

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
un processo organizzato deve appartenere a **uno e uno solo** fra `Cycle`,
`DataSession` e `DataSlot`.

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

Nel primo prototipo Cycle resta in standby. I Commitment operativi o di
partecipazione saranno quindi collegati a DataSession oppure DataSlot; quelli
autonomi verranno affrontati successivamente insieme a login, iscrizione al
Domain e avanzamento dei capitoli.

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

### Schema database raccomandato, non ancora da migrare

Quando passeremo al database, `data_commitments` avrà chiavi esterne esplicite:

```text
cycle_id
data_session_id
data_slot_id
service_id
```

Per i Commitment operativi o di partecipazione, un vincolo dovrà imporre che
sia presente esattamente una fra `cycle_id`, `data_session_id` e
`data_slot_id`. Per `kind: self_directed` le tre chiavi potranno invece essere
vuote, mentre `content_key` sarà obbligatoria. La validazione deve anche
impedire di usare `self_directed` per aggirare il collegamento strutturale di un
impegno organizzato. Le chiavi esplicite restano preferibili a un'associazione
polimorfica perché mantengono foreign key reali e controllabili. `service_id`
sarà opzionale e non sostituirà il collegamento strutturale.

## 3. Operator e funzione nel Brand

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

Per il primo prototipo ogni DataSession/DataSlot ha un operatore responsabile e
eredita il Brand. In seguito si potranno aggiungere tutor, segreteria,
responsabile del luogo e altri operatori come assegnazioni multiple.

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

## 5. Cycle e Service — esplicitamente in standby

**Cycle** sarà una dima composta da Session e Slot, ad esempio un corso di
quattro lezioni, una formazione insegnanti o una produzione video. Si valuta
solo dopo il test delle Session YAML.

**Service** sarà la configurazione commerciale/organizzativa: prezzo,
capienza, luogo/online, operatori e prenotazione. Un prezzo su un contenuto
online non crea automaticamente un Service. Il Service verrà valutato solo
dopo Cycle e casi reali di partecipazione.

Service potrà avere come target Cycle, DataSession oppure DataSlot e dichiarare
prezzo, capienza, ruoli richiesti, modalità di partecipazione e luogo/online.
Applicato al Cycle potrà valere per tutto il ramo, salvo configurazioni più
specifiche su Session o Slot.

Quando verrà introdotto, Cycle descriverà anche i processi Rails4Business
applicati a un Brand: per esempio la produzione dei contenuti PosturaCorretta.
Il responsabile del processo e il responsabile editoriale del Brand possono
coincidere nella fase pilota, ma restano concetti distinti.

## Piano di lavoro — viste/YAML prima del database

1. **Operator — completato**: aggiunti `operator`, `role_operator` e
   `operator_roles` al Brand e aggiornati gli Assigned roles.
2. **Programma lezioni PosturaCorretta — priorità corrente**: completare
   `programma_lezioni_posturacorretta.yml` come ordine didattico unico, valido
   sia per lezioni individuali sia per lezioni di gruppo. Ogni riga visibile è
   un corso completo e raccoglie tutti i suoi capitoli e le sue schede. Le date
   delle lezioni di gruppo restano nel file separato
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
6. **1Impegno, soltanto dopo programma e Week Plan**: creare una single
   page/prototipo alimentata da YAML per `DataSession → DataSlot`, senza ancora
   costruire i model. Il programma sarà la dima; l'orario settimanale aiuterà a
   collocare le istanze reali.
7. **Cycle**: introdurlo solo dopo aver verificato programma, orario, Session e
   Slot; dovrà poter descrivere anche il ciclo di produzione di un video e il
   percorso di un paziente.
8. **Catalogo pubblico**: una vista datata Contenuti ed eventi con
   prossimi/passati, visibilità pubblica e privata.
9. **Test reale**: usare YAML e correggere il vocabolario.
10. **Solo dopo**: scegliere schema database, modelli, controller e migrazioni.

## Decisioni ancora aperte

- formato YAML esatto dei ponti e dei riferimenti DataSlot → Contenuto;
- campi minimi della single page DataSession/DataSlot;
- regole definitive per Session di gruppo, seriali e parallele;
- quando una Session datata genera o aggiorna un DataCommitment;
- campi del futuro Cycle e Service, dopo il pilota.
