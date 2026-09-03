# Vocabolario comune di Impegno e dei brand

> **Aggiornamento MVP:** lo schema basato su Proposta/Occorrenza/Partecipazione è in revisione. La direzione corrente usa `DataEvent` come nodo organizzativo e temporale e `DataCommitment` anche come registrazione. Le decisioni vengono confermate in [DataEvent MVP — decisioni da analizzare](appunti/data_event_mvp_decisioni.md); le definizioni storiche sottostanti restano da riallineare una alla volta.

## Obiettivo

Questo documento definisce il significato dei termini condivisi tra Impegno e i brand che lo utilizzano. Serve a evitare che parole come evento, lezione, appuntamento, programma e attività vengano usate contemporaneamente per indicare un contenuto riutilizzabile, una data reale o la partecipazione di una persona.

Il vocabolario viene valutato un termine alla volta prima di introdurre nuovi modelli, tabelle o fonti YAML.

Per ogni termine vanno chiariti:

- significato;
- nome tecnico ed etichetta mostrata nell'interfaccia;
- proprietario tecnico;
- brand che lo utilizzano;
- chi lo crea, modifica e vede;
- fonte di verità;
- relazioni con gli altri termini;
- cosa non rappresenta;
- stato: esistente, progettato oppure da decidere.

## Schema precedente da riallineare

```text
Brand / Dominio
└── DataEvent (Routine | Percorso | Classe | Corso | Evento)
    ├── regola di ricorrenza facoltativa
    ├── DataEvent figli (giorni | sessioni | slot)
    └── DataCommitment (registrazioni e impegni personali)
```

## Matrice iniziale

La matrice è una prima ipotesi e verrà corretta durante l'analisi.

| Termine | Proprietario tecnico | PosturaCorretta | Percorso Integrato | GeneraImpresa | Giardino del Corpo | Canta che ti passa | Stato |
|---|---|:---:|:---:|:---:|:---:|:---:|---|
| Proposta | Da decidere | ✓ | ✓ | ✓ | ✓ | ✓ | Da definire |
| Scheda | Brand | ✓ | ✓ | ✓ | ✓ | ✓ | Parziale |
| Programma | Brand | ✓ | ✓ | ✓ | ✓ | ✓ | Parziale |
| Modulo | Brand | ✓ | ✓ | ✓ | ✓ | ✓ | Parziale |
| Occorrenza | Impegno | ✓ | ✓ | ✓ | ✓ | ✓ | Progettata |
| Disponibilità | Impegno | ✓ | ✓ |  | ✓ | ✓ | Da implementare |
| Slot | Impegno | ✓ | ✓ |  | ✓ | ✓ | Progettato |
| Partecipazione | Impegno | ✓ | ✓ | ✓ | ✓ | ✓ | Progettata |
| DataCommitment | Impegno | ✓ | ✓ | ✓ | ✓ | ✓ | Implementato |
| Ricorrenza | Impegno | ✓ | ✓ | ✓ | ✓ | ✓ | Da implementare |
| Ruolo contestuale | Impegno e dominio | ✓ | ✓ | ✓ | ✓ | ✓ | Parziale |
| Progetto, fase, step e task | GeneraImpresa |  |  | ✓ |  |  | Implementato in parte |

## Termini da analizzare

### Viste personali iniziali di Impegno

Questi termini descrivono per ora cinque modi di organizzare l'esperienza personale. Non costituiscono cinque calendari o cinque fonti dati differenti.

#### Routine

Attività personale ripetibile che la persona decide di svolgere con una certa frequenza. Può avere una scheda e una regola di ricorrenza; soltanto le esecuzioni pianificate o registrate diventano DataCommitment.

Esempi: pratica posturale quotidiana, esercitazione musicale, assunzione o controllo ricorrente, revisione settimanale.

#### Percorsi

Insieme finalizzato e coordinato di programmi, tappe, moduli e partecipazioni. Può coinvolgere più ruoli e più brand; le singole date del percorso entrano nel calendario come DataCommitment.

