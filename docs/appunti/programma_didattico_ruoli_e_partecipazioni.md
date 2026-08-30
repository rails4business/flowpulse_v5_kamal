# Programma didattico: sezioni, corsi, moduli, lezioni e partecipazioni

> **Schema visivo:** la mappa Mermaid del percorso di formazione è disponibile nella pagina amministrativa [Flusso Formazione e Crescita Insegnanti](/admin/percorso_insegnanti). Questo documento ne costituisce la specifica operativa testuale.

## Obiettivo

Definire una sola struttura per organizzare il percorso educativo PosturaCorretta senza confondere:

- il materiale da studiare è messo nel corso
- per incontri e lezioni si mette una scheda 
- gli appuntamenti reali;
- il ruolo con cui una persona partecipa;
- la lezione può essere livello base, avanzato 
- Uno studente può partecipare a una lezione come di tirocinante; 
- il lavoro organizzativo di tutor, insegnanti e segreteria.

Questa è una specifica funzionale. I dati didattici possono restare negli YAML finché non sarà utile trasferirli nel database.

## Regola generale del percorso

Tutti iniziano da **PosturaCorretta in un mese**. Il pulsante **Inizia** apre la prima attività disponibile del suo programma.

Dopo l'avvio comune, la persona può scegliere liberamente un altro corso. All'interno del corso scelto, incontri e lezioni vengono programmati nell'ordine previsto. I capitoli possono invece rimanere consultabili liberamente come materiale didattico.

## Nomenclatura ufficiale

### 1. Sezione

È un'area ampia del percorso educativo, per esempio **Postura e Recupero**, **Postura e Movimento** o **Postura e Meditazione**. Una sezione raccoglie corsi affini, ma non è un'attività prenotabile.

### 2. Corso

È il contenitore didattico, per esempio **PosturaCorretta in un mese** o **Igiene Posturale**.

Un corso contiene:

- uno o più moduli;
- uno o più capitoli;
- eventuali livelli base e avanzato;
- le regole necessarie per completarlo.

### 3. Modulo

È l'unità didattica riutilizzabile, per esempio **Mobilità articolare**. Può contenere teoria, obiettivi, durata indicativa, una scheda pratica e collegamenti ai materiali del corso.

Un modulo appartiene normalmente a un corso. Una lezione può però combinare moduli provenienti da corsi e sezioni differenti. Lo svolgimento del modulo aggiorna separatamente l'avanzamento del corso al quale appartiene.

### 4. Lezione

È l'appuntamento didattico tenuto da un insegnante in una data precisa. Può essere individuale o di gruppo e può comprendere uno o più moduli.

Esempio: una sola lezione può comprendere **Mobilità articolare** di Igiene Posturale, un modulo di **Postura e Movimento** e un modulo di **Postura e Meditazione**. La persona effettua una sola prenotazione, mentre il sistema registra i moduli effettivamente svolti nei rispettivi corsi.

La lezione registra:

- data, orario, luogo o collegamento online;
- insegnante responsabile ed eventuale maestro supervisore;
- modalità individuale o di gruppo;
- moduli previsti e moduli effettivamente svolti;
- studenti e tirocinanti partecipanti;
- livello base o avanzato delle singole parti, quando necessario.

### 5. Incontro con il tutor

È un appuntamento di orientamento, presentazione o verifica. Non è una lezione e non deve essere usato come contenitore dei moduli didattici.

### 6. Attività prevista dal percorso guidato

Descrive che cosa deve avvenire, senza stabilire ancora una data concreta.

Tipi iniziali:

- `tutor_meeting`: incontro con il tutor;
- `lesson`: lezione con un insegnante, composta da uno o più moduli.

Il tirocinio non è un tipo separato di attività: è il ruolo con cui una persona partecipa a una lezione, in affiancamento o in conduzione supervisionata.

Ogni attività può contenere:

- titolo e descrizione;
- ordine nel corso;
- programma dell'incontro o della lezione;
- scheda pratica;
- durata indicativa;
- livello richiesto;
- attività precedente da completare.

### 7. Appuntamento reale

È l'esecuzione concreta di un'attività del programma. Ha data, ora, luogo o collegamento online, persone coinvolte e stato.

L'appuntamento dovrà collegare:

- corso;
- attività del programma;
- tutor, insegnante o maestro responsabile;
- partecipante o gruppo;
- prenotazione;
- eventuale `DataCommitment` creato nei calendari delle persone coinvolte.

Lo YAML definisce quindi **che cosa può o deve essere fatto**; l'appuntamento nel database registra **quando, con chi e come viene fatto**. Per una lezione, l'appuntamento è il contenitore a calendario e i moduli sono il suo programma didattico.

## Esempio completo

```text
Sezione: Postura e Recupero
└── Corso: Igiene Posturale
    └── Modulo: Mobilità articolare

Lezione del 12 ottobre, 18:00–19:30
├── Mobilità articolare · Igiene Posturale
├── Movimento e respirazione · Postura e Movimento
└── Meditazione e ascolto corporeo · Postura e Meditazione
```

La prenotazione riguarda la lezione. L'avanzamento riguarda i singoli moduli svolti.

