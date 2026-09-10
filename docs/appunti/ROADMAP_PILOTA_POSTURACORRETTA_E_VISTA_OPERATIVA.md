# Roadmap — pilota PosturaCorretta e vista operativa comune

## Principio

Prima si usa un percorso reale. Poi si modella ciò che si è ripetuto davvero.
Nessuna nuova tabella in questa fase.

## 1. Pilota PosturaCorretta — adesso

**Obiettivo:** accompagnare le prime persone dal sito a un primo incontro e a
una prima lezione, usando gli strumenti già esistenti.

### Percorso della persona

1. entra da `/posturacorretta` e comprende i tre progetti;
2. può leggere i corsi online senza prenotare;
3. può vedere il programma lezioni e le schede pratiche;
4. quando desidera iniziare, usa il pulsante WhatsApp per richiedere un primo
   incontro;
5. la richiesta viene gestita manualmente: si chiariscono bisogno, luogo,
   disponibilità e se iniziare in gruppo o singolarmente;
6. solo quando esiste un appuntamento concreto lo si registra in 1Impegno.

### Cosa verificare con persone reali

- se capiscono la differenza fra corsi online e programma di lezioni;
- se il pulsante WhatsApp è sufficiente per fare il primo passo;
- quali informazioni chiedono sempre prima di fissare l'appuntamento;
- se il primo incontro sfocia in una lezione, in un gruppo oppure in un
  orientamento ad altro percorso;
- quali parole o schermate creano confusione.

### Materiale già disponibile

- home: `/posturacorretta`;
- tre progetti: `/posturacorretta/tre-progetti`;
- presentazione stampabile: `/posturacorretta/presentazione-posturacorretta`;
- programma lezioni per chi accede: `/posturacorretta/dashboard`;
- primo contatto: WhatsApp al numero configurato, senza form o raccolta dati
  aggiuntiva.

### Quando il pilota è pronto a passare oltre

Non serve un numero prestabilito di persone: basta avere alcuni casi reali,
gestiti dall'inizio alla prima lezione, e una lista chiara dei passaggi che si
ripetono. Quella lista diventerà il requisito della parte operativa.

## 2. Vista operativa comune — dopo il pilota

Si progetta e prova prima come pagina/prototipo, leggendo YAML di esempio.
Non è ancora un database e non si chiama automaticamente “evento”.

| Livello | Significato minimo | Esempio |
| --- | --- | --- |
| Root | contenitore o intenzione | Gruppo PosturaCorretta di Leno |
| Day | una fascia concreta in una data | mercoledì 15:00–16:00 |
| Session | ciò che avviene in quella fascia | lezione di gruppo 3 |
| Task | azione preparatoria o conseguenza | preparare le tre schede |

La stessa vista deve poter affiancare un progetto, un impegno personale o un
incontro, senza mescolarli: il Root può riferirsi a un progetto, mentre Day,
Session e Task descrivono il lavoro concreto.

## 3. Database — solo dopo uso ripetuto

Ordine confermato:

1. `Project`;
2. `ProjectUpdate`;
3. `ProjectNeed`;
4. `ProjectParticipation`;
5. organizzazioni e sovranità.

Eventuali entità operative arriveranno soltanto dopo avere validato la vista
comune nel pilota, senza ripristinare il vecchio modello `DataEvent`.
