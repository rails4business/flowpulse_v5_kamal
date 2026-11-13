# PosturaCorretta: servizi, dashboard e linee metropolitane

## Stato del documento

Bozza di progettazione aggiornata il **12 novembre 2026**, da rivedere **un punto alla volta** prima di stabilizzare il modello definitivo.

Questo documento conserva integralmente le idee emerse, distingue le decisioni dalle ipotesi e impedisce che l'integrazione delle pagine esistenti faccia perdere dati o funzionalità.

## Visione generale

PosturaCorretta deve diventare un unico ingresso comprensibile per il paziente. La persona deve poter:

1. trovare i servizi da un solo menu;
2. aprire una landing coerente con il dominio dal quale è partita;
3. seguire uno o più percorsi rappresentati come linee metropolitane;
4. consultare materiali registrati, programma lezioni, centri e insegnanti senza cambiare contesto;
5. vedere nella propria dashboard tutte le linee iniziate o percorse;
6. aprire successivamente una mappa generale dei percorsi e delle connessioni.

L'evoluzione dovrà poi sostenere, in quest'ordine indicativo, i ruoli:

1. utente/paziente;
2. tirocinante;
3. insegnante;
4. segreteria dei centri;
5. amministrazione.

## I tre macropunti del progetto

### Macropunto 1 — Trasportare le pagine nella nuova esperienza

Integrare progressivamente nella nuova home e nelle sue tab le funzioni oggi distribuite fra:

- `/percorso-posturacorretta`;
- `/posturacorretta/lezioni`;
- `/posturacorretta/insegnanti`;
- `/posturacorretta/lezioni/centri`.

Le pagine precedenti restano disponibili finché la nuova versione non contiene davvero le stesse informazioni e funzioni. Solo dopo verifica potranno essere reindirizzate e rimosse.

### Macropunto 2 — Home delle linee e prima linea standard

La home non deve necessariamente elencare le linee nel nav. Può diventare il luogo nel quale la persona **sceglie quale linea metropolitana iniziare o continuare**.

La linea attualmente rappresentata in PosturaCorretta è già la prima candidata:

- è la più semplice;
- è la più realizzabile con i dati presenti;
- parte da `La prima settimana con PosturaCorretta`;
- possiede già un programma e delle lezioni;
- prosegue lungo la sequenza dei corsi dell'area Massaggio e recupero;
- ha una durata che deve ancora essere calcolata con precisione.

Questa prima linea deve diventare il prototipo completo per materiali, programma lezioni, centri, insegnanti, progresso personale e rappresentazione nella dashboard.

Prima separazione implementata:

```text
/posturacorretta
└─ home di orientamento e scelta delle linee

/posturacorretta/percorsi/postura-recupero
└─ prima linea metropolitana, con tappa e tab conservate nei parametri
```

La CTA pubblica usa il testo **Inizia il percorso PosturaCorretta** / **Inizia con la Prima settimana**. Le linee future sono presentate in sezioni distinte come `Prossimamente`; il menu della home rimanda alle sezioni tramite anchor.

### Decisione aggiornata: la Prima settimana è un ingresso autonomo

La `Prima settimana con PosturaCorretta` non è soltanto il primo tratto di un pacchetto più lungo. È un'offerta autonoma che permette alla persona di iniziare, capire il metodo e scegliere successivamente come proseguire.

La sua conclusione introduce l'area Massaggio e recupero, ma non obbliga ad acquistare subito il percorso successivo.

```text
Prima settimana con PosturaCorretta
├─ termina qui
├─ Pacchetto Igiene Posturale
├─ Percorso completo Area Massaggio e recupero
└─ Postura e fisiologia [offerta autonoma, inizialmente futura]
```

La Prima settimana può quindi essere:

- acquistata e completata da sola;
- riconosciuta dentro un'offerta successiva senza essere ripetuta;
- usata come stazione di interscambio verso più linee;
- seguita, in futuro, da offerte ulteriori non ancora pubblicate.

#### Offerta 1 — Prima settimana

```text
La prima settimana con PosturaCorretta
└─ 1 incontro di avvio
```

Obiettivo: avviare la persona, presentare il percorso, osservare il corpo e permettere un primo contatto senza richiedere subito un impegno lungo. Nella parte conclusiva presenta anche l'Area Massaggio e recupero e le possibilità di prosecuzione.

#### Offerta 2 — Pacchetto Igiene Posturale

