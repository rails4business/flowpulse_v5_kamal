# DataEvent MVP — storico delle decisioni superate

> **Non è la fonte di verità corrente.** La tabella `data_events` è stata
> rimossa prima dell'uso reale. Le decisioni attuali sono in
> [Architettura comune — contenuti, cicli e servizi](ARCHITETTURA_CICLI_CONTENUTI_E_SERVIZI.md).
> Questo documento resta come storico dei requisiti e delle domande emerse.

## Obiettivo

Definire e implementare la versione minima funzionante che colleghi:

- ciò che viene organizzato (`DataEvent`);
- la gerarchia tra elemento principale, giorni, sessioni e task;
- l'iscrizione e la presenza delle persone (`DataCommitment`);
- la visualizzazione degli impegni nel calendario;
- uno show ad albero ispirato al componente **Custom tree styling** di Preline.

Questo documento serve come checklist decisionale. Ogni punto va analizzato e confermato separatamente prima di trasformarlo in codice.

## Confini della prima versione

> **Stato del lavoro:** il nucleo dati è stato implementato il 2 settembre 2026
> con migrazione, modello `DataEvent`, associazioni a `DataCommitment` e test.
> Il primo controller pubblico, lo show ad albero, il generatore settimanale e
> le prime date reali sono ora presenti. Permessi operativi, prenotazioni e
> interfacce amministrative restano da implementare progressivamente.

### Stato tecnico sintetico

| Parte | Stato |
|---|---|
| Tabella e modello `DataEvent` | Implementati |
| Gerarchia `root → day → session → task` | Implementata e validata |
| Classificazioni e stati | Implementati |
| Pubblicazione e iscrizioni | Campi e regole di modello implementati |
| Servizio minimo sul `DataEvent` | Campi, riferimento e regole implementati |
| Collegamenti richiesto/assegnato su `DataCommitment` | Implementati |
| Commitment padre e figli | Associazione implementata |
| Stato `requested` del commitment | Implementato |
| Dominio, responsabile e luogo | Collegamenti ed eredità implementati |
| Ambito e approvazione dei luoghi | Campi e validazioni implementati |
| Ricorrenza | Struttura dati e primo generatore settimanale PosturaCorretta implementati |
| Permessi dell'MVP | Da applicare nei controller |
| Index, calendario, agenda e show ad albero | Appuntamenti e tree show implementati; index amministrativo da fare |
| Quattro orari PosturaCorretta | Prima settimana generata nel database locale |
| Eventi editoriali PosturaCorretta | 10 eventi YAML e relativi programmi importati localmente |

Verifica aggiornata: **50 test, 422 asserzioni, nessun errore** includendo
modelli, controller amministrativi (radice, day, session), generatore settimanale, dashboard e show pubblico.

Nella prima versione implementiamo soltanto:

```text
DataEvent      → ciò che viene organizzato
DataCommitment → chi aderisce o svolge concretamente l'attività
```

Rimandiamo a una fase successiva:

- `Activity`, che conterrà programma, schede, esercizi e contenuti;
- `Service`, che definirà prezzo, capienza, ruoli ammessi e condizioni;
- collegamenti multipli a corsi, percorsi e progetti;
- ricorrenze automatiche avanzate;
- pagamenti e rimborsi;
- automazioni complesse delle prenotazioni.

I documenti architetturali precedenti devono essere aggiornati, perché non possono rimanere come fonti di verità concorrenti. Durante questa analisi vengono marcati come **in riallineamento** e collegati a questo documento. Quando le decisioni dell'MVP saranno confermate, le parti ancora valide verranno integrate e le ipotesi sostituite (`EventFormat`, `EventOccurrence`, `EventRegistration` e slot come modelli separati) verranno rimosse o archiviate come storico.

## Risposte trasversali ai dubbi emersi

### `DataEvent` può alimentare Routine, Percorsi, Classi, Corsi, Eventi e Progetti

Sì. Queste voci non devono diventare modelli o calendari diversi. Sono classificazioni attraverso le quali organizzare e filtrare i `DataEvent`:

```text
DataEvent
├── routine
├── path
├── class
├── course
├── event
└── project
```

La classificazione risponde alla domanda **«in quale raggruppamento lo mostro?»**. Il tipo del nodo risponde invece alla domanda **«che funzione svolge nell'albero?»**:

```text
classification: routine | path | class | course | event | project
node_kind: root | day | session | task
```

Le due informazioni non vanno confuse. Per esempio:

- una classe settimanale può essere `classification: class` e `node_kind: root`;
- la lezione del giovedì può essere `classification: class` e `node_kind: session`;
- una visita individuale prenotata può essere `classification: path` e `node_kind: session`;
- il calendario operativo di un progetto può essere `classification: project` e `node_kind: root`.

Per l'MVP si può avere una classificazione principale. Bisogna però ricordare che in futuro la stessa lezione potrebbe appartenere contemporaneamente a una classe e a un percorso; in quel momento servirà un'associazione multipla, non una stringa con più significati.

### La ricorrenza non è una sesta classificazione

`Ricorrenza` descrive **come vengono generate le date**, non che cosa rappresenta il `DataEvent`. Può essere applicata a una routine, una classe, un corso, un evento o una disponibilità individuale.

```text
DataEvent: Classe PosturaCorretta di Viadana
classification: class
recurrence: ogni giovedì, 18:00–19:00
```

La voce **Ricorrenze** dell'interfaccia resta una vista operativa delle regole ricorrenti. Non richiede che `recurrence` diventi un tipo di evento.

Per la prima migrazione non è ancora deciso se la regola sarà salvata direttamente su `DataEvent` oppure in un modello dedicato. È invece già chiaro che le singole date generate dovranno diventare figli modificabili e conservare lo storico.

### Che cosa non deve diventare `DataEvent`

Non deve diventare `DataEvent` ciò che non rappresenta né qualcosa da organizzare né una parte selezionabile o temporalmente rilevante:

- testo di un capitolo;
- PDF o collegamento;
- immagine e video;
- istruzione contenuta in una scheda;
- singolo esercizio, se è soltanto contenuto della scheda;
- prezzo, regola di capienza o condizione commerciale;
- ruolo stabile assegnato a una persona nel dominio;
- dati specialistici di GeneraImpresa come validazione, risorse, investimenti e avanzamento: estendono il progetto ma non diventano ulteriori `DataEvent` soltanto perché esistono.

Questi elementi possono comparire nello show ad albero come contenuti collegati, senza essere righe della tabella `data_events`.

Un esercizio diventa invece un `DataEvent` soltanto quando viene pianificato, prenotato o registrato come elemento autonomo, per esempio «esegui questa pratica dalle 08:00 alle 08:10». In quel caso produce o collega un `DataCommitment`.

La direzione aggiornata considera il `DataEvent` radice come l'oggetto organizzato stesso: progetto, corso, percorso, classe, routine oppure evento. GeneraImpresa potrà aggiungere al `DataEvent` classificato `project` le informazioni specifiche di validazione, fasi, step, task, risorse e avanzamento, senza creare una seconda identità concorrente.

```text
DataEvent: Progetto GeneraImpresa
├── obiettivo e periodo di attività
├── DataEvent: fase o elemento da programmare
├── DataEvent: riunione con intervallo giornaliero
└── DataEvent: sessione di lavoro con intervallo giornaliero
    └── DataCommitment delle persone coinvolte
```

Il calendario è una delle strutture operative del `DataEvent`, non la sua identità completa.

### Periodo di attività e intervallo di calendario sono differenti

Un `DataEvent` principale può avere un periodo durante il quale è attivo senza occupare il calendario personale:

```text
Corso attivo:       1 settembre – 30 novembre
Progetto attivo:    1 settembre – 31 dicembre
Evento multidata:  10 settembre – 12 settembre
```

