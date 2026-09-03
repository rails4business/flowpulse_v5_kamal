# Avvio della piattaforma PosturaCorretta

## Priorità di lancio

L'obiettivo del primo lancio non è automatizzare l'Accademia: è permettere a una persona reale di entrare, capire il programma, vedere quando può partecipare e ritrovare ciò che sta facendo. La gestione iniziale resta nelle mani del superadmin.

### Indispensabile per il primo lancio

Prima di pubblicare date e prezzi occorre distinguere tre livelli, che non devono essere confusi:

- **Programma didattico**: un file YAML contiene tutte le sezioni, i corsi, gli incontri e le lezioni previste nell'anno. È la mappa completa e può essere mostrata nel Percorso guidato.
- **Offerte di partecipazione**: ciò a cui una persona può aderire davvero: percorso di un mese, gruppo, lezione individuale in studio, lezione individuale online, oppure singola lezione quando sarà prevista.
- **Calendario dell'insegnante**: un file separato per ogni insegnante contiene soltanto le singole date e disponibilità pubblicate, collegate a una voce del programma, a una modalità e a un luogo oppure online.

Il programma completo può essere preparato ora; al lancio saranno attive soltanto le date che Mark decide di inserire nel proprio calendario. Una lezione può quindi esistere nel programma senza essere ancora disponibile.

Le **schede** restano file dedicati e vengono richiamate dal YAML del programma: per ogni incontro o lezione conterranno obiettivo, programma, pratica, materiali e link a PDF o contenuti. Possono essere aggiunte un passo alla volta. Così la stessa voce didattica, con la stessa scheda e gli stessi moduli, può essere proposta più volte da Mark o da altri insegnanti, senza duplicare contenuti o date.

1. **Accesso PosturaCorretta**
   - registrazione e accesso nel contesto del sito;
   - profilo collegato al brand PosturaCorretta;
   - dashboard studente raggiungibile dopo l'accesso.

2. **Un solo percorso iniziale realmente utilizzabile**
   - PosturaCorretta in un mese;
   - incontro iniziale con tutor;
   - almeno una lezione Base;
   - programma e scheda dell'incontro o della lezione;
   - corso online con i primi contenuti sufficientemente chiari.

   Il percorso di un mese è la prima offerta: non è ancora un abbonamento automatico. L'adesione può includere o proporre incontro iniziale, materiali online e una lezione con insegnante; le condizioni definitive saranno rese esplicite prima della prenotazione.

3. **Calendario visibile in dashboard**
   - futuri e passati;
   - data, orario di inizio e fine, insegnante, gruppo o individuale, luogo oppure online;
   - calendario in sola lettura per studenti e altri utenti;
   - calendario modificabile soltanto dal superadmin nella prima fase.

   Nella dashboard il nome della vista personale è **Appuntamenti**. In futuro potrà raccogliere appuntamenti di tutti i domini Flowpulse, mostrando per ogni voce una pill del sito di provenienza e una pill del ruolo svolto nell'appuntamento. Dentro PosturaCorretta le voci del sito sono complete; gli impegni personali degli altri spazi restano visibili in semitrasparenza per evitare sovrapposizioni. Per ora solo il superadmin accede direttamente a 1Impegno e gestisce tutti i contesti.

4. **Orari e gruppi pubblicati da @markpostura**
   - almeno un orario individuale;
   - almeno un gruppo con giorno, orario, luogo e capienza;
   - distinzione chiara tra incontro con tutor e lezione con insegnante;
   - richiesta o prenotazione inizialmente gestibile manualmente dal superadmin.

   Le modalità da prevedere già nel modello, anche se non tutte attive il primo giorno, sono: gruppo in presenza, individuale in studio e individuale online. Ogni disponibilità deve indicare durata, capienza quando è un gruppo, luogo oppure collegamento online e insegnante.

5. **Schede e contenuti minimi**
   - una scheda concreta per ogni incontro o lezione pubblicata;
   - collegamenti ai capitoli e ai contenuti necessari;
   - indicazione onesta di ciò che è ancora in preparazione.

### Utile subito dopo il lancio

- prenotazione autonoma di individuali e gruppi;
- capienza e lista partecipanti;
- creazione automatica di `DataCommitment` per prenotazione;
- registrazione della presenza e della lezione svolta;
- dashboard con appuntamenti personali reali e avanzamento;
- primo flusso assistito per tutor e segreteria.
- adesione a un mese o a un gruppo con appuntamenti successivi già associati;
- catalogo completo delle lezioni di **Postura e Recupero**, seguito progressivamente dalle altre sezioni dell'Accademia.

### Da rimandare deliberatamente

- pagamenti automatici;
- calendario modificabile dagli studenti;
- automazione completa di gruppi, liste d'attesa e recuperi;
- attestati automatici;
- tirocinio automatizzato;
- Percorso Integrato completo e offerte definitive del dottor Damiata;
- dashboard complete per tutti i ruoli;
- tutti i corsi e tutti i contenuti pronti prima dell'avvio.

### Ordine pratico delle prossime settimane

