# Vocabolario comune di Impegno e dei brand

> Fonte di riferimento insieme a
> [Architettura comune — contenuti, cicli e servizi](appunti/ARCHITETTURA_CICLI_CONTENUTI_E_SERVIZI.md).
> Le ipotesi precedenti basate su `DataEvent`, slot e occorrenze sono storiche.

## Regola fondamentale

Non usare la stessa parola per indicare materiale editoriale, programma
operativo e partecipazione reale. Sono tre livelli diversi:

```text
Contenuto → ciò che si legge, vede o pratica
Ciclo     → come si prepara e si svolge
Service   → come si offre e si prenota realmente
```

## Albero editoriale

| Termine | Significato | Non è |
|---|---|---|
| Percorso | Indice YAML che ordina section e corsi di un brand | un calendario o un gruppo reale |
| Section | Raggruppamento editoriale di corsi | una lezione datata |
| Corso | Contenuto padre, anche in formato masterclass | per forza un evento dal vivo |
| Contenuto | Unità editoriale con un solo padre strutturale | una prenotazione |
| Capitolo | Contenuto di spiegazione o apprendimento | automaticamente una lezione reale |
| Scheda | Contenuto pratico normalmente collegato a un capitolo | un intero corso |
| Esercizio | Parte della scheda; contenuto autonomo solo se riusabile | sempre un task |
| Ponte | Figlio che richiama un contenuto originale già collocato altrove | una seconda copia |

Un contenuto eredita visibilità e appartenenza dal padre. Può essere più
riservato, mai più pubblico. Il ponte non ha figli e non può aumentare la
visibilità dell'originale.

## Albero operativo di 1Impegno

| Termine | Significato | Non è |
|---|---|---|
| Cycle | Dima riutilizzabile di lavoro o svolgimento; per ora in standby | automaticamente una data |
| DataSession | Parte operativa, presentabile come lezione, incontro, appuntamento o evento | un contenuto editoriale duplicato |
| DataSlot | Posizione nella Session: contenuto, prenotazione, operatività o task | sempre un'azione da fare |
| Weekplan | Ritmo e limiti settimanali personali | il programma di un corso |

Una DataSession può collegare una o più schede/contenuti tramite DataSlot. È
la Session a decidere quali pratiche vengono svolte insieme nella lezione reale.

## Operatore e funzione nel Brand

| Termine | Significato |
|---|---|
| Operator | Ruolo comune che abilita l'area Impegno nel contesto di un Brand |
| role_operator | Funzione specifica scelta dalla lista del Brand: insegnante, professionista, segreteria, ecc. |

Un Operator può avere più `role_operator` nello stesso Brand. Le funzioni
operano su Session e Slot; non sono ruoli globali dell'utente.

## Partecipazione reale

| Termine | Significato | Stato |
|---|---|---|
| Service | Configurazione commerciale/organizzativa: prezzo, capienza, luogo o online, operatori e prenotazione | futuro, dopo il pilota |
| DataCommitment | Impegno concreto di una persona nel suo calendario | già esistente |
| Luogo / contatto | Risorse riusabili di 1Impegno | già esistenti, da semplificare |

Un corso o una masterclass con prezzo online può essere acquistabile come
contenuto senza diventare un Service. Il Service serve quando si vende la
partecipazione a sessioni reali. Una masterclass passata può diventare
materiale online; la sua replica dal vivo userà un Cycle e un Service.

## Parole da evitare come modelli nuovi

- `DataEvent`, `EventFormat`, `EventOccurrence`, `EventSlot`;
- `Modulo` quando si intende un corso, capitolo, scheda o sessione: usare il
  nome effettivo nel contesto;
- `Evento` come oggetto tecnico separato: è un'etichetta pubblica possibile
  per una Session.

## Collegamenti

- [Architettura comune — contenuti, cicli e servizi](appunti/ARCHITETTURA_CICLI_CONTENUTI_E_SERVIZI.md)
- [Roadmap — pilota PosturaCorretta e vista operativa comune](appunti/ROADMAP_PILOTA_POSTURACORRETTA_E_VISTA_OPERATIVA.md)
- [Registro YAML dei progetti Flowpulse](appunti/REGISTRO_PROGETTI_YML.md)