Questi intervalli descrivono durata, validità o finestra organizzativa. Nel calendario entrano invece soltanto i figli collocati dentro una giornata concreta:

```text
DataEvent: Corso · 1 settembre – 30 novembre       → non appare come blocco
└── DataEvent: Lezione · 10 settembre 18:00–19:00 → appare nel calendario
```

Servono quindi due concetti distinti:

```text
active_from / active_until → periodo complessivo, espresso normalmente come date
starts_at / ends_at        → intervallo concreto dentro una giornata
```

Regola iniziale:

- il periodo del padre non genera automaticamente una voce nel calendario;
- un elemento con intervallo contenuto nella stessa giornata può generare o collegare un `DataCommitment` e apparire nel calendario;
- un evento di più giorni viene mostrato attraverso i singoli giorni o le singole sessioni figlie;
- un elemento giornaliero senza orario potrà essere trattato come `all_day`;
- nel calendario personale entrano i `DataCommitment`, non tutti i `DataEvent` dotati di una data.

### Radice e parti temporali possono usare lo stesso modello

Non serve dividerli in due modelli. Entrambi possono essere `DataEvent`, ma non sono semanticamente identici:

- la radice organizza i figli e può avere soltanto un periodo generale di attività;
- il giorno identifica la parte appartenente a una singola data;
- la sessione identifica un intervallo concreto, di gruppo oppure individuale;
- il task descrive qualcosa da svolgere dentro una sessione e può avere una durata prevista.

Questa distinzione permette di stabilire correttamente che cosa appare nel calendario senza reintrodurre `EventFormat` ed `EventOccurrence`.

### Lo show può mostrare più livelli senza salvarli tutti come `DataEvent`

Il tree view Preline è una struttura di presentazione, non una corrispondenza obbligatoria «una riga grafica = un record DataEvent»:

```text
DataEvent principale
└── DataEvent giorno/sessione
    ├── contenuto collegato: scheda
    └── contenuto collegato: esercizio
```

Per ora salviamo come `DataEvent` radice, giorni, sessioni e task. Schede, PDF, video ed esercizi puramente descrittivi restano contenuti collegati; un esercizio diventa task quando deve essere svolto, assegnato o tracciato.

## Struttura provvisoria

```text
DataEvent — radice: routine, percorso, classe, corso, evento o progetto
└── DataEvent — giorno
    └── DataEvent — sessione di gruppo o individuale
        ├── DataEvent — task
        └── DataCommitment delle persone coinvolte
```

`DataEvent.parent_id` forma inizialmente un albero con un solo genitore. Se in futuro lo stesso evento dovrà appartenere a più corsi, percorsi o progetti, verrà aggiunta un'associazione separata.

`DataCommitment` viene usato anche come registrazione: non introduciamo per ora un modello `EventRegistration`.

Una partecipazione può appartenere anche a una persona senza account, rappresentata
da un `Contact` tramite `participant_contact_id`. Il profilo che inserisce la
richiesta resta distinto in `created_by_profile_id`. Se la persona creerà in
seguito un account, il contatto potrà essere collegato e i commitment riassociati
con una procedura esplicita, senza creare preventivamente utenti fittizi.

## Decisioni da affrontare una alla volta

### 1. Significato e confini di `DataEvent`

Decisione:

- un elemento è un `DataEvent` quando rappresenta qualcosa di organizzato con un obiettivo: routine, percorso, classe, corso, evento o progetto;
- può esistere senza date oppure avere soltanto un periodo complessivo di attività;
- il periodo complessivo non occupa il calendario;
- con `starts_at` e `ends_at` contenuti nella stessa giornata rappresenta un intervallo concreto che può essere collegato al calendario;
- contenitore organizzativo ed elemento temporale usano lo stesso modello, distinti tramite `node_kind` e presenza dell'intervallo;
- un'azione personale non organizzata resta direttamente un `DataCommitment`;
- routine, percorso, classe, corso, evento e progetto sono classificazioni operative del `DataEvent`;
- un `DataEvent` classificato `project` rappresenta il progetto organizzato; GeneraImpresa ne estende i dati specifici e Impegno ne utilizza le parti temporali;
- testi, schede, esercizi, prezzi, servizi e dati specialistici dei progetti non diventano automaticamente ulteriori `DataEvent`.

Precisazione terminologica: il nodo radice può essere presentato nell'interfaccia come **Progetto**, **Classe**, **Corso**, **Percorso** o **Evento**. Il suo periodo di attività non coincide con il calendario personale di Impegno, che è una vista aggregata dei `DataCommitment` giornalieri della persona.

Stato: **confermato come direzione del punto 1**.

### 2. Tipi minimi di nodo

Decisione proposta:

```text
root    → identità, obiettivo e struttura generale
day     → parte appartenente a una singola data
session → intervallo concreto di gruppo o individuale
task    → cosa deve essere svolto nella sessione
```

`classification` determina invece se la radice viene mostrata tra Routine, Percorsi, Classi, Corsi, Eventi o Progetti.

#### Nessun nodo o modello `slot`

Non vengono creati anticipatamente slot rigidi. Per gli appuntamenti individuali si conserva una finestra di disponibilità; la `session` nasce soltanto dopo la richiesta o la conferma della prenotazione.

```text
DataEvent day · disponibilità 09:00–13:00
├── DataEvent session · 09:00–09:30, creata dopo la prenotazione
└── DataEvent session · 09:30–10:20, creata dopo la prenotazione
```

La durata della sessione può dipendere dal futuro `Service`: 30, 50, 60 minuti oppure un'altra durata prevista dal servizio scelto.

La politica iniziale propone preferibilmente intervalli adiacenti alle prenotazioni esistenti, così da mantenere compatta l'agenda. Se la persona non può scegliere quegli intervalli, l'operatore può ampliare manualmente la disponibilità. Questa è una regola di proposta degli orari, non un nuovo tipo di record.

Regola confermata per la prima proposta automatica:

- il nodo `day` contiene la finestra giornaliera prenotabile;
- nella stessa data possono esistere più nodi `day`, per esempio mattina,
  pomeriggio e sera, ciascuno con la propria finestra e il proprio `position`;
- le finestre sorelle della stessa struttura non possono sovrapporsi;
- se non esistono ancora sessioni, viene proposto un nuovo intervallo a partire
  dall'inizio della finestra;
- se esistono sessioni, vengono cercati prima gli intervalli immediatamente
  adiacenti, sopra o sotto il blocco esistente, purché restino nella finestra;
- la durata deriva dal servizio applicato oppure dalla durata concordata;
- la scelta proposta o effettuata dalla persona viene salvata inizialmente nel
  `DataCommitment` con stato `requested`;
- la richiesta non occupa definitivamente il calendario;
- la `session` figlia viene creata soltanto quando la richiesta viene confermata;
- richieste concorrenti sullo stesso intervallo devono essere ricontrollate al
  momento della conferma;
- il calcolo considera le sessioni delle altre fasce della stessa data e dello
  stesso organizzatore;
- se nessun intervallo adiacente è disponibile, il sistema può proporre un altro
  spazio libero nella finestra oppure lasciare la scelta al superadmin.

Il `DataCommitment` deve quindi conservare l'inizio e la fine proposti senza
confonderli con `created_at`, che continua a indicare il momento di invio della
richiesta. Dopo la conferma, `data_event_id` punta alla nuova sessione concreta,
mentre `requested_data_event_id` continua a puntare al `day` originariamente
scelto.

Per le attività di gruppo la sessione viene invece creata prima delle prenotazioni, perché giorno e orario sono già stabiliti. Più `DataCommitment` possono collegarsi alla stessa sessione.

#### Sessioni e task restano `DataEvent`

Sia `session` sia `task` sono righe di `data_events`:

- una sessione può essere di gruppo o individuale;
- una sessione può contenere più task;
- gli stessi task possono essere inseriti in sessioni di gruppo oppure individuali;
- il task può avere durata prevista senza possedere necessariamente un orario assoluto;
- quando un task viene pianificato autonomamente può avere anche un proprio intervallo e un `DataCommitment`.

Finché `Service` non esiste, non serve copiarlo in un campo testuale generico. Per provare il flusso bastano:

- `bookable`, per stabilire se si può richiedere la partecipazione;
- `booking_mode`, per stabilire se si prenota il padre oppure una sessione;
- eventuale breve `booking_notes`, solo per le istruzioni mostrate all'utente.

Prezzo, capienza, durata commerciale e ruoli ammessi verranno affidati successivamente al servizio.

Stato: **confermato come direzione del punto 2, salvo nomenclatura dei campi**.

### 3. Gerarchia tramite `parent_id`

Decisione:

```text
root
└── day
    └── session
        └── task
```

La gerarchia non viene approfondita oltre il task:

- `root` contiene uno o più `day`;
- `day` contiene una o più `session`;
- `session` contiene zero o più `task`;
- `task` è atomico e non può avere figli;
- quando servono altre parti operative si aggiungono altri task oppure un'altra sessione, senza creare sotto-task.

#### Giorni e sessioni possono essere preparati prima delle date

Un giorno può esistere senza una data e una sessione può esistere senza un orario. In questo modo si prepara prima la struttura e la si calendarizza progressivamente:

```text
Evento o percorso
├── Giorno 1 · data da definire
│   ├── Sessione 1 · orario da definire
│   └── Sessione 2 · orario da definire
└── Giorno 2 · data da definire
    └── Sessione 1 · orario da definire
```

Ogni figlio possiede `position`, un numero intero usato per mantenere l'ordine anche quando date e orari non sono ancora presenti.

Regole di ordinamento proposte:

1. `position` è la fonte dell'ordine progettato;
2. data e ora mostrano quando l'elemento è stato calendarizzato;
3. assegnare una data non deve cambiare automaticamente l'ordine progettato;
4. l'operatore può riordinare esplicitamente giorni, sessioni e task aggiornando `position`.

#### Eredità e intervalli

- dominio, responsabile e luogo vengono ereditati dal genitore quando il figlio non specifica un valore proprio;
- l'eredità è risolta cercando il primo valore disponibile risalendo l'albero;
- un valore presente sul figlio sostituisce quello ereditato soltanto per quel ramo;
- una sessione con orario deve appartenere alla data del proprio `day`;
- una sessione deve restare dentro l'eventuale intervallo disponibile del giorno, salvo modifica esplicita dell'operatore;
- un task può avere una durata prevista, ma non richiede un proprio orario assoluto;
- il modello deve impedire che un record diventi figlio di sé stesso o di uno dei propri discendenti.

Esempio:

```text
Evento principale · PosturaCorretta · Mark · Viadana
├── Giorno 1 · eredita dominio, responsabile e luogo
└── Giorno 2 · luogo proprio: Calvisano
    └── Sessione · eredita PosturaCorretta, Mark e Calvisano
```

#### Eredità nelle ricorrenze

Una ricorrenza genera progressivamente giorni e sessioni partendo da una struttura comune:

- finché il figlio generato è una bozza, può continuare a leggere i valori ereditati dal padre;
- quando la data viene confermata, vengono confermati anche i valori operativi effettivi necessari a conservarne lo storico;
- modificare successivamente luogo, responsabile o servizio sul padre non deve riscrivere automaticamente date già confermate o concluse;
- le date future ancora in bozza possono invece ricevere i nuovi valori;
- una singola ricorrenza può sempre sostituire un valore ereditato senza modificare le altre.

La modalità tecnica con cui salvare questa fotografia verrà scelta durante l'implementazione: colonne esplicite sui figli oppure metadati di conferma. La regola funzionale è già definita.

#### Collegamento con servizio e prenotazione

L'eredità può applicarsi in futuro anche al riferimento al `Service`, ma il servizio conserva la propria responsabilità:

- durata prevista della sessione;
- partecipazione individuale o di gruppo;
- numero minimo e massimo di persone;
- ruoli ammessi;
- prezzo e condizioni.

Se è prenotabile una sessione già esistente, la richiesta crea un `DataCommitment` collegato a quella sessione. Se viene prenotata una disponibilità individuale, la richiesta crea prima una nuova sessione della durata prevista dal servizio e poi il relativo `DataCommitment`.

Il ruolo ammesso viene definito dal servizio; il ruolo realmente assunto dalla persona viene registrato nel suo `DataCommitment`.

Il dominio non determina un tipo distinto di organizzatore: insegnanti,
professionisti del benessere e altri operatori autorizzati usano lo stesso
`DataEvent`. `created_by_profile_id` conserva l'autore, `responsible_profile_id`
indica l'organizzatore principale e `operator_roles` associa i profili ai ruoli
operativi previsti. Giorni e sessioni ereditano questa informazione; alla
conferma il ruolo effettivo verrà fotografato in
`DataCommitment.participation_role`.

Stato: **punto 3 confermato; i dettagli della partecipazione proseguono nel punto 4**.

### 4. Modalità di partecipazione

Decisione proposta: esistono due ingressi differenti alla partecipazione.

#### A. Prenotazione di qualcosa che possiede un servizio

Quando il nodo ha un servizio associato è prenotabile. Il servizio definirà in futuro prezzo, durata, numero di partecipanti e ruoli ammessi.

La persona può scegliere:

```text
prenotazione del padre       → comprende tutte le sessioni prenotabili sottostanti
prenotazione di uno o più figli → comprende soltanto le sessioni selezionate
```

Esempio:

```text
Corso · servizio completo
├── Giorno 1
│   ├── Sessione A
│   └── Sessione B
└── Giorno 2
    └── Sessione C
```

- prenotando il corso, la persona prende A, B e C;
- prenotando soltanto A e C, non acquisisce B;
- i task interni alle sessioni sono compresi e non vengono prenotati separatamente;
- una sessione può avere un proprio servizio quando prezzo, durata, capienza o condizioni sono differenti da quelli del padre.

La prenotazione del padre rappresenta l'adesione complessiva. Le sessioni datate comprese generano gli intervalli effettivi nel calendario mediante `DataCommitment`.

#### B. Richiesta individuale senza servizio già associato

Un `DataEvent` può offrire una disponibilità individuale, definita anche come prenotazione **verticale** o **seriale**: una persona alla volta, con durata da concordare o scelta successivamente.

Non vengono pubblicati slot rigidi. La persona invia una richiesta tramite `DataCommitment`:

```text
disponibilità del responsabile
→ DataCommitment richiesto
→ creazione di una sessione individuale provvisoria
→ conferma di durata e orario
→ DataCommitment confermato
```

La sessione può essere creata nella stessa operazione della richiesta, inizialmente in bozza. Finché la richiesta non viene confermata non blocca definitivamente il calendario.

Questa modalità serve, per esempio, per:

- visita;
- incontro con tutor;
- lezione individuale;
- consulenza;
- disponibilità di un professionista.

#### Dati temporanei prima di `Service`

Nel codice attuale non esiste un modello `Service` separato. Per l'MVP un `DataEvent` può dichiarare di essere anche una definizione di servizio tramite:

```text
service_definition: boolean, default false
```

Il nome tecnico consigliato è `service_definition`, non `services`: il singolare evita ambiguità e il nome completo chiarisce che il record definisce condizioni riutilizzabili. Nell'interfaccia continuerà a essere mostrato semplicemente come **Servizio**.

Questa scelta permette a un record di mantenere la propria classificazione principale e contemporaneamente essere acquistabile:

```text
DataEvent · classification: course · service_definition: true
DataEvent · classification: event  · service_definition: true
DataEvent · classification: path   · service_definition: false
```

Non serve quindi aggiungere `service` alle classificazioni: corso, evento o percorso descrivono che cosa è; `service_definition` indica che possiede anche condizioni di partecipazione.

Le condizioni minime salvate sul `DataEvent` che definisce il servizio sono:

```text
price_cents
currency
duration_minutes
minimum_participants
maximum_participants
allowed_roles
```

Quando una sessione usa le condizioni di un altro `DataEvent`, può collegarlo mediante una relazione distinta dalla gerarchia:

```text
service_data_event_id
```

`parent_id` indica dove si trova la sessione nell'albero; `service_data_event_id` indica quali condizioni applica. Il record referenziato deve avere `service_definition: true`.

Se il padre è già una definizione di servizio, i figli possono ereditarne le condizioni senza ripetere il collegamento. Un figlio dichiarato a sua volta `service_definition: true` può invece essere prenotato separatamente con condizioni proprie.

Quando una prenotazione viene confermata, prezzo, durata, capienza applicabile e ruolo vengono conservati come fotografia sul relativo `DataCommitment` o sulla sessione confermata. Cambiare successivamente il servizio non deve modificare lo storico.

In futuro si potrà estrarre un modello `Service` dedicato se le regole cresceranno; fino a quel momento `DataEvent` resta l'unica fonte di verità.

#### Fotografia del servizio e cancellazione

Non bisogna duplicare l'intera definizione del servizio su ogni evento. Si conserva invece una fotografia minima soltanto quando una sessione o una prenotazione viene confermata.

La separazione proposta è:

```text
DataEvent servizio
└── definizione corrente riutilizzabile

DataEvent sessione confermata
└── fotografia delle condizioni operative applicate

DataCommitment confermato
└── fotografia dell'accordo con quella persona
```

Fotografia minima sulla sessione:

- nome del servizio al momento della conferma;
- durata applicata;
- modalità individuale o di gruppo;
- capienza applicata;
- eventuali condizioni operative necessarie.

Fotografia minima sul `DataCommitment`:

- ruolo effettivo;
- prezzo concordato e valuta;
- stato della prenotazione e del pagamento;
- eventuali condizioni personali rilevanti.

Il collegamento `service_data_event_id` rimane per risalire alla definizione originale, ma lo storico confermato non dipende dalla sua presenza o dai suoi valori correnti.

Un `DataEvent` usato come servizio non può essere eliminato definitivamente quando è già referenziato. Può essere **archiviato**, così non viene più proposto per nuove prenotazioni ma rimane consultabile nello storico. La cancellazione definitiva resta possibile soltanto per bozze mai utilizzate e prive di collegamenti.

#### Proprietà e condivisione dei servizi — direzione futura

Per impostazione iniziale una persona usa e modifica soltanto i propri servizi. In futuro un servizio potrà dichiarare un ambito di utilizzo:

```text
private → utilizzabile soltanto dal proprietario
domain  → standard del singolo dominio
brand   → standard condiviso dai domini del brand
```

Il superadmin o un futuro responsabile autorizzato potrà approvare come standard del dominio o del brand:

- un proprio `DataEvent` servizio;
- il servizio proposto da un operatore;
- un servizio comune PosturaCorretta utilizzabile dagli insegnanti abilitati.

Gli operatori autorizzati potranno utilizzare lo standard senza modificare direttamente la definizione comune. Proprietà, approvazione, versioni e permessi dettagliati vengono rimandati dopo l'MVP; ora vengono fissati soltanto il principio di proprietà privata predefinita e la possibilità futura di condivisione controllata.

#### Regola comune

`DataEvent` descrive ciò a cui si partecipa; `DataCommitment` registra la persona, il ruolo effettivo e lo stato della sua adesione. I task non sono direttamente prenotabili nell'MVP.

#### Prenotabilità separata dei figli

Il servizio del padre vende l'insieme completo e non rende automaticamente acquistabili le singole sessioni:

```text
Padre · service_definition: true
├── Sessione A · inclusa, non prenotabile separatamente
├── Sessione B · inclusa, non prenotabile separatamente
└── Sessione C · service_data_event_id presente
    └── prenotabile anche separatamente
```

Una sessione figlia è prenotabile separatamente soltanto quando:

- è essa stessa `service_definition: true`; oppure
- possiede un proprio `service_data_event_id`.

Un'attività gratuita che richiede iscrizione di gruppo usa comunque una definizione di servizio con prezzo pari a zero. Rimane separata la richiesta individuale senza servizio, che crea una nuova sessione da concordare. I task non sono mai prenotabili direttamente nell'MVP.

Stato: **punto 4 confermato; nel punto 6 verrà deciso come materializzare i commitment dei figli quando si prenota il padre**.

### 5. `DataCommitment` come registrazione

Decisione: `DataCommitment` viene usato anche come richiesta e registrazione, senza introdurre un modello separato.

#### Collegamenti all'evento richiesto e confermato

Servono due riferimenti distinti:

```text
requested_data_event_id → ciò che la persona ha richiesto
data_event_id           → sessione effettivamente assegnata
```

`requested_data_event_id` può puntare alla radice, al giorno o alla disponibilità oggetto della richiesta. Non viene sostituito dopo la conferma: rimane come storico della scelta iniziale.

`data_event_id` rimane vuoto finché non esiste una sessione concreta; dopo la conferma punta alla sessione di gruppo o individuale assegnata.

Esempio:

```text
Richiesta
├── created_at: 1 settembre, 10:30
├── requested_data_event_id: disponibilità del 10 settembre
├── data_event_id: —
├── status: requested
└── blocks_calendar: false

Conferma
├── requested_data_event_id: invariato
├── data_event_id: sessione del 10 settembre, 11:00–11:50
├── starts_at: 10 settembre, 11:00
├── ends_at: 10 settembre, 11:50
├── status: confirmed
└── blocks_calendar: true
```

`created_at` registra quando è stata inviata la richiesta. Non deve essere trasformato nella data dell'appuntamento. Un eventuale orario desiderato può essere conservato inizialmente nei metadata e, se necessario, diventare in futuro `requested_starts_at` e `requested_ends_at`.

#### Stati

Agli stati esistenti di `DataCommitment` viene aggiunto `requested`:

```text
draft
requested
planned
confirmed
in_progress
completed
cancelled
```

- `planned` continua a rappresentare un impegno personale pianificato che non richiede approvazione;
- `requested` rappresenta una richiesta inviata ma non ancora confermata;
- `confirmed` rappresenta una partecipazione o sessione accettata;
- `in_progress` e `completed` rappresentano lo svolgimento reale;
- `cancelled` non blocca il calendario.

#### Data obbligatoria e calendario

- una prenotazione deve indicare almeno un giorno;
- una richiesta generica senza giorno non è ancora un `DataCommitment`, ma una richiesta di informazioni o disponibilità;
- se il giorno è noto ma l'ora deve essere concordata, il commitment usa quella data con `all_day: true`, `status: requested` e normalmente `blocks_calendar: false`;
- quando l'orario viene confermato, `all_day` diventa falso e vengono valorizzati inizio e fine effettivi;
- una richiesta con un intervallo proposto può riservarlo provvisoriamente mediante `blocks_calendar: true`, indipendentemente dal suo aspetto semitrasparente;
- un commitment confermato collegato a una sessione deve avere inizio e fine e blocca il relativo calendario;
- un commitment padre che rappresenta l'adesione complessiva può essere confermato ma non bloccante;
- il calendario personale mostra soltanto gli intervalli effettivi, non il momento nel quale è stata inviata la richiesta.

#### Ruolo e responsabilità