1. Completare il profilo pubblico e l'abilitazione di **@markpostura** come insegnante.
2. Inserire nel calendario YAML soltanto le prime due date reali: incontro iniziale con tutor e lezione pratica del primo mese.
3. Completare la scheda e i materiali minimi di entrambe le attività.
4. Verificare che Appuntamenti mostri correttamente prossimi, passati e altri impegni personali senza rendere la pagina modificabile agli utenti.
5. Fare una prova completa con una persona reale: accesso, dashboard, modulo, appuntamento, scheda e storico.
6. Aggiungere un primo gruppo di Igiene Posturale soltanto dopo la prova del flusso iniziale.
7. Solo dopo questa verifica, introdurre una richiesta di prenotazione con conferma manuale del superadmin.
8. Solo quando il flusso manuale funziona, decidere se introdurre prenotazione autonoma e `DataCommitment` automatico.

**Prima priorità attuale:** pubblicare un primo appuntamento reale di @markpostura, con scheda collegata, e provarne tutto il percorso con una persona reale.

### Prossimo flusso da rendere reale

Non aggiungere per ora altri ruoli, automazioni o pagamenti. Lavorare soltanto su questo percorso:

1. Inserire **@markpostura** come insegnante attivo e completare la sua pagina pubblica essenziale.
2. Pubblicare nel calendario YAML una prima data reale per l'**incontro iniziale con tutor** e una per la **lezione pratica del primo mese**. Se viene definito, aggiungere anche un primo gruppo di Igiene Posturale.
3. Collegare ogni data a una scheda concreta: obiettivo, programma, pratica e materiali o PDF disponibili.
4. Lasciare **Appuntamenti** in sola lettura: dentro PosturaCorretta mostra gli appuntamenti del sito normalmente e gli impegni personali di altri spazi in semitrasparenza, per evitare sovrapposizioni.
5. Fare una prova completa: registrazione → dashboard → modulo → appuntamento → scheda → storico.
6. Solo dopo questa prova introdurre una richiesta di prenotazione con conferma manuale del superadmin.

L'accesso operativo a 1Impegno resta visibile soltanto al superadmin. Gli altri utenti usano la vista Appuntamenti di PosturaCorretta.

## Architettura minima di Impegno e integrazione con i brand

Questa sezione definisce il lavoro da valutare prima di aggiungere nuove fonti YAML, modelli o migrazioni. L'obiettivo è fare convergere in Impegno calendario, disponibilità, lezioni, servizi, percorsi, eventi, routine e attività progettuali, lasciando a ogni brand la proprietà dei propri contenuti e programmi.

Lo schema centrale da verificare è:

```text
Brand / Dominio
└── Proposta
    ├── Scheda e programma
    ├── Ruoli necessari
    ├── Modalità di partecipazione
    └── Edizioni o ricorrenze
        ├── eventuali slot
        └── adesioni o prenotazioni
            └── DataCommitment
```

Routine, Percorsi, Classi, Corsi, Eventi, Servizi e Progetti non devono necessariamente introdurre calendari separati: possono essere tipologie e viste specializzate costruite sopra una struttura condivisa.

### 1. Vocabolario comune

Definire i nomi e i confini di Proposta, Scheda, Programma, Edizione o Occorrenza, Slot, Partecipazione e DataCommitment. Lo stesso termine non deve indicare contemporaneamente un contenuto riutilizzabile, una data reale e la presenza di una persona.

Il glossario viene compilato e verificato in [Vocabolario comune di Impegno e dei brand](../vocabolario_impegno_e_brand.md).

### 2. Proposta

La Proposta descrive ciò che può essere offerto o ripetuto senza dipendere da una data specifica. Può rappresentare una lezione, un incontro con tutor, una prestazione, una classe, un corso, un evento, una routine o un'attività progettuale.

### 3. Scheda e programma

Ogni proposta può avere una Scheda con obiettivo, preparazione, durata, materiali, pratica, verifiche e collegamenti. Il Programma ordina uno o più moduli o attività che compongono la proposta. Va chiarito quali dati appartengono alla Scheda e quali al Programma per non ripeterli nelle date.

### 4. Tipologie condivise

Definire Routine, Percorso, Classe, Corso, Evento, Servizio e Progetto come tipologie funzionali. Devono condividere la base comune e aggiungere soltanto le regole realmente specifiche del proprio caso.

### 5. Edizione o occorrenza

Rappresenta la realizzazione concreta e datata di una proposta: inizio, fine, luogo o collegamento online, conduttori, capienza, stato, prezzo eventuale, dominio e progetto coinvolti. Una proposta ricorrente può generare più occorrenze.

### 6. Disponibilità e slot

La disponibilità descrive una fascia offerta da una persona, un luogo o una risorsa e non deve necessariamente occupare il calendario. Gli slot dividono una disponibilità quando occorre scegliere un appuntamento individuale. Una lezione di gruppo già fissata può essere una singola occorrenza senza ulteriori slot.

### 7. Partecipazioni e prenotazioni

La Partecipazione collega una persona a un'occorrenza o a uno slot e conserva richiesta, conferma, presenza, assenza, annullamento ed eventuale stato economico. Una partecipazione confermata può generare o collegare il relativo DataCommitment.

### 8. DataCommitment

Resta l'unica fonte di verità per ciò che occupa realmente un calendario. Deve poter indicare calendario, dominio, ruolo svolto, proposta o progetto collegato, inizio, fine, stato, blocco del calendario ed eventuale valore economico o temporale.

