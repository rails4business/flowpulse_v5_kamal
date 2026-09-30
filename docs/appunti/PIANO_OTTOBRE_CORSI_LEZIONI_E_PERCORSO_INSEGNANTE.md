# Piano ottobre — corsi online, lezioni e percorso insegnante

Aggiornato il 29 settembre 2026.

> **Nota organizzativa:** la scheda canonica delle cose da fare vive nel
> registro interno **Flowpulse → Sviluppo**, in
> `config/data/brands/flowpulse/development/entries/posturacorretta/2026-09-26-programma-lezioni-studente-insegnante.md`.
> Questo documento conserva il quadro esteso e deve restare coerente con quella
> scheda.

## Obiettivo

Arrivare a ottobre con le funzioni essenziali dell'app pronte per:

1. iscriversi a un percorso online;
2. consultare il materiale disponibile;
3. salvare l'avanzamento e riprendere dall'ultimo contenuto;
4. vedere il programma futuro delle lezioni, senza presentarlo ancora come prenotabile.

Da ottobre il materiale del corso online viene rivisto e pubblicato con un ritmo sostenibile: **un'unità alla settimana**. Prenotazioni, presenze e tirocinio operativo vengono dopo la sistemazione di insegnanti, luoghi, servizi e calendari.

## Decisione di impostazione

Il progetto ha due binari collegati ma distinti:

- **corso online**: contiene capitoli, video, testi, esercizi e schede da consultare;
- **programma lezioni**: contiene gli appuntamenti reali, individuali o di gruppo, tenuti da un insegnante.

La prenotazione riguarda una lezione reale. L'avanzamento didattico riguarda le attività e i moduli effettivamente svolti. La sola lettura di un contenuto online non sostituisce automaticamente una lezione, un incontro o il tirocinio.

## Lavoro già recuperato nel progetto

### Già presente

- [x] Struttura pubblica dei corsi e dei capitoli online.
- [x] Programma lezioni separato dal percorso online.
- [x] Programma didattico con **40 schede distribuite in 36 lezioni e 7 corsi**.
- [x] Percorsi di tirocinio descritti per i corsi, con 19 attività complessive.
- [x] Ruoli didattici definiti: studente, aspirante insegnante, insegnante, insegnante maestro, tutor e segreteria.
- [x] Modalità previste: individuale, gruppo, presenza, online e tirocinio in compresenza.
- [x] Area lezioni dello studente e pagina degli appuntamenti.
- [x] Area insegnante esistente come anteprima frontend.
- [x] Elenco di insegnanti e centri, con pagine dedicate.
- [x] Calendario editoriale YAML: preparazione il lunedì e lezioni di gruppo il venerdì alle 15:00 e alle 20:00.
- [x] Rilascio settimanale dei corsi già calcolato dall'app.
- [x] Modelli generali già disponibili per sessioni, slot e impegni a calendario (`DataSession`, `DataSlot`, `DataCommitment`).
- [x] Possibilità di conservare nel singolo impegno il ruolo di partecipazione.

### Presente solo in parte o come interfaccia

- [~] Il pulsante **Prenota** esiste, ma porta nell'area 1Impegno: non conclude ancora una prenotazione guidata della specifica lezione PosturaCorretta.
- [~] Gli appuntamenti dell'utente possono essere mostrati, ma non costituiscono ancora uno storico didattico completo.
- [~] Le lezioni programmate possono essere lette da YAML, ma il calendario ricorrente non genera ancora tutte le lezioni reali prenotabili.
- [~] Il percorso insegnante è visibile agli utenti autorizzati, ma attività, supervisione e avanzamento non sono ancora registrati integralmente nel database.
- [~] Ruoli e permessi esistono, ma vanno completati e verificati per ogni operazione.

### Ancora da completare per l'obiettivo di ottobre