Il ruolo effettivo svolto dalla persona viene registrato nel `DataCommitment`, per esempio partecipante, insegnante, tutor, tirocinante, organizzatore o supervisore. Chi crea il `DataEvent` ne è inizialmente responsabile, ma autore della richiesta, responsabile dell'evento e persona che partecipa rimangono concetti distinti.

Stato: **punto 5 confermato nella struttura principale; l'eventuale `parent_id` dei commitment viene deciso nel punto 6**.

### 6. Iscrizione al padre e generazione dei figli

Decisione:

#### Prenotazione dell'intero padre

La prenotazione completa crea un `DataCommitment` principale, che rappresenta adesione, servizio, prezzo e pagamento complessivi. Vengono creati commitment figli soltanto quando servono più giorni o sessioni temporalmente separate:

```text
DataCommitment padre · blocks_calendar: false
├── DataCommitment sessione A · blocks_calendar: true
├── DataCommitment sessione B · blocks_calendar: true
└── DataCommitment sessione C · blocks_calendar: true
```

I commitment delle sessioni conservano `parent_id` verso il commitment principale.

- le sessioni già datate e comprese al momento della conferma generano subito i commitment figli;
- il padre non viene mostrato come un secondo blocco temporale;
- i task sono compresi nelle sessioni e non generano automaticamente commitment separati;
- il prezzo complessivo resta sul commitment padre, mentre sui figli possono essere conservate soltanto eventuali quote o condizioni specifiche.

La regola è mantenere il minor numero possibile di commitment senza perdere intervalli, presenze o completamenti distinti:

- un solo intervallo continuo → un solo commitment, che contiene anche le condizioni economiche;
- più giorni o sessioni separate → commitment principale economico più figli temporali;
- più task nella stessa sessione → nessun commitment aggiuntivo automatico.

#### Prenotazione di sessioni separate

Quando la persona sceglie soltanto uno o più figli prenotabili, vengono creati commitment soltanto per le sessioni selezionate. Se la selezione viene acquistata e pagata come una sola operazione, può essere creato un commitment principale economico con quei soli figli; altrimenti ogni sessione resta una prenotazione autonoma. Non viene attribuita l'adesione completa al padre.

#### Sessioni aggiunte successivamente

Se dopo l'iscrizione completa viene aggiunta una nuova sessione oppure una sessione prima senza data viene calendarizzata:

- la sessione è riconosciuta come compresa nell'adesione;
- viene creato un commitment figlio con stato `requested` e `blocks_calendar: false`;
- il partecipante deve confermare il nuovo intervallo prima che occupi il suo calendario;
- il rifiuto o l'annullamento della singola nuova sessione non annulla automaticamente l'adesione completa.

Lo stesso principio si applica a uno spostamento sostanziale di una sessione già confermata: il nuovo orario non deve occupare automaticamente il calendario senza consenso.

#### Evento continuo

Quando il padre rappresenta un unico intervallo continuo e non possiede sessioni temporali separate, può esistere un solo commitment confermato collegato al giorno o alla sessione concreta. Non si crea una coppia padre-figlio priva di utilità.

Stato: **punto 6 confermato**.

### 7. Regola di visibilità nel calendario

Decisione:

> Nel calendario compare l'unità temporale realmente occupata; lo show conserva l'intero albero organizzativo.

`DataEvent` organizza ciò che deve avvenire. `DataCommitment` porta la partecipazione della singola persona nella sua agenda. Nessun `DataEvent` entra direttamente nell'agenda personale senza un commitment associato.

Anche organizzatori e operatori hanno il proprio commitment:

```text
DataEvent sessione · 10 settembre 18:00–19:00
├── DataCommitment · Mark · teacher/organizer
├── DataCommitment · Anna · participant
└── DataCommitment · Luca · trainee
```

Nell'agenda e nello show deve essere sempre visibile:

- il collegamento al `DataEvent`;
- il titolo dell'evento, percorso, corso o progetto di appartenenza;
- il ruolo svolto dalla persona;
- chi è organizzatore o responsabile;
- il dominio di provenienza.

#### Aspetto grafico e blocco del calendario

Aspetto e blocco sono indipendenti:

- confermato e bloccante → aspetto normale;
- richiesto con intervallo riservato → semitrasparente ma bloccante;
- ipotesi non bloccante → tratteggiata o più tenue;
- annullato → storico, non bloccante.

I commitment degli operatori devono essere distinguibili da quelli dei partecipanti mediante colore, icona o badge del ruolo. Il colore non sostituisce l'etichetta testuale e non deve essere l'unico modo per comunicare il ruolo.

Una prima direzione grafica può distinguere:

```text
organizzatore/operatore → colore operativo
partecipante            → colore personale
richiesta/ipotesi       → opacità o tratteggio
dominio                 → pill o piccolo indicatore del brand
```

I colori definitivi verranno scelti nell'implementazione rispettando la palette del dominio e l'accessibilità.

#### Ruoli e compensi degli operatori

Il `DataEvent` usato come definizione di servizio può indicare i ruoli operativi necessari e il compenso standard previsto per ciascun ruolo, separandolo dal prezzo pagato dal partecipante:

```text
prezzo partecipante
operator_roles
├── teacher   · compenso standard
├── tutor     · compenso standard
└── assistant · compenso standard
```

Quando una persona viene assegnata alla sessione, il suo `DataCommitment` conserva:

- ruolo effettivo;
- compenso concordato;
- tipo di valorizzazione, per esempio fisso oppure orario;
- riferimento al servizio applicato;
- fotografia delle condizioni applicate.

Il servizio rimane lo standard; il commitment rappresenta l'accordo concreto. Modificare successivamente il compenso standard non cambia quanto già concordato.

Una gestione formale delle versioni del servizio può essere aggiunta dopo l'MVP. Per la prima versione è sufficiente lo snapshot sui commitment e sulle sessioni confermate; in futuro si potrà aggiungere un numero di revisione per confrontare le versioni.

L'indice del calendario deve unire:

- commitment personali senza evento;
- commitment collegati a eventi;
- eventi nei quali la persona opera come organizzatore o conduttore; qui per esempio c'è da mettere una regola per gli eventi multigiorno e con giorni staccati...
- senza mostrare contemporaneamente padre e figli sullo stesso intervallo.

Il calendario pubblico del dominio mostra i `DataEvent` pubblicati. L'agenda privata mostra i `DataCommitment` della persona. Bozze e ipotesi sono visibili soltanto agli operatori autorizzati e al superadmin.

Stato: **punto 7 confermato; colori definitivi e versionamento dei servizi rimandati**.

### 8. Stati di `DataEvent`

Decisione: stato organizzativo, pubblicazione, visibilità e iscrizioni sono dimensioni separate.

#### Stato organizzativo

Stato organizzativo già usato:

```text
draft      → bozza incompleta
organizing → in organizzazione
proposed   → proposto al pubblico
confirmed  → confermato
completed  → concluso
cancelled  → annullato
```

`draft` rimane sempre privato. Gli altri stati non determinano da soli la visibilità.

#### Pubblicazione e visibilità

Per l'MVP:

```text
visibility: private | public
published_at: datetime facoltativo
```

Il comando **Pubblica** non modifica necessariamente lo stato organizzativo. Imposta la visibilità pubblica e registra il momento della pubblicazione.

Combinazioni ammesse:

```text
organizing + private → organizzazione interna
organizing + public  → visibile per raccogliere interesse
proposed + public    → proposta ufficialmente al pubblico
confirmed + public   → evento confermato
cancelled + public   → evento ancora visibile con avviso di annullamento
```

Il comportamento mantiene compatibilità con PosturaCorretta: gli eventi in organizzazione possono essere pubblici, mentre le bozze sono escluse agli utenti normali.