La proposta può includere e riconoscere quanto svolto nella Prima settimana e proseguire con il programma di Igiene Posturale:

```text
Prima settimana con PosturaCorretta [inclusa o già riconosciuta]
→ Igiene Posturale — Mobilità articolare
→ Igiene Posturale — Punti di tensione
→ Igiene Posturale — Vie di discesa
→ Igiene Posturale — Recettori sensoriali
```

L'introduzione all'Area Massaggio e recupero rimane dentro la Prima settimana. Non diventa, per ora, una seconda offerta obbligatoria o una stazione commerciale separata.

#### Offerta 3 — Percorso completo Area Massaggio e recupero

Prosegue lungo tutta la prima linea e comprende i corsi e gli incontri successivi dell'area. La denominazione commerciale, la durata e il numero definitivo di incontri devono ancora essere stabiliti.

#### Offerta autonoma — Postura e fisiologia

`Postura e fisiologia` non è il quarto pacchetto della linea Massaggio e recupero. È una linea e un'offerta autonoma:

```text
Postura e fisiologia
→ presentazione delle cinque aree
→ scelta delle aree da conoscere o attivare
```

In una prima fase può essere proposta dopo la Prima settimana. In futuro potrà avere anche un proprio ingresso diretto. Da questa linea potrà inoltre nascere il ramo professionale `Diventa insegnante PosturaCorretta`.

#### Regole funzionali da progettare

- un'offerta può includere una linea intera oppure soltanto un suo tratto;
- una stazione didattica non coincide necessariamente con un'offerta acquistabile;
- completare la Prima settimana deve essere riconosciuto entrando successivamente in Igiene Posturale o nel percorso completo;
- non bisogna duplicare stazioni, progressi o lezioni;
- una stazione può costituire un ingresso, un'uscita o un interscambio fra più linee;
- centri e insegnanti possono offrire uno o più pacchetti o linee;
- prezzo, iscrizione, calendario e disponibilità appartengono all'offerta concreta, non alla definizione astratta della linea;
- la dashboard deve mostrare l'offerta scelta e il tratto complessivamente percorso;
- ciò che è già stato completato deve poter essere riutilizzato senza un nuovo acquisto o una ripetizione obbligatoria.

### Revisione necessaria della nuova home

La home appena introdotta è soltanto una prima struttura tecnica e deve essere semplificata prima di aggiungere altre funzioni.

Principi da seguire:

- ogni sezione presenta **una sola linea narrativa e una sola decisione principale**;
- non mostrare tutte le possibilità contemporaneamente;
- partire dalla Prima settimana come offerta autonoma e mostrare con chiarezza le prosecuzioni;
- inserire chiaramente **Postura e fisiologia** nella home;
- presentare le possibilità future soltanto dopo aver spiegato il primo percorso;
- evitare che sezioni, linee e punti di ingresso sembrino alternative equivalenti quando appartengono invece a livelli diversi;
- rivedere testi, gerarchia e CTA una sezione alla volta.

Ordine proposto per la revisione della home:

1. hero e promessa principale;
2. Prima settimana e possibili prosecuzioni;
3. spiegazione della prima linea;
4. sezione Postura e fisiologia;
5. soltanto dopo, gli altri ingressi e le linee future.

### Macropunto 3 — Linee personalizzate generate da protocolli professionali

In una fase successiva un professionista potrà programmare una linea personalizzata partendo da un protocollo.

Il Percorso Integrato è il primo caso evidente, ma **non è l'unico ambito possibile**. Una linea personalizzata può nascere ovunque esista un Node che dichiara che i professionisti dispongono di un protocollo per aprire nuovi percorsi personalizzati.

Il Node rappresenta quindi:

- il punto di partenza;
- il protocollo o il contesto autorizzante;
- l'identità pubblica e stabile dalla quale nasce il percorso.

Le tappe personalizzate non diventano necessariamente nuovi Node. Vengono pianificate attraverso Data Commitment, Data Session e Data Slot secondo il modello ancora da definire.

Questo macropunto viene affrontato per ultimo, dopo aver stabilizzato la prima linea standard e la dashboard utente.

## 1. Un unico menu `Servizi`

### Idea

Il nav pubblico dovrebbe avere un solo dropdown **Servizi**. Ogni voce apre una landing del servizio.

### Requisito di continuità

La landing dovrebbe aprirsi nel dominio in cui si trova già la persona, anche quando il servizio o il percorso appartiene concettualmente a un altro dominio. L'obiettivo è evitare che il paziente cambi improvvisamente identità visiva, navigazione o dominio e si disorienti.

