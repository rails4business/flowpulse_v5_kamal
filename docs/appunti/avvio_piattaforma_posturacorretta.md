# Avvio della piattaforma PosturaCorretta

## TODO operativo

Questa è la checklist principale per l'avvio. Va aggiornata nello stesso momento in cui una funzione viene completata e verificata. Non aprire il blocco successivo finché il flusso minimo del blocco corrente non funziona con una persona reale.

### Blocco 1 — Registrazione e accesso PosturaCorretta

- [ ] Riconoscere automaticamente il contesto PosturaCorretta su `posturacorretta.org`.
- [ ] Riconoscere il contesto PosturaCorretta nei percorsi locali `/posturacorretta/...`.
- [ ] Mostrare logo, titolo, descrizione, colori e navigazione PosturaCorretta nelle pagine di registrazione e accesso.
- [ ] Conservare una destinazione `return_to` interna e sicura.
- [x] Dopo la registrazione collegare o riattivare il profilo su PosturaCorretta con `DomainMembership`.
- [x] Dopo accesso o registrazione tornare alla dashboard, alla lezione o alla pagina inizialmente richiesta.
- [ ] Mantenere un solo account e una sola autenticazione per tutta la piattaforma.
- [ ] Verificare registrazione, accesso, errori, uscita e nuovo accesso sia da localhost sia dal dominio.

**Completato quando:** un nuovo utente entra da PosturaCorretta, crea l'account, ritorna alla dashboard PosturaCorretta e al successivo accesso ritrova lo stesso profilo senza vedere Flowpulse o dover effettuare un secondo login.

### Collegamento del profilo al sito

`TravelerSubscription` non viene usato per l'adesione a PosturaCorretta: richiede un `Node` ed è riservato ai contenuti Node-based già esistenti.

Per l'adesione a un sito viene usato `DomainMembership`:

- `profile_id`;
- `domain_id`;
- `status` (`active` o `cancelled`);
- `joined_at`.

Registrazione, accesso e apertura della dashboard in contesto PosturaCorretta creano o riattivano in modo idempotente la membership. Non sono richiesti un secondo account o un secondo accesso.

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

- [ ] Conservare temporaneamente lo slug nella sessione durante accesso e registrazione.
- [ ] Conservare una sola destinazione `return_to` interna e verificata.
- [ ] Mantenere contesto e destinazione quando il form presenta errori.
- [ ] Eliminare il contesto temporaneo quando il flusso è concluso.

##### Punto 4 — Form comuni brandizzati

- [ ] Fare leggere a `/session/new` e `/users/new` il contesto risolto.
- [ ] Mostrare logo, nome, colori, testi e navigazione del sito.
- [ ] Conservare contesto e `return_to` nei collegamenti tra registrazione e accesso.
- [ ] Evitare riferimenti visibili a Flowpulse quando il contesto è PosturaCorretta.
- [ ] Mantenere accessibili le pagine anche senza contesto specifico.

##### Punto 5 — Sicurezza della destinazione

- [ ] Accettare esclusivamente percorsi interni.
- [ ] Rifiutare URL assoluti, destinazioni con `//` e host esterni.
- [ ] Verificare che la destinazione sia coerente con il sito quando è presente un contesto specifico.
- [ ] Usare la dashboard del sito come destinazione di ripiego.

##### Punto 6 — Registrazione e collegamento al sito

- [ ] Creare `User` e `Profile` con la procedura comune.
- [ ] Collegare o riattivare il profilo sul sito corrente.
- [ ] Eseguire creazione dell'account e collegamento in modo atomico.
- [ ] Avviare una sola sessione.
- [ ] Reindirizzare alla destinazione richiesta.

##### Punto 7 — Accesso di un account esistente

- [ ] Autenticare l'account globale con la procedura comune.
- [ ] Verificare il collegamento del profilo al sito corrente.
- [ ] Richiedere una conferma esplicita prima di creare un collegamento mancante, se l'accesso non era partito da un'azione di adesione chiara.
- [ ] Riattivare un collegamento annullato soltanto con una conferma esplicita.
- [ ] Tornare alla destinazione richiesta.

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

**Punto attualmente in lavorazione:** Punto 3 — conservazione del contesto e validazione sicura di `return_to` durante accesso e registrazione.

### Blocco 2 — Profilo e disponibilità di @markpostura

- [ ] Completare la pagina pubblica dell'insegnante.
- [ ] Definire le disponibilità settimanali individuali.
- [ ] Consentire la creazione di lezioni di gruppo.
- [ ] Registrare data, inizio, fine, durata, presenza/online, luogo e capienza.
- [ ] Distinguere incontro con tutor e lezione con insegnante.
- [ ] Collegare corsi e moduli che possono essere svolti nella lezione.

**Completato quando:** @markpostura può pubblicare almeno una disponibilità individuale e una lezione di gruppo realmente selezionabili.

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
- [ ] Prenotazione assistita per chi ha difficoltà.
- [ ] Procedura sicura per aiutare nella registrazione senza conoscere la password dell'utente.
- [ ] Assegnazione di tutor e insegnante.
- [ ] Gestione gruppi, capienza, spostamenti, recuperi e annullamenti.
- [ ] Apertura del percorso e indicazione del prossimo passaggio.
- [ ] Registrazione delle eccezioni motivate al programma.

**Completato quando:** tutor o segreteria possono accompagnare una persona dall'ingresso al primo appuntamento senza interventi tecnici.

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
