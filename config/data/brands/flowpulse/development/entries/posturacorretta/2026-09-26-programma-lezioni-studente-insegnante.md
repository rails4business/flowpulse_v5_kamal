# Unificare programma studente e percorso insegnante

## Decisione

PosturaCorretta mantiene due fonti ufficiali distinte, con responsabilità diverse:

- il **percorso online** descrive `Section → Course → Chapter`;
- il **programma lezioni** descrive `Course` introduttivi e `Section → Course → Lesson → Schede`.

Il programma lezioni ufficiale descrive:

- le sezioni del percorso;
- i corsi contenuti in ogni sezione;
- le lezioni di ogni corso;
- le schede collegate a ogni lezione;
- i requisiti aggiuntivi per diventare insegnante;
- il tirocinio previsto per ciascun corso.

Lo YAML descrive la struttura comune, non contiene utenti, presenze o progressi personali.

## Accesso al percorso insegnante

Il pulsante **Diventa insegnante** non deve essere mostrato agli utenti e non può essere attivato autonomamente.

Il percorso insegnante diventa visibile per una persona soltanto dopo un’attivazione esplicita effettuata da:

- un insegnante PosturaCorretta già autorizzato;
- un tutor PosturaCorretta;
- il superadmin.

L’autorizzazione deve essere limitata al Node del Brand PosturaCorretta. Essere operatori di un altro Brand non concede questo permesso.

Durante il pilota l’attivazione può essere rappresentata da un `RoleAssignment` con ruolo `operator` e funzione `tirocinante`, assegnato nel contesto PosturaCorretta. Le funzioni abilitate ad assegnarlo saranno `insegnante`, `tutor` e `superadmin`.

## Struttura YAML prevista

```yaml
schema_version: 2

program:
  key: programma-lezioni-posturacorretta
  title: Programma lezioni PosturaCorretta

  courses:
    - key: introduzione-a-posturacorretta
      title: Introduzione a PosturaCorretta
      lessons:
        - key: inizia-con-posturacorretta
          title: Inizia con PosturaCorretta
          sheets:
            - course_key: inizia-con-posturacorretta
              chapter_key: prima-scheda-esercizi-video

  sections:
    - key: postura-recupero
      title: Postura, recupero e coscienza corporea
      color: blue

      courses:
        - key: igiene-posturale
          title: Igiene Posturale
          description: Mobilità articolare, punti di tensione e percezione.

          lessons:
            - key: mobilita-articolare
              title: Mobilità articolare
              sheets:
                - course_key: igiene-posturale
                  chapter_key: mobilita-articolare
                  title: Mobilità articolare
                  type: practical

          teacher_path:
            title: Tirocinio · Igiene Posturale
            lessons:
              - key: igiene-posturale-tirocinio-1
                title: Affiancare una lezione di gruppo con un insegnante.
                type: internship
                sheets: []
```

Il primo corso introduttivo appartiene direttamente al programma e non a una Section, come nel prototipo ufficiale. I corsi futuri senza lezioni complete possono comparire come spazi non ancora disponibili.

Anche affiancamenti, compresenze e tirocinio sono Lesson. Vivono in `teacher_path.lessons`, usano lo stesso linguaggio visivo delle altre lezioni e sono filtrati dal permesso; non sono semplici note o requisiti testuali.

Ogni scheda conserva `course_key` e `chapter_key` per aprire il contenuto corrispondente nel percorso online, ma non trasforma il Chapter in una Lesson: le due gerarchie rimangono separate.

## Fonti canoniche

- Percorso online: `config/data/posturacorretta/contenuti/percorso.yml`.
- Programma lezioni: `config/data/posturacorretta/programmi/programma_lezioni_posturacorretta.yml`.

Gli altri YAML didattici restano temporaneamente disponibili per la revisione e non devono diventare nuove fonti concorrenti.

## Nuova vista Lezioni

La pagina `/posturacorretta/lezioni` deve riprendere il prototipo:

`docs/private_prototypes/viste_html/programma_lezioni_posturacorretta_ufficiale.html`

La vista Rails dovrà avere:

- uno stepper orizzontale con sezioni e corsi;
- scorrimento orizzontale utilizzabile anche da mobile;
- un pannello dedicato al corso selezionato;
- l’elenco delle lezioni e delle schede collegate;
- lo stato del percorso studente;
- attestato del corso o del percorso quando i requisiti saranno completati;
- blocco insegnante e tirocinio solo per le persone abilitate;
- nessun progresso dimostrativo conservato in JavaScript.

Il corso selezionato potrà essere mantenuto nei parametri della pagina, così il relativo URL sarà condivisibile.

## Stati personali

Gli stati non devono essere scritti nel programma YAML. La vista dovrà essere predisposta a ricevere separatamente:

- corso disponibile o bloccato;
- lezione programmata;
- partecipazione o completamento;
- percorso insegnante attivato;
- tirocinio iniziato o completato;
- abilitazione conseguita.

Nella prima implementazione, in assenza di dati personali, la pagina mostrerà soltanto la struttura ufficiale e le regole di accesso realmente verificabili.

## Integrazione futura con 1Impegno

La struttura editoriale resterà nello YAML. Le occorrenze reali saranno collegate successivamente così:

```text
Corso e lezione definiti nello YAML
              ↓
DataSession   = lezione realmente programmata
DataSlot      = scheda o parte della lezione
DataCommitment = partecipazione, presenza, completamento o tirocinio
```

Lo YAML non conterrà date, prenotazioni, persone o presenze. Questi dati apparterranno a 1Impegno e potranno essere letti dalla pagina PosturaCorretta.

## Passi di implementazione

1. Migrare `programma_lezioni_posturacorretta.yml` allo schema con sezioni, corsi e lezioni.
2. Conservare tutti i collegamenti esistenti ai capitoli e alle schede.
3. Aggiornare il loader del programma mantenendo controlli espliciti sui dati mancanti.
4. Ricostruire la vista Rails sul prototipo ufficiale.
5. Applicare i permessi del percorso insegnante al Node PosturaCorretta.
6. Aggiungere test per utente, tirocinante, insegnante, tutor e superadmin.
7. Verificare desktop e mobile.
8. Solo dopo la verifica, preparare il changelog pubblico del Brand.

## Stato al 26 settembre 2026

Implementato:

- schema 2 del programma lezioni con 1 corso introduttivo fuori dalle Section, 5 Section successive, 7 corsi, 36 lezioni studente, 19 lezioni di tirocinio e 40 schede;
- collegamenti delle schede ai capitoli del percorso online;
- selezione del corso tramite parametro `corso`;
- stepper orizzontale con una linea continua, numerazione unica e pannello del corso selezionato;
- apertura settimanale dei corsi secondo il calendario esistente;
- blocco del percorso insegnante per gli utenti non attivati;
- visualizzazione del tirocinio per superadmin e operatori `tirocinante` nel contesto PosturaCorretta;
- test della struttura YAML e dei due livelli di accesso principali.

Da validare con casi reali:

- interfaccia mobile e leggibilità dello stepper;
- attivazione effettuata da tutor e insegnante;
- progressi, presenze, attestati e tirocinio tramite i futuri DataCommitment;
- completamento graduale delle sezioni successive, un corso alla settimana.

## Escluso da questo blocco

- creazione automatica di `DataSession`, `DataSlot` e `DataCommitment`;
- prenotazioni e pagamenti;
- attestati definitivi scaricabili;
- abilitazioni permanenti per singolo corso;
- importazione del programma nel database.

Questi aspetti verranno affrontati dopo aver validato struttura YAML e interfaccia con casi reali.