Può rappresentare, tra gli altri, una presenza a lezione, un appuntamento, una routine eseguita, una scadenza, un'attività GeneraImpresa, una partecipazione a un evento o un'attività organizzativa.

### 9. Ruoli contestuali

Il ruolo deve essere legato al profilo e al dominio o progetto. La stessa persona può essere studente o insegnante in PosturaCorretta, tutor o professionista nel Percorso Integrato, organizzatore nel Giardino del Corpo e lavoratore o responsabile in GeneraImpresa.

```text
Profilo + dominio o progetto + ruolo
```

### 10. Viste Routine, Percorsi, Classi, Corsi ed Eventi

Recuperare le suddivisioni utili già presenti nel prototipo di Impegno come viste specializzate, non come fonti dati indipendenti.

Area personale:

```text
Agenda
Routine
Percorsi
Classi
Corsi
Eventi
```

Area operativa:

```text
Agenda
Disponibilità
Servizi
Percorsi
Classi
Corsi
Eventi
```

### 11. Organizzazione della settimana

La vista settimanale deve riunire impegni personali, lezioni condotte, partecipazioni, appuntamenti professionali, gruppi, routine, attività progettuali e disponibilità prenotabili. Dominio, ruolo, tipologia e stato devono essere riconoscibili senza creare calendari duplicati.

### 12. Regole di ricorrenza

Definire come routine quotidiane, classi settimanali, lezioni periodiche, disponibilità e incontri ripetuti generano occorrenze entro un intervallo limitato, conservando eccezioni, cancellazioni e storico.

### 13. Confini tra i brand

- **Impegno** possiede calendario, disponibilità, occorrenze, slot, prenotazioni e commitment.
- **PosturaCorretta** possiede programmi educativi, schede e moduli.
- **Percorso Integrato** possiede percorsi, programmi professionali e servizi.
- **GeneraImpresa** possiede progetti, fasi, step e task.
- **Giardino del Corpo** possiede filosofia, esperienze ed eventi.
- **Canta che ti passa** possiede corsi, incontri, prove ed esercitazioni.

Ogni brand descrive il proprio contenuto; Impegno lo trasforma in tempo organizzato e partecipazioni reali.

### Ordine di analisi

I tredici punti devono essere considerati uno alla volta, nello stesso ordine. Prima di creare tabelle o migrazioni vanno stabilizzati almeno: vocabolario, Proposta, Scheda e Programma e tipologie condivise.

## TODO operativo

Questa è la checklist principale per l'avvio. Va aggiornata nello stesso momento in cui una funzione viene completata e verificata. Non aprire il blocco successivo finché il flusso minimo del blocco corrente non funziona con una persona reale.

### Blocco 1 — Registrazione e accesso PosturaCorretta

- [x] Riconoscere automaticamente il contesto PosturaCorretta su `posturacorretta.org`.
- [x] Riconoscere il contesto PosturaCorretta nei percorsi locali `/posturacorretta/...`.
- [x] Mostrare logo, titolo, descrizione, colori e navigazione PosturaCorretta nelle pagine di registrazione e accesso.
- [x] Conservare una destinazione `return_to` interna e sicura.
- [x] Dopo la registrazione collegare o riattivare il profilo al dominio con `DomainMembership` e, quando il dominio ha un nodo, anche al brand con `TravelerSubscription`.
- [x] Dopo accesso o registrazione tornare alla dashboard, alla lezione o alla pagina inizialmente richiesta.
- [x] Mantenere un solo account e una sola autenticazione per tutta la piattaforma.
- [x] Verificare registrazione, accesso, errori, uscita e nuovo accesso sia da localhost sia dal dominio.

**Completato quando:** un nuovo utente entra da PosturaCorretta, crea l'account, ritorna alla dashboard PosturaCorretta e al successivo accesso ritrova lo stesso profilo senza vedere Flowpulse o dover effettuare un secondo login.

### Collegamento del profilo al sito e al brand

L'accesso distingue il **brand** dal singolo hostname:

- quando il dominio è collegato a un `Node`/brand, l'appartenenza al brand viene rappresentata da una `TravelerSubscription` identificata da `profile_id + node_id`;
- nello stesso caso viene mantenuta anche una `DomainMembership`, che registra a quale specifico dominio del brand la persona ha aderito;
- quando il dominio è autonomo e non possiede un nodo, l'appartenenza viene rappresentata da una `DomainMembership` identificata da `profile_id + domain_id`;
- una `DomainMembership` su un dominio appartenente a un brand registra l'accesso allo specifico hostname, ma non sostituisce l'iscrizione al brand;
- `DomainMembership` non salva un `traveler_subscription_id`: l'eventuale relazione viene ricostruita tramite profilo e `domain.node_id`, evitando due fonti di verità.

Se un brand possiede più domini, nel selettore compare una sola volta. Il dominio determina routing, configurazione grafica e host; la `TravelerSubscription` determina l'appartenenza al brand. Registrazione e accesso restano comuni: non sono richiesti un secondo account o una seconda autenticazione.

**Stato locale:** è stato creato il Node `PosturaCorretta`, appartenente al Creator world di `@markpostura`, e `posturacorretta.org` è stato collegato sia al nodo sia al relativo `RoleAssignment`.

