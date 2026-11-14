# Percorso online, lezioni e programma insegnante

Documento di lavoro del 12 novembre 2026. Si procede un passo alla volta e si chiudono le domande di
ogni passo prima di passare al successivo.

## Priorità

1. Sistemare il **percorso online** (`/posturacorretta/percorsi/postura-recupero`) e il numero di lezioni.
2. **Lezioni**: il primo insegnante imposta le lezioni di gruppo; chi vuole lezioni private può prenotarle.
3. **Programma insegnante** con il tirocinio.

Tutto il resto (pagina offerta, prezzi per modalità, servizi costruiti dal professionista, centri)
viene dopo.

## 1. Percorso online

### Stato attuale

- Schede: Percorso online, Programma lezioni, Centri, Insegnanti (`Posturacorretta::HomeJourney`).
- Le stazioni in alto sono una lista fissa nel codice (`HomeJourney::STATIONS`, 9 stazioni) e non
  vengono lette dalla linea `postura-recupero` del catalogo: manca per esempio la Valutazione della
  mobilità articolare.
- L'etichetta dice "Corso 1 di 7" mentre le stazioni sono 9.
- La Prima settimana ha i suoi 7 capitoli online; gli altri corsi vanno verificati uno per uno.
- In "Programma lezioni" le lezioni sono numerate in modo continuo sull'intera linea (Igiene
  Posturale parte da "Lezione 8").

### Da sistemare

- leggere stazioni e ordine dalla linea del catalogo, come la home;
- correggere il conteggio "Corso X di N";
- mostrare per ogni corso il numero di lezioni (Node `course_lesson`) e di capitoli online.

### Domande

1. Nella striscia delle stazioni vanno tutti i Node della linea non-lezione (come in home: 10
   stazioni, inclusa la Valutazione) o solo i corsi?
2. Le lezioni si numerano per corso (Igiene Posturale: lezioni 1–4) o in modo continuo sulla linea?
3. Quali corsi hanno già i contenuti online e quali vanno mostrati come "in preparazione"?

## 2. Lezioni di gruppo e lezioni private

### Obiettivo

- **Gruppo**: il primo insegnante (markpostura) programma le lezioni di un corso: data, luogo o
  online, posti. La persona si iscrive a un posto.
- **Private**: la persona chiede o prenota una lezione individuale con l'insegnante.

### Strumenti già presenti

`DataExperience`, `DataSession` (la lezione programmata), `DataSlot` (orario/posto) e
`DataCommitment` (l'impegno della persona). La lezione programmata si collega alla lezione del corso
(Node `course_lesson`).

### Domande

1. Dove l'insegnante programma le lezioni: nell'area admin del Brand o in un'area insegnante dedicata?
2. Lezione privata: prenotazione diretta su orari che l'insegnante rende disponibili, oppure
   richiesta che l'insegnante conferma?
3. Una lezione di gruppo copre una sola lezione del corso o un ciclo (tutte le lezioni del corso)?
4. Online, in presenza o entrambe per le lezioni di gruppo?

## 3. Programma insegnante e tirocinio

### Proposta da verificare

Il tirocinio **scende dal corso** (figlio del Node corso), non è una linea parallela:

```text
Corso Igiene Posturale
├─ lezioni del corso
└─ Tirocinio Igiene Posturale
   ├─ lezioni di tirocinio
   └─ verifica / abilitazione
```

Le lezioni di tirocinio consistono nel partecipare come tirocinante alle lezioni reali del corso
(punto 2). La linea **Diventa insegnante** unisce i corsi da completare e i rispettivi tirocini.

### Domande

1. Il tirocinio ha un `view_type` dedicato (per esempio `internship`)?
2. Quante lezioni di tirocinio per corso e chi le valida?
3. Chi può iniziare il tirocinio: solo chi ha completato il corso?

## Dopo

- pagina dell'offerta con scelta della modalità e prezzo;
- abilitazione di centri e altri insegnanti;
- servizi costruiti dal professionista con `DataSession` e `DataSlot`;
- durata calcolata e card delle offerte in home con modalità e prezzo.