Esempio concettuale:

```text
posturacorretta.org
└─ Servizi
   └─ Percorso Integrato
      └─ landing contestualizzata in PosturaCorretta
```

### Questione ancora aperta

Bisogna decidere se la landing sia:

- una presentazione locale del servizio che mantiene il dominio corrente e rimanda al dominio proprietario solo quando necessario;
- la stessa pagina Node renderizzata con il tema e il nav del dominio corrente;
- una pagina canonica del dominio proprietario, raggiunta però solo dopo una spiegazione esplicita del cambio di ecosistema.

### Vincoli da non perdere

- Non duplicare i contenuti editoriali in più record indipendenti.
- Conservare una URL canonica chiara per SEO.
- Separare il **proprietario del servizio** dal **dominio che lo presenta**.
- Non perdere nel cambio di dominio la sessione, il percorso scelto o la stazione selezionata.
- Il nav e la landing devono far capire quando un servizio appartiene anche a un altro progetto, senza costringere subito l'utente a cambiare sito.

### Direzione iniziale suggerita, da confermare

Usare un unico Node del servizio e renderizzarlo nel contesto del dominio corrente. Il dominio proprietario rimane il riferimento canonico; il dominio ospitante presenta una vista contestuale. La decisione SEO e il comportamento dei link esterni vanno definiti prima dell'implementazione.

## 2. La linea metropolitana come modello riutilizzabile

### Idea

Una linea metropolitana è una sequenza ordinata di stazioni/Node. Può essere mostrata in:

- Percorso online;
- Programma lezioni;
- Centri;
- Insegnanti;
- in futuro Tirocinio;
- dashboard utente;
- mappa generale.

La stessa linea cambia stato e disponibilità in base alla tab e alla risorsa selezionata, ma non cambia identità.

### Ipotesi iniziale sul Node

È stata proposta la possibilità di aggiungere al Node:

- un booleano `linea_metropolitana`;
- uno spazio per inserire le stazioni della linea.

Questa soluzione è semplice, ma rischia di essere insufficiente perché:

- una linea possiede un ordine, un nome e una propria identità;
- lo stesso Node può comparire in linee diverse;
- una stazione può essere attraversata più volte;
- possono esistere più dime dello stesso percorso;
- servono versioni e modifiche senza alterare i percorsi già iniziati;
- la disponibilità cambia per centro, insegnante, ruolo e modalità.

### Alternativa da valutare

Trattare la linea come una **dima/template** distinta dal Node, eventualmente modellata con la logica di Rails4Business:

```text
LineTemplate
├─ nome
├─ slug
├─ dominio/proprietario
├─ stato e versione
└─ LineStationTemplate[]
   ├─ node_id
   ├─ posizione
   ├─ tipo di passaggio
   ├─ obbligatoria/opzionale
   └─ regole di disponibilità
```

Il Node potrebbe comunque avere un indicatore derivato come `metro_line?`, ma l'elenco delle stazioni non dovrebbe necessariamente vivere in un singolo campo del Node.

### Uso iniziale di YAML e futuro database

Possibile progressione:

1. definire le dime in YAML per stabilizzare struttura e vocabolario;
2. importarle come record versionati;
3. aggiungere l'editor soltanto quando il modello è stabile;
4. collegare in seguito eventi e Data Commitment senza eliminare la sorgente YAML.

Questa progressione è un'ipotesi, non ancora una decisione.

## 2A. Due famiglie di linee

### Linee standard create dal creator

Sono strade già progettate e pubblicate. Usano Node esistenti come stazioni e contenitori di identità, contenuti e relazioni.

Esempio iniziale:

```text
La prima settimana con PosturaCorretta
→ Area Massaggio e recupero
→ Igiene Posturale
→ Principi di Fisioterapia
→ …
```

Caratteristiche:

- ordine e stazioni sono stabiliti dal creator;
- le stazioni principali sono Node;
- i contenuti pubblicati sono collegati ai Node;
- il programma delle lezioni è già definito;
- centri e insegnanti indicano dove la linea è concretamente disponibile;
- ogni persona vede quali tratti ha percorso.

Perché una strada standard sia considerata pubblicata e percorribile nella parte `Percorso online`, dovrà essere associata al Data Commitment di chi l'ha pubblicata, insieme al Node e al contenuto. Il dettaglio delle relazioni deve essere progettato senza confondere:

- pubblicazione/autorialità della strada;
- accesso della persona;
- completamento personale di una stazione;
- prova o evento che attesta il passaggio.

### Linee personalizzate create da professionisti

Non richiedono la creazione di un nuovo Node per ogni tappa. Partono da un Node che espone un protocollo professionale e poi vengono programmate per una persona o un gruppo.

Esempi possibili:

- Percorso Integrato personalizzato;
- protocollo sanitario, educativo o di benessere collegato a un altro Node;
- percorso costruito da un professionista a partire da una valutazione o da un obiettivo.

Struttura concettuale:

```text
Node con protocollo professionale
└─ linea personalizzata
   ├─ Data Commitment: obiettivi, accordi, tappe o risultati attesi
   ├─ Data Session: incontri, visite, trattamenti o momenti di lavoro
   └─ Data Slot: data, orario, disponibilità o collocazione della sessione
```

La responsabilità precisa di ciascun oggetto è ancora da confermare. In particolare va chiarito se una tappa personalizzata sia un Data Commitment, una Data Session, oppure una relazione fra i due.

### Protocollo professionale sul Node

Non basta un booleano generico `linea_personalizzata`. Il Node dovrebbe poter indicare almeno:

- che esiste un protocollo utilizzabile dai professionisti;
- quali ruoli possono usarlo;
- quale dima o regola iniziale propone;
- quali dati sono obbligatori per aprire la linea;
- se il percorso è individuale o di gruppo;
- quali tipi di incontri, visite o trattamenti possono essere programmati.

La configurazione concreta può inizialmente essere YAML o una relazione dedicata; non è ancora deciso se debba diventare un campo diretto del Node.

## 2B. Lezioni, incontri ed eventi

### Linee standard

Una lezione concretamente programmata deve avere:

- un Evento;
- un insegnante;
- una Data Session;
- uno o più Data Slot;
- il Node della stazione/corso standard a cui appartiene.

La modalità della lezione potrà essere in presenza, online o ibrida. L'aula online, quando presente, appartiene alla lezione programmata.

### Linee personalizzate

Incontri, visite e trattamenti vengono programmati dal professionista. La linea conserva il Node iniziale del protocollo, ma le singole tappe operative non devono essere trasformate automaticamente in Node pubblici.

Queste tappe useranno Data Commitment, Data Session, Data Slot ed eventualmente Eventi. Va ancora deciso quando serva un Evento esplicito e quando Data Session/Data Slot siano sufficienti.

## 2C. Evoluzione delle sorgenti YAML

Gli YAML restano utili durante la costruzione perché rendono verificabili ordine, nomi e relazioni della prima linea.

Quando saranno stabili:

1. Node e contenuti pubblicati potranno essere governati dai Data Commitment del creator;
2. lezioni effettive saranno governate da Eventi, Data Session e Data Slot;
3. progressi personali saranno registrati come istanze e passaggi, senza modificare la dima;
4. gli YAML potranno smettere di essere la sorgente operativa principale.

Non vanno però eliminati prima di aver definito importazione, migrazione, versionamento, rollback e ricostruzione dei dati. La loro eventuale rimozione è una fase finale, non un prerequisito.

## 2D. Mappa metropolitana amministrativa

### Scopo

Prima di costruire altre home o offerte è necessario un primo strumento amministrativo semplice con cui il creator possa descrivere la rete senza modificare a mano la visualizzazione.

La mappa amministrativa deve permettere di distinguere e collegare:

- **Node**, che forniscono identità stabile e contenuto editoriale;
- **stazioni**, cioè la presenza di un Node o di una tappa dentro una linea;
- **linee**, cioè sequenze ordinate e versionabili di stazioni;
- **percorsi**, cioè tratti o combinazioni di una o più linee;
- **offerte**, cioè ciò che può essere proposto, acquistato o attivato;
- **ingressi**, **uscite** e **interscambi**, che descrivono dove una persona può iniziare, terminare o cambiare linea.

Questi concetti non devono essere compressi in un solo booleano sul Node.

### Relazioni minime

```text
Node
  ↑ collegato a
Stazione della linea
  ↑ ordinata dentro
Linea standard versionata
  ↑ usata da
Percorso o tratto
  ↑ incluso in
Offerta
```

Una stazione può avere contemporaneamente più funzioni:

- tappa didattica;
- ingresso acquistabile;
- uscita valida;
- interscambio verso un'altra linea;
- stazione inclusa in più offerte.