- [ ] Iscrizione persistente dell'utente al percorso/corso online.
- [ ] Creazione e pubblicazione delle lezioni reali con data, ora, sede o collegamento, insegnante, modalità e capienza.
- [ ] Prenotazione e annullamento da parte dell'utente.
- [ ] Prevenzione di doppie prenotazioni e gestione dei posti disponibili.
- [ ] Conferma della partecipazione/presenza.
- [ ] Registrazione dei moduli realmente svolti durante la lezione.
- [ ] Avanzamento personale persistente e sblocco dell'attività successiva.
- [ ] Flusso di attivazione dell'aspirante insegnante.
- [ ] Registrazione del tirocinio in affiancamento o conduzione supervisionata.
- [ ] Validazione del tirocinio da parte dell'insegnante maestro.
- [ ] Strumenti minimi di insegnante, maestro e segreteria per gestire lezioni e partecipanti.
- [ ] Notifiche o, per il primo rilascio, conferme chiare nell'app e procedura manuale documentata.

## MVP necessario per ottobre — prima il percorso online

Per non allargare troppo il lavoro, il primo rilascio operativo deve coprire un flusso completo, anche semplice:

```text
registrazione/accesso
→ iscrizione al percorso online
→ apertura del primo contenuto
→ contenuto iniziato/completato
→ avanzamento salvato
→ ripresa dall'ultimo punto
→ contenuto successivo disponibile
```

### Funzioni indispensabili

#### Utente/studente

- iscriversi al percorso;
- vedere a quale corso è iscritto e la prossima attività;
- consultare i contenuti già pubblicati;
- scegliere una lezione disponibile;
- vedere modalità, insegnante, data, luogo/link e posti;
- prenotare o annullare;
- vedere appuntamenti futuri e attività concluse;
- avanzare soltanto dopo la conferma della lezione svolta.

#### Insegnante — fase successiva

- vedere le lezioni assegnate;
- vedere l'elenco dei partecipanti;
- confermare presenza o assenza;
- indicare quali moduli sono stati effettivamente svolti;
- chiudere la lezione.

#### Insegnante maestro — fase successiva

- avere le funzioni dell'insegnante;
- vedere i tirocinanti presenti;
- indicare affiancamento o conduzione supervisionata;
- validare l'attività di tirocinio e lasciare una nota essenziale.

#### Segreteria/amministrazione — fase successiva

- creare o modificare una lezione reale;
- assegnare insegnante, maestro, sede/link e capienza;
- confermare, spostare o annullare una lezione;
- controllare iscritti e posti disponibili.

## Ordine di lavoro aggiornato

### Fase 1 — Rendere operativo il percorso online

- [ ] Salvare l'iscrizione al percorso o al corso.
- [ ] Definire accessi libero, iscritto, programmato e bloccato.
- [ ] Salvare lo stato personale dei contenuti.
- [ ] Riprendere il percorso dall'ultimo contenuto raggiunto.
- [ ] Mostrare corso attivo, prossimo contenuto e avanzamento reale.
- [ ] Collaudare il flusso completo su desktop e telefono.

### Fase 2 — Pubblicare un'unità alla settimana

- [ ] Preparare la prima unità completa.
- [ ] Mantenere due o tre unità di margine.
- [ ] Collegare ogni unità alla futura lezione o scheda pertinente.
- [ ] Raccogliere osservazioni e correggere il materiale già pubblicato.

### Fase 3 — Ordinare l'offerta dal vivo

- [ ] Completare insegnanti e insegnanti maestri.
- [ ] Definire luoghi e centri.
- [ ] Definire servizi, abilitazioni e modalità.
- [ ] Collegare professionisti, servizi e calendari.

### Fase 4 — Rendere prenotabile una lezione reale

- [ ] Scegliere una sola rappresentazione canonica dell'appuntamento: `DataSession` per la lezione e partecipazioni collegate tramite `DataCommitment`.
- [ ] Collegare ogni lezione reale alla voce del programma e alle sue schede/moduli.
- [ ] Creare almeno i due appuntamenti di gruppo del venerdì.
- [ ] Definire luogo effettivo oppure link online; non pubblicare valori "Da definire".
- [ ] Aggiungere capienza, stato e regole di prenotazione.

### Fase 5 — Prenotazione utente

- [ ] Trasformare **Prenota** in un'azione interna e specifica per quella lezione.
- [ ] Salvare il ruolo scelto (`student` o `teacher_trainee`) nella partecipazione.
- [ ] Gestire conferma, annullamento, posti terminati e prenotazione duplicata.
- [ ] Mostrare la prenotazione nella pagina Appuntamenti.

### Fase 6 — Svolgimento e avanzamento delle lezioni