Esempi: Percorso Integrato per la salute, percorso educativo PosturaCorretta, percorso personale di apprendimento.

#### Classi

Gruppo relativamente stabile che si incontra con continuità secondo un calendario. La classe identifica gruppo, conduttore, luogo e regole; le singole lezioni sono occorrenze e le presenze generano partecipazioni e DataCommitment.

Esempi: gruppo settimanale di Igiene Posturale, classe di yoga, gruppo musicale continuativo.

#### Corsi

Struttura didattica ordinata composta da contenuti, capitoli, moduli o lezioni. Il corso può essere fruito online senza data oppure accompagnato da incontri programmati; soltanto questi ultimi occupano il calendario.

Esempi: PosturaCorretta in un mese, corso di Igiene Posturale, corso di chitarra.

#### Eventi

Iniziativa organizzata e comunicabile al pubblico o a un gruppo, realizzata in una o più date. Può contenere più sessioni, richiedere iscrizione e collegare esperienze o moduli provenienti dai brand.

Esempi: giornata PosturaCorretta, evento del Giardino del Corpo, presentazione, masterclass, concerto o laboratorio.

### Viste operative iniziali

Le viste operative dipendono dal ruolo contestuale. Il professionista conserva Prestazioni, Percorsi, Classi, Corsi ed Eventi. L'insegnante usa inizialmente Lezioni, Percorsi, Classi, Corsi ed Eventi. Le matrici definitive di Tutor, Segreteria e Responsabile della sede verranno valutate nel punto dedicato ai ruoli.

### 1. Proposta

**Domanda:** che cosa viene offerto, organizzato o reso ripetibile?

- **Significato provvisorio:** definizione riutilizzabile di una lezione, un incontro, una prestazione, una classe, un corso, un evento, una routine o un'attività progettuale.
- **Nome tecnico:** da decidere tra `Proposal`, `Offering`, `Format` o un nome più neutro.
- **Proprietario tecnico:** da decidere; il contenuto potrebbe appartenere al brand mentre Impegno ne usa soltanto l'identità e le regole operative.
- **Non significa:** proposta commerciale non ancora approvata, singola data, prenotazione o presenza in calendario.
- **Stato:** da definire.

### 2. Scheda

**Domanda:** come si svolge e che cosa bisogna sapere?

- **Significato provvisorio:** obiettivo, destinatari, preparazione, pratica, materiali, verifiche, risultati attesi e collegamenti.
- **Proprietario tecnico:** normalmente il brand che definisce il contenuto.
- **Questioni aperte:** scheda unica oppure versioni per partecipante, conduttore, Base e Avanzato.
- **Non significa:** data, luogo, partecipanti o stato della prenotazione.
- **Stato:** presente in forme diverse, da uniformare.

### 3. Programma

**Domanda:** da quali parti ordinate è composta una proposta?

- **Significato provvisorio:** sequenza ordinata di moduli o attività.
- **Proprietario tecnico:** brand.
- **Non significa:** calendario delle date o insieme dei DataCommitment personali.
- **Stato:** presente in forme diverse, da uniformare.

### 4. Modulo

**Domanda:** quale unità didattica o operativa riutilizzabile viene inserita nel programma?

- **Significato provvisorio:** contenuto riutilizzabile che può essere combinato con altri moduli in lezioni, incontri, eventi o percorsi.
- **Proprietario tecnico:** brand.
- **Non significa:** necessariamente una lezione completa o una data reale.
- **Stato:** presente soprattutto nel percorso educativo PosturaCorretta, da confrontare con gli altri brand.

### 5. Occorrenza

**Domanda:** quando e dove viene realizzata una proposta?

- **Significato provvisorio:** singola realizzazione datata, con inizio, fine, luogo o URL, conduttori, capienza e stato.
- **Nome tecnico proposto:** `Occurrence`.
- **Etichette possibili nell'interfaccia:** Data, Edizione, Lezione, Incontro oppure Appuntamento secondo il contesto.
- **Proprietario tecnico:** Impegno.
- **Non significa:** presenza della singola persona nel calendario.
- **Stato:** progettata, non ancora implementata come modello autonomo.