In futuro `visibility` potrà includere `domain`, `brand` o `unlisted`; non sono necessari per l'MVP.

#### Stato delle iscrizioni

Stato delle iscrizioni già separato:

```text
pending
open
full
closed
```

Modalità già distinta:

```text
none     → accesso libero
required → iscrizione richiesta
pending  → modalità ancora da decidere
```

Un evento può quindi essere confermato con iscrizioni ancora aperte, complete oppure chiuse. `full` può essere calcolato dalla capienza e dai commitment confermati, evitando un contatore indipendente quando possibile.

#### Filtri pubblici

Il calendario pubblico può filtrare separatamente:

- stato organizzativo;
- stato e modalità delle iscrizioni;
- data;
- classificazione;
- luogo;
- conduttore.

Stato: **punto 8 confermato**.

### 9. Dominio, organizzatore, luogo e responsabilità

Decisione: vengono riutilizzati `Domain`, `Profile` e `Brands::Impegno::Place` già presenti. Non viene creato un modello luogo specifico per PosturaCorretta.

#### Riferimenti del DataEvent

Campi proposti:

```text
domain_id
created_by_profile_id
responsible_profile_id
place_id
```

- `domain_id` indica il dominio proprietario del contesto;
- `created_by_profile_id` conserva chi ha creato il record;
- `responsible_profile_id` indica il responsabile attuale ed è ereditabile;
- `place_id` collega il luogo di Impegno ed è ereditabile.

Organizzatori, insegnanti, tutor, tirocinanti e altri operatori vengono rappresentati dai loro `DataCommitment` e relativi ruoli, non mediante una serie di colonne sul `DataEvent`.

#### Proprietà e riconoscimento dei luoghi

Il luogo appartiene tecnicamente a Impegno. `profile_id` indica proprietario o referente; l'eventuale `domain_id` indica il dominio nel quale è riconosciuto, non trasferisce la proprietà.

Luogo personale o professionale:

```text
profile_id: professionista
domain_id: null
scope: private
```

Centro o luogo riconosciuto da PosturaCorretta:

```text
profile_id: superadmin o responsabile
domain_id: posturacorretta
scope: domain
approval_status: approved
```

Luogo proposto da un professionista:

```text
profile_id: professionista
domain_id: posturacorretta
scope: domain
approval_status: pending
```

Il superadmin può approvarlo senza cambiare il proprietario.

Campi da aggiungere a `impegno_places`:

```text
domain_id       facoltativo
scope           private | domain | brand
approval_status draft | pending | approved | rejected | archived
```

Più professionisti possono utilizzare lo stesso luogo nei propri `DataEvent` senza duplicarlo. Una futura associazione tra luoghi, profili e ruoli potrà descrivere chi vi opera stabilmente; non è necessaria nell'MVP.

Quando una sessione viene confermata, nome e indirizzo effettivamente applicati vengono conservati nello snapshot storico della sessione o dei commitment.

Primo contesto reale: **PosturaCorretta, Viadana di Calvisano**.

Stato: **punto 9 confermato; associazioni multiple tra luoghi e operatori rimandate**.

### 10. Permessi dell'MVP

Decisione per il primo avvio:

- il superadmin crea, modifica e annulla i `DataEvent`;
- l'utente autenticato può richiedere la partecipazione;
- il superadmin conferma manualmente;
- l'utente vede soltanto i propri commitment;
- gli eventi dichiarati pubblici sono consultabili senza autenticazione;
- il proprietario del servizio può vedere i DataEvent che lo applicano;
- responsabili e operatori possono vedere le sessioni e i partecipanti nei quali possiedono un commitment operativo;
- soltanto il superadmin approva inizialmente luoghi e servizi standard;
- ruoli più avanzati verranno aperti progressivamente.

#### Servizio pubblico e autorizzazione futura

Un servizio standard PosturaCorretta può essere pubblico e uguale per tutti gli insegnanti, ma pubblico non significa utilizzabile operativamente da qualsiasi persona.

In futuro l'autorizzazione a creare o condurre sessioni basate sul servizio dovrà verificare almeno:

```text
ruolo nel dominio
abilitazione al corso o modulo
livello conseguito
eventuale tirocinio o supervisione richiesta
```

Esempio:

```text
Servizio standard: Lezione Base di Igiene Posturale
├── visibile pubblicamente
└── erogabile soltanto da profili autorizzati
    ├── insegnante abilitato Base
    ├── tirocinante in conduzione supervisionata
    └── insegnante avanzato o maestro
```

I concetti da distinguere saranno:

- ruolo stabile nel dominio, per esempio `teacher`;
- livello formativo della persona, per esempio Base o Avanzato;
- stato di tirocinio;
- abilitazione specifica per corso o modulo;
- ruolo assunto nella singola sessione, conservato nel `DataCommitment`.

Per l'MVP queste verifiche non vengono automatizzate: il superadmin assegna e conferma manualmente. La struttura non deve però confondere visibilità del servizio con permesso di erogazione.

Stato: **punto 10 confermato per l'MVP; matrice ruoli, attestati e abilitazioni rimandata**.

### 11. Show ad albero

Decisione: lo show usa il tree view Preline fornito come riferimento, adattato alla UX del sito e alla gerarchia fissa `root → day → session → task`.

```text
Nome evento, corso, percorso o progetto
└── Giorno 1 · giovedì 10 settembre 2026
    ├── Sessione 1 · 18:00–18:30
    │   ├── Task · Mobilità articolare · 10 min
    │   └── Task · Respirazione · 5 min
    └── Sessione 2 · 18:30–19:00
        └── Task · Verifica · 10 min
```

Anche quando esiste una sola data viene mantenuto il livello `day`, così evento singolo e multidata condividono la stessa struttura.

La riga della sessione mostra in forma compatta:

- orario o posizione se ancora da definire;
- stato;
- luogo effettivo;
- servizio applicato;
- posti disponibili, quando previsti;
- operatori con ruolo;
- stato della prenotazione dell'utente.

La riga del task mostra:

- titolo;
- durata prevista;
- stato;
- eventuale icona o link al contenuto.

Il testo esteso del task non viene aperto dentro l'albero: selezionando la riga si apre il relativo dettaglio. Il task rimane atomico e non ha ulteriori figli.

Direzione grafica e accessibilità:

- badge per stato e partecipazione;
- albero verticale apribile anche su mobile.
- controlli apri/chiudi utilizzabili da tastiera;
- attributi ARIA coerenti con la struttura tree;
- colore accompagnato sempre da testo o icona;
- rientri contenuti per non perdere spazio su mobile.

Stato: **punto 11 confermato**.

### 12. Index e agenda settimanale

Decisione: indice dei `DataEvent`, calendario del dominio e agenda personale sono tre viste differenti degli stessi dati collegati.

#### Indice DataEvent

Mostra principalmente i nodi `root` organizzati nelle viste:

```text
Routine
Percorsi
Classi
Corsi
Eventi
Progetti
```

Per ogni radice può mostrare stato, responsabile, periodo complessivo, dominio e prossimo appuntamento. Non è una vista del calendario personale.

#### Calendario del dominio

Mostra le sessioni e gli eventi pubblicati appartenenti al dominio, per esempio lezioni, incontri, eventi e disponibilità rese pubbliche da PosturaCorretta.

Non espone commitment personali, richieste private, compensi o dati degli iscritti. Applica visibilità, stato di pubblicazione e filtri del dominio.

#### Agenda personale

Mostra i `DataCommitment` della persona nei diversi ruoli:

- partecipante;
- insegnante;
- tutor;
- organizzatore;
- tirocinante;
- responsabile di attività o progetto.

Titolo, struttura, servizio, luogo e dominio vengono ricavati dal `DataEvent` collegato; ruolo, accordo e stato personale rimangono sul commitment.

