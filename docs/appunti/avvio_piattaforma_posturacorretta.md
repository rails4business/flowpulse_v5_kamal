# Avvio della piattaforma PosturaCorretta

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

- corso attivo;
- prossima attività;
- appuntamenti;
- materiale da leggere;
- scheda da utilizzare;
- avanzamento personale.

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