Per questo ingresso e uscita sono proprietà della stazione **nel contesto di una linea o di un'offerta**, non caratteristiche assolute del Node.

### Esempio iniziale PosturaCorretta

```text
Offerta: Prima settimana
└─ linea/stazione: Prima settimana con PosturaCorretta
   ├─ uscita: termina il percorso introduttivo
   ├─ interscambio: Pacchetto Igiene Posturale
   ├─ interscambio: Percorso completo Area Massaggio e recupero
   └─ interscambio futuro: Postura e fisiologia
```

`Postura e fisiologia` rimane un'offerta e una linea autonoma. Può inizialmente essere raggiunta dopo la Prima settimana e, in futuro, acquisire anche un ingresso diretto.

### Primo prototipo da progettare dopo l'approvazione del documento

Il primo prototipo deve essere deliberatamente piccolo e amministrativo. Non deve ancora gestire acquisti, calendari o progressi personali.

Funzioni minime:

1. creare o modificare una linea;
2. scegliere il dominio e il creator proprietario;
3. aggiungere Node esistenti come stazioni;
4. ordinare le stazioni;
5. marcare una stazione come ingresso, uscita o interscambio;
6. collegare una prosecuzione verso un'altra linea;
7. definire quali tratti sono inclusi in una prima offerta descrittiva;
8. vedere un'anteprima metropolitana della struttura.

Prima dima da usare nel prototipo:

```text
Prima settimana
→ Igiene Posturale
→ prosecuzione Area Massaggio e recupero

Prima settimana
↘ Postura e fisiologia [diramazione futura]
```

I dati del prototipo possono iniziare in YAML, purché la struttura rappresenti già entità separate e sia importabile in record versionati. Non si aggiungono ancora campi definitivi o migrazioni finché il prototipo non chiarisce il vocabolario.

### Decisione sul primo livello di rappresentazione

La prima mappa non deve dedurre linee colorate dalla gerarchia dei Node. Finché il superadmin non avrà definito le linee, mostra soltanto l'infrastruttura esistente:

- Node come stazioni;
- relazioni parent/children come binari grigi continui;
- `node_link` come binari grigi tratteggiati;
- colore del Node conservato sulla stazione;
- nessuna interpretazione automatica dei rami come linee di viaggio.

Le linee colorate saranno un livello successivo, esplicitamente creato e nominato dal superadmin. In questo modo la topologia esistente non viene confusa con una linea didattica o commerciale già approvata.

La disposizione della mappa usa un algoritmo dedicato `metro_schematic_layout`, indipendente dai layout radiale, a corsie e della rete globale. Il motore assegna binari alle diramazioni, riduce gli incroci attraverso un albero di supporto e produce esclusivamente segmenti orizzontali, verticali o diagonali a 45°. Tutti i collegamenti reali restano visibili anche quando non appartengono all'albero di supporto.

Le coordinate manuali non appartengono al Node: vengono salvate per la coppia `mappa + Node`. Il titolo rimane invece canonico sul Node e si modifica nel suo editor, così tutte le mappe continuano a usare lo stesso nome senza introdurre etichette divergenti.

## 2E. Mappe provvisorie create dai professionisti

Le mappe provvisorie non sono pubblicate dal creator come strade standard dell'ecosistema. Nascono operativamente da un Node che autorizza l'uso di un protocollo professionale.

```text
Node con protocollo
└─ istanza provvisoria del percorso
   ├─ stazione operativa / Data Session
   ├─ stazione operativa / Data Session
   └─ Data Slot per calendario e disponibilità
```

Il termine `Data Lesson` può descrivere concettualmente una lezione, ma **non corrisponde oggi a un modello presente nell'applicazione**. Prima di introdurlo bisogna verificare se:

- la lezione è un contenuto o programma collegato al Node;
- la sua esecuzione concreta è già rappresentabile con `DataSession`;
- serve davvero una nuova entità oppure basta una tipologia di sessione.

Per ora la regola prudente è:

- il Node conserva il punto di partenza e il protocollo;
- il Data Commitment conserva obiettivi e accordi;
- la Data Session rappresenta incontro, lezione, visita o trattamento concretamente programmato;
- il Data Slot rappresenta collocazione temporale e disponibilità;
- nessuna tappa provvisoria diventa automaticamente un Node pubblico.

Le mappe provvisorie vengono implementate soltanto dopo aver validato la mappa standard del creator.

## 3. Dima e percorso realmente effettuato

### Problema centrale

Una linea teorica non coincide con il percorso di una persona.