**Stato in produzione:** il Node PosturaCorretta e il collegamento del dominio sono stati configurati; il flusso di autenticazione è stato verificato ed è considerato chiuso.

Il collegamento è ripetibile in modo idempotente con:

```bash
bin/rails brands:setup_posturacorretta
```

Per usare un proprietario diverso da `@markpostura`:

```bash
POSTURACORRETTA_OWNER=username bin/rails brands:setup_posturacorretta
```

#### Implementazione del Blocco 1 — un punto alla volta

Le route restano comuni a tutti i siti:

- `/session/new` per l'accesso;
- `/users/new` per la registrazione.

Non vanno create nuove route di autenticazione per ogni brand. In produzione il sito viene riconosciuto dal dominio; su localhost si può usare temporaneamente un parametro `site` verificato dal server.

##### Punto 1 — Registro dei contesti di autenticazione

- [x] Usare `config/domains.yml` come configurazione distribuibile dei siti.
- [x] Usare la tabella `domains` e il modello `Domain` come fonte utilizzata durante l'esecuzione.
- [x] Non introdurre un secondo file YAML per i contesti di autenticazione.
- [x] Continuare a importare la configurazione nel database tramite `bin/rails domains:import` o la procedura amministrativa equivalente.
- [x] Usare `Current.domain` e l'host della richiesta per riconoscere automaticamente il sito in produzione.
- [x] Non esporre né accettare direttamente un `domain_id` come identificatore pubblico del contesto.
- [x] Aggiungere lo slug pubblico e stabile `auth_slug: posturacorretta`.
- [x] Aggiungere la destinazione predefinita `auth_default_path: /posturacorretta/dashboard`.
- [x] Aggiungere `auth_enabled: true`.
- [x] Completare `logo_full_url` e `logo_square_url` usando gli asset ImageKit già presenti nel sito.
- [x] Definire il comportamento generale Flowpulse quando non esiste un sito specifico: accesso comune, nessuna adesione automatica, ritorno alla pagina richiesta o al profilo.

**Decisione:** `config/domains.yml` e `Domain` costituiscono insieme l'unica fonte del contesto. Il file YAML permette di distribuire e versionare la configurazione; il database viene interrogato dall'applicazione. Titolo, descrizione, favicon, immagine sociale e loghi non devono essere duplicati altrove.

**Prossima azione del Punto 1:** iniziare il Punto 2 e risolvere il contesto attraverso `Current.domain` o `auth_slug` in locale.

##### Punto 2 — Risoluzione del contesto

- [x] Usare prima `Current.domain` quando la richiesta arriva da un dominio reale.
- [x] Usare `params[:site]` soltanto in locale o negli ambienti in cui più siti condividono lo stesso host.
- [x] Convalidare lo slug cercando esclusivamente domini attivi con `auth_slug` corrispondente.
- [x] Usare il contesto generale quando dominio e parametro non identificano un sito.
- [x] Non usare il parametro per concedere ruoli o autorizzazioni.

**Implementato:** `AuthenticationBrandContext` risolve il sito dal dominio reale o, solo in locale, da `site`. I link PosturaCorretta e i reindirizzamenti delle pagine protette mantengono il contesto quando necessario.

##### Punto 3 — Conservazione durante il flusso

- [x] Conservare temporaneamente lo slug nella sessione durante accesso e registrazione.
- [x] Conservare una sola destinazione `return_to` interna e verificata.
- [x] Mantenere contesto e destinazione quando il form presenta errori.
- [x] Eliminare la destinazione temporanea quando il flusso è concluso.

**Regola di sicurezza:** sono ammessi solo percorsi relativi interni. URL assoluti, destinazioni che iniziano con `//`, backslash e caratteri di controllo sono ignorati. In contesto PosturaCorretta sono ammessi solo percorsi che iniziano con `/posturacorretta`; negli altri casi il ritorno di ripiego è la dashboard configurata nel dominio.

##### Punto 4 — Form comuni brandizzati

- [x] Fare leggere a `/session/new` e `/users/new` il contesto risolto.
- [x] Mostrare logo, nome, colori, testi e navigazione del sito.
- [x] Conservare contesto e `return_to` nei collegamenti tra registrazione e accesso.
- [x] Evitare riferimenti visibili a Flowpulse quando il contesto è PosturaCorretta.
- [x] Mantenere accessibili le pagine anche senza contesto specifico.
- [x] Reindirizzare gli utenti già autenticati: dashboard del sito nel contesto brandizzato, profilo nel contesto generale.

##### Punto 5 — Sicurezza della destinazione

- [x] Accettare esclusivamente percorsi interni.
- [x] Rifiutare URL assoluti, destinazioni con `//` e host esterni.
- [x] Verificare che la destinazione sia coerente con il sito quando è presente un contesto specifico.
- [x] Usare la dashboard del sito come destinazione di ripiego.

##### Punto 6 — Registrazione e collegamento al brand o al sito

- [x] Creare `User` e `Profile` con la procedura comune.
- [x] Se il dominio ha un nodo, creare o riattivare sia la `TravelerSubscription` del profilo per il brand sia la `DomainMembership` per lo specifico dominio.
- [x] Se il dominio non ha un nodo, creare o riattivare la `DomainMembership` per quel sito autonomo.
- [x] Evitare duplicati quando più domini appartengono allo stesso nodo.