## Dimensioni della partecipazione

Le caratteristiche non devono essere fuse in un unico nome. Sono dimensioni indipendenti.

### Ruolo della persona

- `student`: partecipa come studente;
- `teacher_trainee`: partecipa come aspirante insegnante;
- `teacher`: conduce una lezione;
- `master_teacher`: conduce e supervisiona il tirocinio;
- `tutor`: introduce, orienta e segue il programma;
- `secretariat`: organizza disponibilità, iscrizioni e appuntamenti.

### Livello didattico

- `base`;
- `advanced`;

Il tirocinio non è un livello del contenuto: è una forma di partecipazione alla lezione.

### Modalità

- `individual`;
- `group`.

### Forma di partecipazione

- in presenza;
- online, quando prevista;
- in compresenza per il tirocinio.

Esempi:

- studente, livello base, lezione di gruppo;
- studente, livello avanzato, lezione individuale;
- aspirante insegnante, tirocinio di gruppo in compresenza con un maestro;
- tutor, incontro individuale di presentazione.

## Responsabilità dei ruoli

### Studente

Consulta i capitoli, prenota la prima attività disponibile e segue il programma del corso in ordine.

### Insegnante

Propone disponibilità o conduce una lezione base per la quale è abilitato. Registra i moduli svolti e le informazioni essenziali richieste.

### Insegnante maestro

Può condurre lezioni base e avanzate, comporre il programma della lezione con i moduli autorizzati e supervisionare il tirocinio degli aspiranti insegnanti.

### Tutor

Gestisce l'ingresso nel percorso, presenta il metodo, aiuta nella scelta dei corsi e può autorizzare motivate eccezioni all'ordine normale.

### Segreteria

Gestisce calendario, disponibilità, gruppi, conferme, spostamenti e annullamenti. Non modifica valutazioni o contenuti didattici.

## Stati minimi

### Attività nel percorso della persona

- `locked`: non ancora disponibile;
- `available`: prima attività prenotabile;
- `booked`: appuntamento fissato;
- `completed`: attività svolta;
- `cancelled`: appuntamento annullato, attività nuovamente da programmare;
- `waived`: attività considerata soddisfatta dal tutor con motivazione.

### Appuntamento

- bozza;
- proposto;
- confermato;
- concluso;
- annullato.

## Regole di avanzamento

1. La prima attività incompleta del corso è disponibile.
2. Le successive rimangono bloccate.
3. Una prenotazione porta l'attività nello stato `booked`, ma non la completa.
4. La conclusione dell'appuntamento porta l'attività nello stato `completed`.
5. Il tutor può usare `waived` soltanto con una motivazione registrata.
6. Ripetere un'attività crea un nuovo appuntamento senza cancellare lo storico precedente.
7. La lettura dei capitoli non sostituisce automaticamente incontri, lezioni o tirocinio.

## Dati e file attuali

- `teachers.yml`: insegnanti attivi e candidati già attestati ma non ancora pubblicati; attestato, abilitazione operativa e disponibilità restano dati distinti;
- `posturacorretta_titoli_sezioni_e_corsi.yml`: indice generale con sezioni e corsi;
- `posturacorretta_percorso.yml`: corsi online, organizzati in moduli e capitoli;
- `posturacorretta_percorso_guidato.yml`: incontri e lezioni prenotabili, ordinati per corso;
- `attivita_percorso_guidato/`: programma delle singole attività; ogni lezione può riferirsi a uno o più moduli, anche appartenenti a corsi differenti;

Il ruolo appartiene alla partecipazione, non al corso. Ogni attività può dichiarare in `participation.roles` i ruoli ammessi e un `default_role`; il ticket o il futuro `DataCommitment` conserverà il ruolo effettivamente scelto.
- `docs/role_navigation_refactor_plan.md`: ruoli applicativi e autorizzazioni;
- `docs/appunti/programma_posturacorretta_in_1_mese.md`: contenuti e sviluppo del primo mese.

La presente specifica collega questi elementi, ma non deve duplicarne tutti i contenuti.

## Implementazione progressiva consigliata

1. Mantenere ora l'ordine visivo delle attività usando i dati disponibili.
2. Collegare il pulsante **Prenota** alla creazione di un appuntamento reale.
3. Salvare nel database iscrizione al corso e avanzamento personale.
4. Creare le viste dedicate a studente, tutor, insegnante e segreteria.
5. Aggiungere gruppi, disponibilità e gestione delle presenze.
6. Aggiungere abilitazioni per livelli avanzati e tirocinio.
# Tirocinio: struttura predisposta

Per ora il tirocinio registra la modalità della singola partecipazione, senza determinare automaticamente l'avanzamento formativo:

- **in affiancamento**: il tirocinante osserva e supporta;
- **conduzione supervisionata**: il tirocinante conduce una parte o tutta la lezione, mentre la responsabilità resta all'insegnante maestro.

L'insegnante conduce le lezioni base. L'insegnante maestro può condurre anche le lezioni avanzate e supervisionare il tirocinio. Prerequisiti, numero di affiancamenti, ore, valutazioni e passaggio alla conduzione saranno definiti successivamente in un **Programma di tirocinio** dedicato.