- [ ] Permettere all'insegnante di registrare presenza e moduli svolti.
- [ ] Chiudere la lezione senza perdere lo storico.
- [ ] Aggiornare l'avanzamento personale.
- [ ] Sbloccare la successiva attività del programma.
- [ ] Gestire la ripetizione di una lezione come nuovo appuntamento.

### Fase 7 — Percorso per diventare insegnante

- [ ] Attivare esplicitamente la persona come aspirante insegnante.
- [ ] Prenotarla alla lezione nel ruolo di tirocinante.
- [ ] Registrare modalità del tirocinio e maestro supervisore.
- [ ] Far validare l'attività al maestro.
- [ ] Mostrare attività completate, mancanti e abilitazione raggiunta.

### Fase 8 — Collaudo delle funzioni dal vivo

- [ ] Provare il flusso completo con un utente studente.
- [ ] Provarlo con un aspirante insegnante.
- [ ] Provarlo con insegnante e maestro.
- [ ] Verificare gruppo pieno, annullamento e spostamento.
- [ ] Verificare permessi: nessun ruolo deve modificare dati che non gli competono.
- [ ] Verificare il comportamento da telefono.
- [ ] Preparare una procedura manuale di emergenza per il primo mese.

## Calendario dei contenuti da ottobre

La scelta di sistemare **un pezzo ogni settimana** è corretta. Consente di usare il corso mentre viene revisionato, raccogliere osservazioni reali e non bloccare l'apertura in attesa che tutto il materiale sia perfetto.

### Ritmo settimanale proposto

| Momento | Attività |
| --- | --- |
| Lunedì | scegliere l'unità della settimana e controllare il materiale esistente |
| Martedì | riscrivere testi e preparare scheda/esercizi |
| Mercoledì | registrare o sistemare video, immagini e materiali; eventuale diretta |
| Giovedì | revisione finale, collegamenti e prova nell'app |
| Venerdì | lezione di gruppo e raccolta delle domande reali |
| Fine settimana | piccole correzioni e annotazione di ciò che va migliorato |

### Regola di pubblicazione

Ogni unità settimanale dovrebbe avere almeno:

- un obiettivo chiaro;
- un contenuto principale;
- una scheda pratica o un esercizio;
- il collegamento alla lezione dal vivo pertinente;
- una verifica tecnica dei link e della visualizzazione mobile;
- uno stato: `bozza`, `in revisione`, `pubblicato`, `da aggiornare`.

Conviene mantenere sempre **2–3 unità già pronte in anticipo**, così una settimana più impegnativa non interrompe le pubblicazioni.

## Cose rinviabili dopo il primo rilascio

Non sono necessarie per provare il flusso di ottobre:

- pagamenti automatici;
- lista d'attesa automatica;
- certificati generati automaticamente;
- statistiche avanzate;
- messaggistica interna completa;
- automazioni sofisticate per notifiche e promemoria;
- gestione completa di tutte le sedi e di tutti i corsi;
- importazione immediata di tutto il materiale storico.

## Definizione di “pronto per ottobre”

Il sistema è pronto quando, senza interventi tecnici sul database:

1. una persona crea o usa il proprio account;
2. si iscrive al percorso online;
3. apre il primo contenuto disponibile;
4. lo segna o lo porta a completamento secondo la regola scelta;
5. ritrova l'avanzamento dopo un nuovo accesso;
6. vede il contenuto successivo disponibile;
7. consulta il programma delle lezioni sapendo che le date saranno aperte in seguito.

## File già collegati a questo piano

- `docs/appunti/programma_didattico_ruoli_e_partecipazioni.md`
- `docs/appunti/ROADMAP_PILOTA_POSTURACORRETTA_E_VISTA_OPERATIVA.md`
- `TODO_ACCADEMIA.md`
- `config/data/posturacorretta/programmi/programma_lezioni_posturacorretta.yml`
- `config/data/posturacorretta/programmi/calendario_lezioni_gruppo.yml`
- `config/data/posturacorretta/accademia/lezioni_programmate.yml`

## Prossimo passo concreto

Partire dalla **Fase 1** e completare un unico caso reale: un utente si iscrive al percorso online, apre la prima unità, salva l'avanzamento e riparte dal punto corretto al nuovo accesso. Solo dopo si ordinano insegnanti, luoghi e servizi necessari alle prenotazioni.