**Implementato:** login, registrazione e dashboard usano `ensure_current_user_site_access!`. Il metodo mantiene sempre la `DomainMembership`; quando è presente `domain.node_id`, mantiene anche la `TravelerSubscription`, cercata per `profile_id + node_id` e non per hostname.
- [x] Eseguire creazione dell'account e collegamento in modo atomico.
- [x] Avviare una sola sessione dopo il completamento della transazione.
- [x] Reindirizzare alla destinazione richiesta.

Il dominio destinato all'iscrizione gratuita non viene più esposto tramite un ID numerico o un hostname modificabile: i form trasmettono un `signed_id` con scopo `free_subscription` e il controller accetta esclusivamente un dominio attivo verificato dalla firma.

##### Punto 7 — Accesso di un account esistente

- [x] Autenticare l'account globale con la procedura comune.
- [x] Verificare e creare il collegamento del profilo al sito corrente.
- [x] Considerare l'accesso dal contesto PosturaCorretta come adesione esplicita al sito e al brand.
- [x] Riattivare automaticamente i collegamenti annullati quando l'utente accede nuovamente dal contesto PosturaCorretta.
- [x] Tornare alla destinazione richiesta.

##### Punto 8 — Link del sito

- [ ] Aggiornare i link Accedi e Registrati di PosturaCorretta.
- [ ] In locale aggiungere `site=posturacorretta` e il `return_to` corretto.
- [ ] In produzione lasciare che sia il dominio a determinare il contesto.
- [ ] Conservare la pagina richiesta quando l'accesso parte da dashboard, corso, incontro o lezione.

##### Punto 9 — Protezione della dashboard

- [ ] Richiedere una sessione autenticata.
- [ ] Verificare che il profilo sia collegato a PosturaCorretta.
- [ ] Mostrare una richiesta di adesione quando il collegamento manca.
- [ ] Non introdurre un secondo login.

##### Punto 10 — Verifiche finali

- [ ] Nuova registrazione da PosturaCorretta.
- [ ] Accesso con account esistente.
- [ ] Errori di validazione senza perdita del contesto.
- [ ] Logout e nuovo accesso.
- [ ] Collegamento già attivo.
- [ ] Collegamento annullato.
- [ ] `return_to` esterno o malevolo.
- [ ] Localhost con parametro `site`.
- [ ] Dominio reale senza parametro `site`.
- [ ] Accesso generale senza alcun sito specifico.

**Blocco autenticazione completato:** registrazione, accesso, collegamento al dominio e al brand e ritorno alla dashboard sono operativi. Le verifiche restano nella checklist come riferimento per le future regressioni.

### Blocco 2 — Profilo e disponibilità di @markpostura

- [x] Pubblicare il profilo essenziale di @markpostura come insegnante maestro attivo.
- [ ] Definire le disponibilità settimanali individuali.
- [ ] Consentire la creazione di lezioni di gruppo.
- [ ] Registrare data, inizio, fine, durata, presenza/online, luogo e capienza.
- [ ] Distinguere incontro con tutor e lezione con insegnante.
- [ ] Collegare corsi e moduli che possono essere svolti nella lezione.

**Completato quando:** @markpostura può pubblicare almeno una disponibilità individuale e una lezione di gruppo realmente selezionabili.

**Stato attuale:** `teachers.yml` contiene @markpostura come insegnante maestro pubblico e attivo, abilitato alle lezioni Base e Avanzate, individuali e di gruppo, online e alla supervisione del tirocinio. La pagina pubblica degli insegnanti usa questa stessa fonte. Il prossimo dato necessario non è un altro profilo, ma la prima disponibilità reale da pubblicare in `lezioni_programmate.yml`.

### Blocco 3 — Prenotazione e Impegno

- [ ] Mostrare allo studente gli slot disponibili.
- [ ] Prenotare una lezione individuale.
- [ ] Iscriversi a una lezione di gruppo rispettandone la capienza.
- [ ] Creare i `DataCommitment` nei calendari dello studente e del responsabile.
- [ ] Impedire sovrapposizioni nel calendario personale.
- [ ] Gestire conferma, modifica, annullamento e conclusione.

**Completato quando:** una prenotazione effettuata da PosturaCorretta compare correttamente nei calendari delle persone coinvolte.

### Blocco 4 — Dashboard studente e avanzamento

- [x] Predisporre la dashboard su `/posturacorretta/dashboard`.
- [x] Leggere corsi, attività e capitoli dalle fonti YAML correnti.
- [ ] Salvare l'iscrizione personale al corso.
- [ ] Mostrare incontri e lezioni futuri e passati.
- [ ] Mostrare le lezioni effettivamente svolte.
- [ ] Registrare presenza e moduli svolti.
- [ ] Calcolare l'avanzamento personale per corso e modulo.
- [ ] Mostrare e sbloccare il prossimo passaggio.
- [ ] Collegare materiali, schede e contenuti della lezione.

**Completato quando:** lo studente vede dati propri e verificabili, non un avanzamento ricostruito genericamente dagli YAML.