Alcune stazioni, per esempio:

```text
Percorso Integrato → Stop al dolore
```

possono essere percorse più volte. La stessa persona può iniziare più percorsi, ripetere una tappa o usare dime diverse.

### Separazione necessaria

```text
Dima della linea
    ↓ crea
Istanza del percorso della persona
    ↓ contiene
Passaggi/stazioni effettuati
```

Modello concettuale da valutare:

```text
JourneyTemplate
JourneyTemplateStation

UserJourney
├─ user/profile
├─ template e versione usata
├─ stato
├─ data di inizio/fine
└─ UserJourneyStation[]
   ├─ station template
   ├─ node
   ├─ stato
   ├─ tentativo/ciclo
   ├─ data
   └─ eventi o Data Commitment collegati
```

### Requisiti

- La ripetizione di una stazione non deve sovrascrivere il passaggio precedente.
- Due percorsi basati sulla stessa dima devono rimanere distinti.
- Una nuova versione della dima non deve cambiare retroattivamente i percorsi già iniziati.
- I progressi devono poter essere ricostruiti dagli eventi in futuro.
- Va deciso se un passaggio ripetuto genera una nuova istanza di stazione o un nuovo `UserJourney`.

## 4. Dashboard utente

### Vista principale proposta

La dashboard utente diventa una lista in cui **ogni riga è una linea metropolitana**.

Ogni riga dovrebbe poter mostrare almeno:

- nome del percorso;
- dominio o progetto di riferimento;
- stazione attuale;
- stazioni completate, disponibili e future;
- eventuale centro o insegnante;
- data dell'ultima attività;
- stato: da iniziare, attivo, sospeso, completato;
- azione principale per continuare.

### Casi da sostenere

- più linee attive contemporaneamente;
- più istanze della stessa linea;
- stazioni ripetute;
- linea personale derivata da una dima;
- percorso registrato, in presenza, online o ibrido;
- passaggi tra domini senza perdere il contesto utente.

### Pagina mappa generale

Oltre alla lista serve una pagina separata per vedere:

- tutta la mappa delle linee disponibili;
- le linee iniziate;
- quelle completate;
- le intersezioni tra linee;
- le stazioni attraversate più volte;
- le possibili prosecuzioni.

La dashboard deve privilegiare l'azione quotidiana; la mappa generale deve privilegiare orientamento e comprensione dell'ecosistema.

### Cartina personale

Ogni persona deve avere una cartina complessiva che unisce:

- linee standard disponibili;
- tratti standard realmente percorsi;
- stazioni completate o ripetute;
- linee personalizzate programmate;
- appuntamenti, visite, trattamenti e lezioni già svolti o futuri;
- punto corrente e possibili prosecuzioni.

La cartina non deve appiattire tutto in una sola linea: deve distinguere il percorso standard condiviso dalle diramazioni personalizzate e dalle diverse istanze attraversate dalla stessa persona.

## 5. Integrazione delle pagine PosturaCorretta esistenti

### Pagine da integrare nella nuova esperienza

1. `/percorso-posturacorretta`
2. `/posturacorretta/lezioni`
3. `/posturacorretta/insegnanti`
4. `/posturacorretta/lezioni/centri`

Le funzioni di queste pagine dovrebbero confluire progressivamente in `/posturacorretta`, nelle tab e nella futura dashboard unificata.

### Corrispondenza iniziale

| Pagina attuale | Destinazione prevista |
|---|---|
| `/percorso-posturacorretta` | Percorso online, corsi, materiali e struttura del percorso |
| `/posturacorretta/lezioni` | Programma lezioni e successivamente dashboard delle lezioni personali |
| `/posturacorretta/insegnanti` | Tab Insegnanti e schede pubbliche contestuali |
| `/posturacorretta/lezioni/centri` | Tab Centri e disponibilità dei corsi per centro |

### Regola di sicurezza della migrazione

Le vecchie pagine non devono essere eliminate subito.

Ordine corretto:

1. inventario di dati, azioni, permessi e link presenti nella pagina vecchia;
2. implementazione equivalente nella nuova esperienza;
3. confronto funzionale e test;
4. periodo di compatibilità;
5. redirect dalla vecchia URL;
6. eliminazione del codice duplicato soltanto quando non è più referenziato.

### Stato attuale

Centri e Insegnanti sono già parzialmente integrati nelle tab della home PosturaCorretta. Devono però essere confrontati con le due pagine esistenti per verificare che non manchino filtri, schede, azioni, disponibilità o permessi.