Gli impegni provenienti dagli altri domini restano visibili con una pill del brand, così la persona può evitare sovrapposizioni. La vista incorporata in un dominio può ridurre i dettagli degli altri brand, ma non deve nascondere che l'intervallo è occupato.

#### Raggruppamenti e filtri

- agenda raggruppata per giorno e settimana;
- prossimi e passati calcolati dagli intervalli effettivi;
- filtri per dominio, ruolo e stato;
- nessuna duplicazione del padre quando i figli rappresentano gli intervalli reali;
- collegamento dal blocco visivo al commitment e allo show del DataEvent.

Stato: **punto 12 confermato**.

### 13. Primo caso reale di prova

#### Sede e organizzazione iniziale

- dominio: **PosturaCorretta**;
- responsabile e primo insegnante: **Mark Postura**;
- nome provvisorio della sede: **Sede PosturaCorretta · Viadana di Calvisano**;
- indirizzo completo: ancora da inserire;
- modalità: lezioni di gruppo;
- durata di ogni appuntamento: **60 minuti**.

#### Programmazione settimanale iniziale

Si parte riservando quattro ore alla settimana:

```text
Martedì  · 15:00–16:00
Martedì  · 20:00–21:00
Giovedì  · 15:00–16:00
Giovedì  · 20:00–21:00
```

Prima settimana caricata localmente: **7–13 settembre 2026**.

- martedì 8 settembre: 15:00–16:00 e 20:00–21:00;
- giovedì 10 settembre: 15:00–16:00 e 20:00–21:00;
- lezione: **Lezione pratica PosturaCorretta in un mese**.

I quattro appuntamenti della stessa settimana sono **orari alternativi della
stessa lezione**, non quattro lezioni consecutive. Il modulo proposto cambia la
settimana successiva per tutti gli orari.

Questa organizzazione permette:

- di preparare un solo contenuto didattico ogni settimana;
- alla persona di scegliere l'orario più comodo;
- di recuperare nella stessa settimana scegliendo un altro appuntamento;
- di verificare separatamente la domanda pomeridiana e quella serale;
- di conservare un unico ordine del programma didattico.

#### Conferma degli appuntamenti

I quattro orari rappresentano la disponibilità settimanale di partenza. Ogni
appuntamento viene confermato quando esiste almeno un partecipante; in assenza di
iscrizioni l'ora rimane disponibile ma Mark non è obbligato a condurre un gruppo
vuoto.

Nell'implementazione:

- il programma settimanale è la radice o struttura ricorrente;
- ciascuna data concreta è rappresentata dal relativo `DataEvent` giornaliero e
  dalla sessione ivi contenuta;
- la lezione/modulo della settimana è collegata alle quattro alternative;
- l'iscrizione di ogni persona genera il relativo `DataCommitment`;
- il commitment di Mark registra il ruolo di insegnante/conduttore;
- soltanto gli intervalli confermati e bloccanti occupano l'agenda personale.

#### Dati ancora necessari prima della prova completa

- indirizzo;
- capienza iniziale;
- prezzo, oppure conferma che la prima prova sia gratuita;
- regola definitiva di ricorrenza e periodo iniziale di pubblicazione.

Il primo caso deve verificare l'intero flusso: creazione, gerarchia, richiesta, conferma, commitment e calendario.

Stato: **struttura e prima settimana implementate localmente; indirizzo,
capienza definitiva, prezzo e prenotazione utente restano da completare**.

## Ordine consigliato di analisi

1. significato di `DataEvent`;
2. tipi dei nodi;
3. gerarchia;
4. modalità di partecipazione;
5. uso di `DataCommitment` come registrazione;
6. regole del calendario;
7. stati e permessi;
8. primo caso reale;
9. soltanto dopo: migrazioni, modelli, test e interfaccia.

## Checklist operativa dopo il nucleo dati

- [x] Creare route e controller per lo show pubblico del `DataEvent`.
- [x] Mostrare lo show ad albero `evento → giorno → sessione → task`.
- [x] Collegare le date della dashboard Appuntamenti allo show.
- [x] Importare in modo idempotente gli eventi PosturaCorretta dallo YAML.
- [x] Conservare immagini, tassonomie, conduttori, WhatsApp e programma nei metadata.
- [x] Collegare il modal del catalogo allo show completo importato.
- [x] Creare la richiesta di prenotazione tramite `DataCommitment`.
- [x] Permettere al superadmin di confermare o rifiutare la richiesta.
- [x] Creare il commitment dell'organizzatore con il ruolo operativo previsto quando una sessione viene confermata.
- [ ] Applicare nei controller i permessi di pubblico, partecipante e operatore.
- [ ] Generare le settimane successive associando il modulo previsto.
- [ ] Inserire indirizzo completo, capienza e prezzo oppure gratuità.
- [ ] Creare l'interfaccia amministrativa per aggiungere e modificare i `DataEvent`.

### Priorità necessarie per partire

- [ ] Inserire l'indirizzo completo della sede di Viadana di Calvisano.
- [ ] Definire la capienza delle quattro lezioni settimanali.
- [ ] Indicare se la prima lezione è gratuita oppure assegnare il prezzo.
- [x] Mostrare in 1impegno, nella sezione “Ruoli operativi” riservata al superadmin, l'elenco delle richieste `requested` filtrato per dominio.
- [x] Permettere al superadmin di confermare, rifiutare o annullare una partecipazione, liberando la capienza e chiudendo la sessione individuale creata dalla richiesta quando resta senza partecipanti.
- [x] Conservare e consultare richieste in attesa, confermate e annullate tramite filtri per stato nella console del superadmin.
- [x] Mostrare nella scheda una cronologia leggibile di invio, conferma, rifiuto, ritiro e annullamento usando i metadati di audit conservati nel commitment.
- [x] Alla conferma assegnare o creare la sessione definitiva e rendere bloccante il commitment del partecipante.
- [x] Alla conferma creare o collegare il commitment operativo dell'organizzatore.
- [x] Verificare le sovrapposizioni prima di confermare partecipante e organizzatore.
- [x] Mostrare il commitment confermato nell'agenda personale distinguendo ruolo operativo e persona rappresentata.

### Prenotazione e partecipazione

- [x] Mostrare capienza, iscritti confermati e posti ancora disponibili, bloccando nuove richieste quando la sessione è completa.
- [x] Portare lo stato delle iscrizioni a `full` al raggiungimento della capienza, contando soltanto i partecipanti confermati.
- [x] Distinguere con chiarezza evento gratuito, a pagamento o con condizioni ancora da definire.
- [x] Mostrare all'utente in italiano lo stato `requested`, `confirmed` o `cancelled`, lasciando possibile una nuova richiesta dopo l'annullamento.
- [x] Permettere all'utente di ritirare una richiesta non ancora confermata conservandone lo storico.
- [ ] Definire il comportamento di pagamento prima di aprire eventi a pagamento.

Per il pilota non viene introdotto uno stato o una coda automatica di lista
d'attesa. Quando la capienza è completa vengono bloccate nuove richieste e nuove
conferme; le richieste `requested` già presenti restano consultabili e vengono
gestite manualmente dal superadmin. Un commitment `confirmed` occupa il posto
anche se il pagamento non è ancora modellato. Prima di aprire eventi a pagamento
andranno decisi stato del pagamento, scadenza della riserva, liberazione del
posto e promozione dalla futura lista d'attesa.

La pagina pubblica mostra `Gratuito` quando il prezzo applicabile è zero, il
prezzo e la valuta quando sono valorizzati, oppure `Condizioni da definire`
quando manca ancora un accordo economico. Al momento della richiesta viene
salvata nel `agreement_snapshot` la condizione applicabile; alla conferma prezzo,
valuta e durata vengono copiati nei campi `agreed_*` del `DataCommitment`. Questo
congela l'accordo storico senza introdurre ancora incasso o stato del pagamento.