### Blocco 5 — Tutor e segreteria

- [ ] Elenco delle persone da accogliere e delle richieste aperte.
- [ ] Consentire l'ingresso sia tramite registrazione autonoma sia tramite registrazione assistita dalla segreteria.
- [ ] Salvare per ogni iscrizione il centro di riferimento e, quando presente, il professionista di riferimento.
- [ ] Prenotazione assistita per chi ha difficoltà.
- [ ] Procedura sicura per aiutare nella registrazione senza conoscere la password dell'utente.
- [ ] Assegnazione di tutor e insegnante.
- [ ] Gestione gruppi, capienza, spostamenti, recuperi e annullamenti.
- [ ] Apertura del percorso e indicazione del prossimo passaggio.
- [ ] Registrazione delle eccezioni motivate al programma.

**Completato quando:** tutor o segreteria possono accompagnare una persona dall'ingresso al primo appuntamento senza interventi tecnici.

#### Regola per studenti, centri e professionisti di riferimento

Il nome e i dati personali appartengono al `Profile`; il collegamento generale al sito appartiene a `DomainMembership`. Centro e professionista di riferimento, invece, non vanno salvati in uno di questi due record: possono cambiare in base al corso o al percorso frequentato.

Quando verrà introdotta l'iscrizione, il record di iscrizione al corso/percorso dovrà quindi contenere almeno:

- `profile_id`;
- corso o percorso scelto;
- `center_slug` facoltativo;
- `reference_professional_slug` facoltativo;
- provenienza: registrazione autonoma oppure segreteria;
- stato dell'iscrizione e data;
- tutor o insegnante assegnato, quando necessario.

All'inizio la segreteria può compilare questi dati per la persona e invitarla poi a creare o completare il proprio account. In questo modo non deve mai conoscere o gestire la password dell'utente.

### Blocco 6 — Ciclo settimanale contenuti e YouTube

- [ ] Riservare nel calendario il tempo settimanale per preparazione e registrazione.
- [ ] Preparare il contenuto collegato alla lezione o al corso.
- [ ] Registrare il video YouTube.
- [ ] Salvare autore, data di registrazione e data di pubblicazione.
- [ ] Pubblicare o programmare video e articolo.
- [ ] Collegare il contenuto a corso, modulo, capitolo o scheda.
- [ ] Raccogliere domande e riscontri per la revisione successiva.

**Completato quando:** almeno un contenuto alla settimana segue un processo riconoscibile dalla preparazione alla pubblicazione e al collegamento didattico.

### Blocco 7 — Prima base del Percorso Integrato

- [ ] Consentire al tutor di aprire il percorso della persona.
- [ ] Definire il programma Benessere Integrato del dottor Giovanni Damiata.
- [ ] Definire separatamente proposta di tre mesi e proposta di sei mesi.
- [ ] Concordare prestazioni, frequenza, impegno richiesto, condizioni e prezzo.
- [ ] Non pubblicare prezzi prima dell'approvazione dell'offerta.
- [ ] Inserire visite e lezioni PosturaCorretta nello stesso calendario Impegno.
- [ ] Predisporre il diario unico della persona.
- [ ] Collegare verifiche e risultati senza confondere educazione e prestazioni professionali.

**Completato quando:** una persona può vedere in un unico percorso e calendario lezioni PosturaCorretta, visite professionali, attività concordate e diario.

### Stato corrente

**In corso:** Blocco 1 — Registrazione e accesso PosturaCorretta.

**Prossima azione:** analizzare e adattare le pagine comuni `UsersController` e `SessionsController` affinché ricavino il contesto PosturaCorretta dal dominio o dal percorso, mantengano la navigazione del sito e tornino alla dashboard richiesta.

## Decisione operativa: un solo accesso

Registrazione e autenticazione devono avvenire direttamente su **PosturaCorretta**, con il dominio, il logo, la navigazione e il linguaggio di PosturaCorretta. L'utente non deve effettuare una seconda autenticazione e non deve percepire un passaggio verso Flowpulse.

Tecnicamente l'account rimane unico per tutta la piattaforma, ma l'esperienza iniziale è quella del sito dal quale la persona arriva:

- su `posturacorretta.org` registrazione e accesso assumono automaticamente il contesto PosturaCorretta;
- su localhost il contesto viene ricavato dal percorso PosturaCorretta;
- dopo l'accesso la persona ritorna alla pagina richiesta, normalmente `/posturacorretta/dashboard`;
- il profilo viene collegato a PosturaCorretta durante la registrazione;
- tutor e segreteria potranno in seguito accompagnare o registrare le persone che non riescono a completare autonomamente il flusso;
- calendario e `DataCommitment` restano condivisi con Impegno, senza richiedere un nuovo account o un nuovo accesso.

Questa è la prima cosa da rendere stabile. Non va introdotto un secondo livello di login per il singolo brand.

## Obiettivo operativo immediato

Permettere a una persona reale di:

1. registrarsi o accedere da PosturaCorretta;
2. entrare nella propria dashboard studente;
3. vedere la disponibilità di **@markpostura**;
4. prenotare un incontro con il tutor o una lezione individuale o di gruppo;
5. trovare l'appuntamento nel proprio calendario Impegno;
6. vedere nella dashboard le lezioni prenotate e quelle effettivamente svolte.