## 6. Ruoli e sviluppo progressivo

### Utente/paziente — prima priorità

- scegliere un servizio;
- iniziare una linea;
- vedere materiali, programma lezioni, centri e insegnanti;
- continuare il proprio percorso;
- vedere più linee e più istanze della stessa linea.

### Tirocinante — fase successiva

- accesso condizionato dopo il completamento/iscrizione prevista;
- linea Tirocinio separata ma collegata al corso;
- attività, affiancamenti e progressi verificabili.

### Insegnante

- programma lezioni;
- lezioni in presenza, online o ibride;
- aula online collegata alla lezione programmata;
- partecipanti, materiali e avanzamento.

### Segreteria centri

- disponibilità dei corsi nel centro;
- calendario, aule, insegnanti e iscrizioni;
- associazione delle stazioni disponibili al centro.

### Amministrazione

- gestione delle dime e delle versioni;
- gestione di Node, linee, stazioni, ruoli e permessi;
- controllo delle integrazioni tra domini;
- report e audit dei percorsi.

## 7. Priorità proposta secondo i tre macropunti

### Fase 0 — analisi senza rimozioni

- Rivedere questo documento un punto alla volta.
- Fare l'inventario delle quattro pagine da integrare.
- Separare dati canonici, presentazione e funzionalità specifiche per ruolo.

### Fase 1 — trasporto delle pagine e prima linea standard

- Inventariare e integrare le quattro pagine esistenti.
- Completare nella home la prima linea che parte dalla Prima settimana.
- Calcolare e rendere esplicita la durata indicativa della linea.
- Stabilizzare Percorso online, Programma lezioni, Centri e Insegnanti.
- Non eliminare ancora le pagine precedenti.

### Fase 2 — home di scelta e modello delle linee standard

- Trasformare la home nel punto di scelta delle linee, senza caricare tutte le linee nel nav.
- Progettare il prototipo amministrativo di linee, stazioni, ingressi, uscite, interscambi e offerte.
- Tenere separati Node, stazioni, linee, percorsi e offerte.
- Validare il prototipo in YAML prima di introdurre il modello persistente definitivo.
- Collegare pubblicazione, Node, contenuto e Data Commitment del creator.
- Definire stazioni, ordine, durata, versioni e intersezioni.

### Fase 3 — lezioni reali e disponibilità

- Collegare Evento, insegnante, Data Session, Data Slot e Node.
- Gestire presenza, online e modalità ibrida.
- Mostrare sulla linea dove e con chi ogni stazione è disponibile.

### Fase 4 — dashboard utente

- Una riga/metropolitana per ogni istanza di percorso.
- Supporto a più linee e ripetizioni.
- Pagina separata con mappa generale.

### Fase 5 — servizi e continuità fra domini

- Definire il dropdown unico Servizi.
- Stabilire come renderizzare una landing di un servizio esterno nel dominio corrente.
- Definire URL canoniche, tema/nav e passaggio di contesto.

### Fase 6 — ruoli operativi

- Tirocinante.
- Insegnante.
- Segreteria centri.
- Amministrazione.

### Fase 7 — linee personalizzate, per ultima

- Definire il protocollo professionale collegato a un Node.
- Consentire l'apertura di linee personalizzate in qualunque ambito autorizzato, non soltanto nel Percorso Integrato.
- Definire tappe, incontri, visite e trattamenti con Data Commitment, Data Session e Data Slot.
- Integrare le linee personalizzate nella cartina della persona.

### Fase 8 — dismissione controllata

- Redirect delle vecchie pagine.
- Rimozione del codice duplicato.
- Verifica SEO, link interni, sitemap, analytics e permessi.

## 8. Questioni da affrontare una alla volta

Ordine suggerito per la revisione:

1. Quando un servizio appartiene a un altro dominio, che cosa deve rimanere del dominio corrente e qual è la sua URL canonica?
2. Il dropdown Servizi è configurato sul Node, sul Domain o su una struttura di navigazione separata?
3. Quali record e relazioni devono rendere persistente la dima autonoma collegata ai Node dopo il prototipo YAML?
4. Quali dati minimi definiscono una stazione?
5. Come si versiona una linea già usata da persone reali?
6. Quando una stazione ripetuta crea un nuovo passaggio e quando crea un nuovo percorso?
7. Quali funzioni precise di `/percorso-posturacorretta` devono migrare nella tab Percorso online?
8. Quali funzioni precise di `/posturacorretta/lezioni` devono migrare nella tab Programma lezioni e quali appartengono invece alla dashboard personale?
9. Che cosa manca nelle tab Centri e Insegnanti rispetto alle pagine esistenti?
10. Qual è il primo prototipo minimo della dashboard utente?
11. Come si presenta la mappa generale senza confonderla con la dashboard operativa?
12. Quali condizioni abilitano la futura linea Tirocinio?
13. Quale relazione certifica che una strada standard è stata pubblicata dal creator?
14. Che cosa registra il passaggio personale su una stazione standard?
15. Come indica un Node che contiene un protocollo utilizzabile dai professionisti?
16. In una linea personalizzata, che differenza esatta c'è tra tappa, Data Commitment e Data Session?
17. Quando una visita o un trattamento richiede anche un Evento oltre a Data Session e Data Slot?
18. Quando gli YAML potranno cessare di essere la sorgente principale senza perdere ricostruibilità?
19. Qual è il confine esatto fra linea, percorso e offerta nel primo prototipo amministrativo?
20. Un'offerta collega una linea intera, un tratto fra due stazioni oppure un insieme di stazioni non necessariamente contigue?
21. Ingresso, uscita e interscambio appartengono alla stazione nella linea, all'offerta o a entrambi con significati diversi?
22. Come si riconosce automaticamente la Prima settimana già completata entrando in un'offerta successiva?
23. `Postura e fisiologia` deve avere subito un ingresso diretto o soltanto l'interscambio dalla Prima settimana nella prima versione?
24. Una lezione operativa richiede una nuova entità `DataLesson` oppure è una tipologia di `DataSession` collegata a programma e Node?

## 9. Decisioni già ferme e ipotesi da non confondere

### Già ferme

- Un unico dropdown Servizi è l'obiettivo del nav.
- Evitare cambi di dominio disorientanti per il paziente è un requisito.
- La dashboard utente dovrà mostrare una linea metropolitana per riga.
- Deve esistere anche una pagina distinta con la mappa generale.
- Una stazione può essere percorsa più volte.
- Possono esistere più dime o più istanze di percorso.
- Le quattro pagine esistenti devono essere integrate prima di essere eliminate.
- Lo sviluppo dei ruoli parte dall'utente e prosegue con tirocinante, insegnante, segreteria e amministrazione.
- La prima linea da completare parte dalla Prima settimana ed è il prototipo più semplice e realizzabile.
- La Prima settimana è un'offerta autonoma e può terminare senza un acquisto successivo.
- La conclusione della Prima settimana introduce l'Area Massaggio e recupero e apre più possibili prosecuzioni.
- Igiene Posturale e il percorso completo Area Massaggio e recupero sono offerte successive distinte.
- Postura e fisiologia è una linea e un'offerta autonoma, inizialmente collegabile come prosecuzione e in futuro anche come ingresso diretto.
- Node, stazione, linea, percorso e offerta sono concetti distinti.
- La mappa standard viene definita dal creator e usa prevalentemente Node come stazioni.
- Le linee personalizzate vengono affrontate per ultime.
- Le linee personalizzate possono nascere da qualsiasi Node dotato di un protocollo professionale, non soltanto dal Percorso Integrato.
- Le tappe personalizzate non devono generare automaticamente nuovi Node.
- Ogni persona deve avere una cartina con linee standard percorse e linee personalizzate programmate o svolte.

### Ancora da decidere

- comportamento esatto delle landing tra domini;
- collocazione della configurazione Servizi;
- struttura persistente definitiva della dima autonoma e suoi eventuali indicatori derivati sul Node;
- uso definitivo di Rails4Business come sistema delle dime;
- struttura persistente di percorsi, tentativi e ripetizioni;
- confine tra Programma lezioni e dashboard personale;
- tempi e regole della dismissione delle vecchie pagine.
- modello esatto che collega creator, Data Commitment, Node e Content nella pubblicazione di una linea standard;
- responsabilità precise di Evento, Data Session e Data Slot e necessità eventuale di un concetto `DataLesson`;
- configurazione del protocollo professionale sul Node;
- criterio per sostituire definitivamente gli YAML come sorgente operativa.
- nome, durata, contenuti e calendario definitivi delle offerte successive alla Prima settimana;
- modello dati che distingue il tratto della linea dall'offerta commerciale del centro o dell'insegnante;
- contenuti e ordine definitivo delle sezioni della nuova home.