### Amministrazione degli eventi

- [x] Introdurre una vista operativa del `DataEvent` in 1impegno: albero programma e commitment collegati a ogni sessione, mantenendo separati struttura dell'attività e tempo assegnato alle persone.

- [x] Creare un form superadmin per elencare, aggiungere e modificare il `DataEvent` radice con dominio, titolo, classificazione, responsabile, stato e visibilità.
- [ ] Gestire dall'interfaccia i livelli giorno, sessione e task. Fasce `day` e sessioni sono ora creabili e modificabili; i task restano da aggiungere.
- [x] Quando il nuovo evento ha già data e orario definiti, creare automaticamente la struttura `root → day → session` rendendo prenotabile la sessione concreta.
- [ ] Selezionare dominio, responsabile, conduttori e luogo.
- [ ] Gestire stato organizzativo, visibilità, pubblicazione e iscrizioni separatamente.
- [ ] Gestire immagine, descrizione, ambiti, aree, paradigmi e messaggio WhatsApp.
- [ ] Archiviare gli eventi utilizzati; eliminare definitivamente soltanto bozze prive di collegamenti.

### Calendari e agenda

- [ ] Mostrare i `DataEvent` pubblici nel calendario del dominio PosturaCorretta.
- [ ] Mostrare nell'agenda privata i `DataCommitment` confermati della persona.
- [ ] Distinguere graficamente partecipante, insegnante, tutor, tirocinante e organizzatore.
- [ ] Mostrare in forma attenuata gli impegni degli altri domini per prevenire sovrapposizioni.
- [ ] Gestire correttamente prossimi, passati, completati e annullati.
- [ ] Evitare la duplicazione visiva tra commitment padre e figli temporali.

### Ricorrenze settimanali

- [ ] Generare le settimane successive a quella del 7–13 settembre 2026.
- [ ] Collegare a ogni settimana il modulo didattico previsto.
- [ ] Consentire la modifica di una singola data senza modificare l'intera serie.
- [ ] Consentire spostamento o annullamento di una singola ricorrenza.
- [ ] Conservare lo storico delle date confermate quando cambia la struttura ricorrente.
- [ ] Pubblicare soltanto le date verificate dall'operatore.

### Completamento della migrazione YAML

- [ ] Confrontare nello show tutti i dieci eventi importati con `eventi.yml`.
- [ ] Verificare immagini, tassonomie, luoghi, conduttori, programmi e WhatsApp.
- [ ] Rendere il database la fonte principale della pagina Eventi.
- [ ] Conservare lo YAML come archivio/importazione finché l'interfaccia amministrativa non è completa.
- [ ] Applicare migrazione e importazione idempotente anche in produzione.
- [ ] Dopo la verifica, eliminare la doppia lettura runtime YAML/database.

### Prossime evoluzioni da valutare

#### Due viste complementari di 1impegno

L'interfaccia operativa va progressivamente semplificata attorno a due viste
complementari, senza fondere i due concetti:

- **vista DataEvent**: programma e struttura `root → day → session → task`,
  persone partecipanti e ruoli operativi collegati alle sessioni;
- **vista settimana**: griglia dei `DataCommitment`, cioè tempo realmente
  assegnato a una persona, ruolo, stato e dominio.

Un organizzatore vede entrambe: nel `DataEvent` legge e organizza l'attività;
nel `DataCommitment` trova il proprio impegno di calendario. Il commitment non
duplica l'evento, ma lo collega alla persona e alla sua responsabilità.

La prima vista è ora disponibile nella console superadmin, ispirata a
`public/viste_html/0_dataevent_show.html`. È ora disponibile anche una vista
settimanale derivata da `public/viste_html/6_weekplan.html`: filtra i soli
commitment della settimana, esclude quelli annullati, distingue i brand e
collega ogni impegno operativo al relativo `DataEvent` quando accessibile.
Sarà usata per distribuire il tempo tra PosturaCorretta, Percorso Integrato,
GeneraImpresa / Rails 4 Business, comunicazioni, Il Giardino del Corpo, Canta
che ti passa e pazienti domiciliari.

#### Accesso operativo e `1impegno Plus`

Per il primo avvio la sezione **Ruoli operativi** resta accessibile soltanto al
superadmin. Insegnanti, professionisti e altri operatori possono già essere
registrati come organizzatori dei `DataEvent` e nei relativi `DataCommitment`,
ma non accedono ancora alla console operativa.

In una fase successiva l'accesso potrà essere aperto tramite due condizioni
distinte e contemporanee:

```text
attivazione di 1impegno Plus
+
ruolo operativo assegnato nello specifico dominio
```

`1impegno Plus` abiliterà le funzioni operative, mentre dominio, ruolo ed
eventuale abilitazione stabiliranno rispettivamente dove, con quali permessi e
su quali attività la persona può operare. I primi domini da valutare sono:

- PosturaCorretta;
- Percorso Integrato;
- Canta che ti passa;
- GeneraImpresa;
- Il Giardino del Corpo.

Ruoli inizialmente previsti:

- insegnante;
- professionista;
- organizzatore o conduttore;
- responsabile di sede;
- segreteria clienti;
- segreteria amministrativa.

Prima dell'apertura agli operatori andranno definite una matrice dei permessi,
le eventuali abilitazioni formative e la separazione tra visibilità, gestione e
conduzione delle attività.

#### Avvio operativo dei progetti e dei brand

L'obiettivo successivo all'MVP tecnico è costruire una settimana reale di
impegni che assegni tempo alle diverse iniziative e permetta di verificarne il
funzionamento attraverso l'agenda personale.

Ordine di valutazione proposto:

1. completare richiesta, conferma e visualizzazione in agenda;
2. impostare la prima settimana reale con impegni e ruoli;
3. attivare GeneraImpresa per tracciare il progetto Rails 4 Business;
4. usare i commitment anche per pianificare le comunicazioni;
5. avviare progressivamente PosturaCorretta, Percorso Integrato, Eventi,
   Il Giardino del Corpo e Canta che ti passa;
6. verificare carico, sovrapposizioni e tempo effettivamente dedicato prima di
   ampliare l'accesso operativo.

Da mantenere separati durante l'avvio:

- il `DataEvent` descrive progetto, evento o attività organizzata;
- il `DataCommitment` assegna persona, ruolo, tempo e stato operativo;
- GeneraImpresa aggiunge obiettivi e avanzamento ai progetti senza duplicare il
  calendario di 1impegno;
- le comunicazioni diventano task o sessioni soltanto quando vengono realmente
  pianificate e assegnate.

Durante la transizione `eventi.yml` rimane intatto e continua ad alimentare il
catalogo editoriale. Il database alimenta lo show operativo. Lo YAML potrà essere
archiviato come sorgente primaria soltanto dopo il confronto completo dei dieci
eventi importati e dopo l'introduzione dell'interfaccia amministrativa.

La prima prenotazione è intenzionalmente una richiesta: crea un solo
`DataCommitment` con stato `requested`, conserva il `requested_data_event_id` e
non blocca il calendario. Richieste duplicate attive per la stessa persona e lo
stesso evento non vengono create. L'assegnazione definitiva della sessione e il
blocco del calendario avverranno con la conferma del superadmin.

## Documenti collegati

- [Avvio piattaforma PosturaCorretta](avvio_piattaforma_posturacorretta.md)
- [Architettura Impegno ed eventi](../impegno_eventi_architettura.md)
- [Vocabolario Impegno e brand](../vocabolario_impegno_e_brand.md)
- [Eventi trasversali ai domini](../eventi_trasversali_domini.md)
- [Esperienze, eventi e commitment](../esperienze_eventi_commitment.md)
