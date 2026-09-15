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
- programma lezioni per chi accede: `/posturacorretta/lezioni`;
- primo contatto: WhatsApp al numero configurato, senza form o raccolta dati
  aggiuntiva.

### Quando il pilota è pronto a passare oltre

Non serve un numero prestabilito di persone: basta avere alcuni casi reali,
gestiti dall'inizio alla prima lezione, e una lista chiara dei passaggi che si
ripetono. Quella lista diventerà il requisito della parte operativa.

## 2. YAML comune — prima del database

La fonte di verità è [Architettura comune — contenuti, cicli e servizi](ARCHITETTURA_CICLI_CONTENUTI_E_SERVIZI.md).
Si progetta e prova prima come pagina/prototipo, leggendo YAML di esempio.
Non è ancora un database.

| Livello | Significato minimo | Esempio |
| --- | --- | --- |
| DataSession | ciò che avviene in una fascia | lezione di gruppo 3 |
| DataSlot | contenuto, prenotazione o attività nella sessione | scheda mobilità o appuntamento 16:00 |

Ogni DataSession collega una o più schede/contenuti tramite DataSlot. Una
DataSession può essere presentata come lezione, incontro, appuntamento o
evento. Cycle e Service restano in standby fino alla prova di questa vista.

## 3. Database — solo dopo uso ripetuto

Ordine confermato:

1. `Project`;
2. `ProjectUpdate`;
3. `ProjectNeed`;
4. `ProjectParticipation`;
5. organizzazioni e sovranità.

Le prime entità operative da valutare saranno DataSession e DataSlot. Cycle e
Service arriveranno solo dopo il test dei YAML; senza ripristinare il vecchio
modello `DataEvent`. Project e i modelli di aggiornamento restano successivi
all'uso reale del pilota.