Il primo tutor, insegnante e responsabile di segreteria può essere temporaneamente @markpostura. Questo consente di validare il processo prima di distribuire i ruoli.

## Ordine di lavoro aggiornato

### 1. Accesso PosturaCorretta

- pagina di registrazione PosturaCorretta;
- pagina di accesso PosturaCorretta;
- mantenimento del contesto e della navigazione PosturaCorretta;
- ritorno sicuro alla dashboard o alla lezione richiesta;
- collegamento del profilo al sito senza una seconda autenticazione.

### 2. Disponibilità di Mark Postura

- profilo pubblico dell'insegnante;
- disponibilità settimanali per lezioni individuali;
- lezioni di gruppo con data, orario, luogo o collegamento online;
- durata, capienza e livello della lezione;
- distinzione tra incontro con tutor e lezione con insegnante.

### 3. Prenotazione e calendario

- scelta dello slot disponibile;
- iscrizione alla lezione individuale o al gruppo;
- creazione dei `DataCommitment` dello studente e del responsabile;
- prevenzione delle sovrapposizioni sul calendario personale;
- conferma, modifica, annullamento e conclusione.

### 4. Dashboard studente reale

- corso o corsi attivi;
- prossimo incontro o lezione;
- appuntamenti futuri e passati;
- lezioni svolte;
- moduli completati durante ciascuna lezione;
- materiali e schede collegati;
- prossimo passo del programma.

### 5. Segreteria e tutor

- elenco delle richieste e delle persone da accogliere;
- possibilità di aiutare la persona nella registrazione senza conoscere o scegliere la sua password;
- inserimento o conferma dei dati necessari;
- prenotazione assistita;
- assegnazione al tutor o all'insegnante;
- gestione di gruppi, spostamenti, recuperi e annullamenti;
- apertura e verifica del percorso della persona.

### 6. Continuità editoriale settimanale

Ogni settimana deve rimanere uno spazio protetto per:

- preparare il contenuto;
- registrare il video YouTube;
- pubblicare o programmare video e articolo;
- collegare il contenuto al relativo corso, capitolo, modulo o scheda;
- raccogliere domande e riscontri utili per migliorare lezioni e programma.

La parte tecnica non deve assorbire tutto il tempo disponibile e interrompere la produzione educativa.

### 7. Prima base del Percorso Integrato

Soltanto dopo il primo flusso PosturaCorretta funzionante:

- apertura del percorso della persona da parte del tutor;
- programma Benessere Integrato del dottor Giovanni Damiata;
- proposta distinta di tre e sei mesi;
- definizione condivisa di prestazioni, frequenza, condizioni e prezzo;
- visite, lezioni PosturaCorretta e altri appuntamenti nello stesso calendario Impegno;
- diario unico della persona;
- verifiche e risultati registrati senza confondere percorso educativo e prestazioni professionali.

Il prezzo non deve essere pubblicato finché contenuto del programma, impegno richiesto, prestazioni incluse e accordo con il professionista non sono stati confermati.

## Priorità: cosa non fare adesso

Per arrivare velocemente al primo utilizzo reale, rimangono fuori dal prossimo passaggio:

- una seconda autenticazione per PosturaCorretta;
- pagamenti automatici;
- automatizzazione completa del tirocinio;
- dashboard complete per tutti i ruoli;
- apertura contemporanea di tutti i corsi;
- sviluppo completo del Percorso Integrato prima di aver validato lezioni e calendario;
- pubblicazione dei prezzi del programma del dottor Damiata prima della definizione dell'offerta.

## Strategia

PosturaCorretta non deve aspettare che tutti i corsi, i capitoli e le schede siano completi. L'obiettivo è costruire prima un'ossatura stabile, avviare il primo percorso con poche persone e aggiungere progressivamente contenuti, lezioni e insegnanti.

La piattaforma cresce quindi su due binari:

1. **struttura tecnica e organizzativa stabile**;
2. **pubblicazione settimanale dei contenuti**.

La fonte tecnica dettagliata per ruoli, livelli, appuntamenti e avanzamento è [Programma didattico: ruoli, lezioni e partecipazioni](/admin/appunti/docs/appunti/programma_didattico_ruoli_e_partecipazioni.md).

## Cosa deve essere pronto prima dell'avvio

### Pagine pubbliche

- home del percorso educativo;
- catalogo dei corsi;
- presentazione di ogni corso;
- indice del programma;
- indice dei capitoli;
- show dell'incontro o della lezione;
- show del capitolo;
- indicazione chiara dei contenuti disponibili e di quelli in preparazione.

### Percorso iniziale

Per partire è sufficiente rendere utilizzabile **PosturaCorretta in un mese** con:

- incontro iniziale con il tutor;
- prima lezione Base;
- programma dell'incontro;
- scheda pratica Base;
- capitoli essenziali già leggibili;
- collegamento per chiedere o prenotare la partecipazione.

La versione Avanzata, il tirocinio e i corsi successivi possono essere mostrati come sviluppi previsti senza promettere una disponibilità immediata.

### Gestione iniziale

Nella prima fase il superadmin può svolgere temporaneamente le funzioni di:

- tutor;
- insegnante;
- segreteria;
- responsabile della pubblicazione.

Questo permette di verificare il flusso prima di distribuire permessi e responsabilità.

## Struttura delle pagine da completare

### Studente

- URL definitivo: `/posturacorretta/dashboard`;
- corso attivo;
- prossima attività;
- appuntamenti;
- materiale da leggere;
- scheda da utilizzare;
- avanzamento personale.

La vista frontend è predisposta e usa il catalogo e il programma YAML reali. Lo stato personale rimane però informativo finché iscrizione, prenotazione, `DataCommitment`, presenza e completamento non vengono persistiti nel database.

### Tutor

- persone da accogliere;
- incontri iniziali;
- corsi scelti;
- prossimi passaggi;
- eventuali eccezioni motivate al programma.

### Insegnante

- lezioni assegnate;
- livello Base o Avanzato;
- partecipazione individuale o di gruppo;
- elenco dei partecipanti;
- conclusione della lezione e note essenziali.

### Segreteria

- disponibilità;
- calendario;
- prenotazioni;
- gruppi;
- conferme, spostamenti e annullamenti.

Le pagine possono essere predisposte prima di collegarle completamente al database, purché sia sempre chiaro quali funzioni sono operative e quali sono ancora dimostrative.

## Flusso minimo da rendere funzionante

1. La persona apre PosturaCorretta.
2. Entra in **PosturaCorretta in un mese**.
3. Il pulsante **Inizia** apre il primo incontro disponibile.
4. La persona richiede o prenota l'incontro con il tutor.
5. L'appuntamento crea un `DataCommitment`.
6. Tutor o insegnante concludono l'attività.
7. Il sistema sblocca l'attività successiva.
8. La persona continua il corso oppure sceglie un altro corso disponibile.

## Pubblicazione settimanale

Ogni settimana si può completare una piccola unità realmente utilizzabile.

### Unità minima settimanale

- un capitolo revisionato;
- il programma di un incontro o di una lezione;
- una scheda pratica;
- eventuale materiale video o immagine;
- una prova con almeno una persona;
- correzione delle difficoltà emerse.

### Ciclo consigliato

1. **Scrivere:** completare contenuto, programma e scheda.
2. **Controllare:** verificare chiarezza, durata e confini del ruolo educativo.
3. **Provare:** svolgere l'attività individualmente o con un piccolo gruppo.
4. **Raccogliere:** annotare domande, difficoltà e tempi reali.
5. **Correggere:** aggiornare contenuti e scheda.
6. **Pubblicare:** rendere disponibile l'unità successiva.

## Avvio progressivo degli insegnanti

Gli insegnanti non devono essere attivati tutti insieme.

### Prima fase

- osservano una lezione;
- studiano Base e Avanzata;
- partecipano come tirocinanti;
- conducono una parte in compresenza con il maestro.

### Seconda fase

- conducono la Base con supervisione;
- registrano presenze e conclusione;
- raccolgono feedback;
- correggono la conduzione con il maestro.

### Terza fase

- ricevono l'abilitazione per lo specifico corso o modulo;
- propongono disponibilità individuali o di gruppo;
- conducono autonomamente ciò per cui sono abilitati.

L'abilitazione deve riguardare corsi e livelli specifici, non un'autorizzazione generica a insegnare qualsiasi contenuto.

## Cosa può aspettare

Non è necessario per il primo avvio completare subito:

- pagamenti automatici;
- attestati automatici;
- tutti i corsi avanzati;
- tirocinio completamente automatizzato;
- gruppi complessi e liste d'attesa;
- statistiche avanzate;
- notifiche automatiche;
- disponibilità di molti insegnanti.

## Ordine di implementazione

### Fase 1 — Ossatura

- uniformare le pagine studente, tutor, insegnante e segreteria;
- completare navigazione e stati vuoti;
- rendere coerenti programma, capitoli e schede.

### Fase 2 — Primo flusso reale

- iscrizione personale al corso;
- prenotazione;
- creazione del `DataCommitment`;
- conclusione dell'attività;
- sblocco dell'attività successiva.

### Fase 3 — Primo gruppo

- disponibilità dell'insegnante;
- lezione di gruppo;
- presenze;
- ripetizione o recupero;
- feedback.

### Fase 4 — Formazione insegnanti

- livelli Base e Avanzato;
- tirocinio;
- supervisione;
- abilitazione per corso.

### Fase 5 — Crescita

- nuovi corsi e capitoli;
- nuovi insegnanti;
- più sedi e gruppi;
- pagamenti e automazioni quando il processo manuale è stato validato.

## Primo traguardo

Il primo traguardo non è avere tutta l'Accademia completa. È permettere a una persona reale di:

1. comprendere da dove iniziare;
2. prenotare il primo incontro;
3. svolgere una lezione Base;
4. ricevere e utilizzare una scheda;
5. vedere chiaramente il passo successivo.

Quando questo flusso funziona senza assistenza tecnica, la piattaforma può iniziare a crescere una settimana alla volta.

## Prossima analisi tecnica

La definizione dell'MVP basato su `DataEvent` e `DataCommitment` viene affrontata una decisione alla volta nel documento [DataEvent MVP — decisioni da analizzare](data_event_mvp_decisioni.md).
