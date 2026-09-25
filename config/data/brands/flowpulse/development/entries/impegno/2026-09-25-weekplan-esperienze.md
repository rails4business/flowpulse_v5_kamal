# Coordinare Weekplan ed Esperienze in 1Impegno

## Problema

Agenda, Weekplan ed Esperienze esistono già, ma sono ancora percepiti come strumenti separati. Il Weekplan legge soltanto gli impegni personali, mentre una Sessione programmata dentro un’Esperienza non compare se non possiede ancora un Commitment. Il pulsante **Registra** crea inoltre un’attività senza permettere di indicare l’Esperienza a cui appartiene.

## Obiettivo minimo

Usare un unico flusso operativo:

```text
Esperienza → Sessione / Slot / Commitment → Agenda e Weekplan
```

## Compreso

- mantenere come aree principali soltanto Agenda, Luoghi e Contatti;
- aggiungere Esperienze come vista interna dell’Agenda, riservata al superadmin durante il pilota;
- mostrare nel Weekplan sia le Sessioni programmate sia i Commitment personali;
- collegare gli elementi del Weekplan allo show dell’Esperienza;
- permettere a **Registra** di creare un Commitment diretto dentro un’Esperienza;
- conservare il ritorno alla pagina dalla quale è iniziata la registrazione;
- coprire il flusso con test di controller.

## Escluso

- gestione definitiva dei permessi di operatori e creator;
- interfacce di gestione per Node e Service;
- pagamenti, capienza e prenotazioni;
- modifica della gerarchia dati già validata.

## Verifica prevista

1. aprire Esperienze dalla sottovista Agenda;
2. creare o aprire un’Esperienza;
3. registrare un’attività associata all’Esperienza;
4. verificare che il Commitment compaia nello show e nell’Agenda;
5. programmare una Sessione e verificare che compaia nel Weekplan anche senza Commitment;
6. aprire l’Esperienza dalla relativa voce del Weekplan.

## Esito della verifica locale

- Esperienze è disponibile come sottovista dell’Agenda per il superadmin;
- l’indice viene caricato nello stesso workspace Turbo di Elenco e Settimana;
- le Sessioni programmate compaiono nel Weekplan anche senza Commitment;
- Sessioni e Commitment collegati aprono lo show dell’Esperienza;
- **Registra** può creare e avviare un Commitment diretto nell’Esperienza;
- il flusso conserva il ritorno allo show o alla vista di partenza;
- test mirati: 51 esecuzioni, 548 asserzioni, nessun errore.