### 6. Disponibilità

**Domanda:** quando una persona, un luogo o una risorsa può essere prenotata?

- **Significato provvisorio:** fascia temporale offerta, eventualmente ricorrente.
- **Proprietario tecnico:** Impegno.
- **Non significa:** appuntamento confermato o spazio necessariamente occupato.
- **Stato:** da implementare.

### 7. Slot

**Domanda:** quale intervallo preciso può essere scelto?

- **Significato provvisorio:** intervallo prenotabile ricavato da una disponibilità oppure pubblicato direttamente.
- **Proprietario tecnico:** Impegno.
- **Non significa:** DataCommitment; diventa un impegno personale soltanto quando la partecipazione viene confermata.
- **Stato:** progettato nell'architettura degli eventi.

### 8. Partecipazione o prenotazione

**Domanda:** chi aderisce a un'occorrenza o a uno slot e con quale stato?

- **Significato provvisorio:** relazione tra profilo e occorrenza o slot, con ruolo, richiesta, conferma, presenza, annullamento ed eventuale stato economico.
- **Nome tecnico proposto:** `Participation`; Prenotazione può essere uno stato o una sua specializzazione.
- **Proprietario tecnico:** Impegno.
- **Non significa:** definizione della proposta o data generale dell'evento.
- **Stato:** progettata.

### 9. DataCommitment

**Domanda:** che cosa occupa concretamente un calendario personale?

- **Significato:** singolo impegno temporale di una persona o di un calendario delegato.
- **Nome tecnico attuale:** `Brands::Impegno::Commitment` con alias `DataCommitment`.
- **Proprietario tecnico:** Impegno.
- **Fonte di verità:** tabella `data_commitments`.
- **Usi:** lezione condotta o frequentata, appuntamento, routine eseguita, attività GeneraImpresa, partecipazione a un evento, scadenza o attività organizzativa.
- **Non significa:** disponibilità generica, programma, scheda o definizione riutilizzabile.
- **Stato:** implementato.

### 10. Ricorrenza

**Domanda:** con quale regola vengono generate più occorrenze?

- **Significato provvisorio:** regola temporale con periodo di validità, frequenza ed eccezioni.
- **Proprietario tecnico:** Impegno.
- **Non significa:** una singola occorrenza; deve generare date modificabili senza perdere lo storico.
- **Stato:** prevista ma non implementata.

### 11. Ruolo contestuale

**Domanda:** in quale funzione partecipa una persona nel dominio e nella singola attività?

- **Ruolo nel dominio:** assegnazione stabile, per esempio insegnante, tutor, professionista o segreteria.
- **Ruolo nell'occorrenza:** funzione svolta in quella data, per esempio conduttore, partecipante, tirocinante, organizzatore o supervisore.
- **Proprietario tecnico:** autorizzazioni nel dominio; uso operativo in Impegno.
- **Stato:** `RoleAssignment` contestuale è implementato; il collegamento alle singole occorrenze e ai commitment va definito.

## Distinzioni da conservare

```text
Lezione ≠ partecipazione alla lezione
Evento ≠ data dell'evento
Disponibilità ≠ appuntamento
Slot ≠ DataCommitment
Scheda ≠ programma
Modulo ≠ lezione
Percorso ≠ somma dei commitment
Ruolo nel dominio ≠ ruolo nella singola attività
```

## Collegamenti

- Piano di avvio: [appunti/avvio_piattaforma_posturacorretta.md](appunti/avvio_piattaforma_posturacorretta.md)
- Architettura Impegno ed eventi: [impegno_eventi_architettura.md](impegno_eventi_architettura.md)
- Esperienze, eventi e commitment: [esperienze_eventi_commitment.md](esperienze_eventi_commitment.md)
