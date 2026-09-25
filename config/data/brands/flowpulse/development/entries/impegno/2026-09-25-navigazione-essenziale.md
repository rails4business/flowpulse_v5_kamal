# Semplificare la navigazione di 1Impegno

## Problema

La navigazione mostra correttamente le aree **Agenda**, **Luoghi** e **Contatti**, ma nella barra interna dell’Agenda compare anche **Struttura & Calendari**. Questa voce sovrappone configurazione e uso quotidiano e rende meno immediato il rapporto tra elenco, settimana ed esperienze.

## Obiettivo minimo

Usare una sola barra di navigazione, senza distinguere tra aree principali e viste secondarie:

```text
Agenda · Settimana · Esperienze · Luoghi · Contatti
```

## Compreso

- usare **Agenda** come nome dell’attuale vista Elenco;
- mostrare **Agenda**, **Settimana**, **Esperienze**, **Luoghi** e **Contatti** nella stessa barra;
- eliminare la seconda barra e la voce duplicata **Elenco**;
- conservare i parametri necessari per condividere e riaprire la stessa vista;
- rimuovere **Struttura & Calendari** dalla navigazione operativa;
- conservare temporaneamente la relativa pagina e le sue funzioni come strumento interno, finché ogni informazione utile non sarà ricollocata;
- aggiornare i test di navigazione e dei parametri.

## Escluso

- eliminazione dei modelli o dei dati relativi ai calendari;
- nuova gestione dei calendari professionali;
- modifica dei permessi di operatori, creator o utenti;
- interventi su Node, Service, pagamenti o prenotazioni.

## Verifica prevista

1. aprire `/impegno` e vedere una sola barra con Agenda, Settimana, Esperienze, Luoghi e Contatti;
2. passare direttamente tra le cinque destinazioni senza una seconda barra;
3. verificare che la vista selezionata rimanga nell’URL;
4. verificare che nessuna destinazione mostri una seconda barra di navigazione;
5. verificare che Struttura & Calendari non sia più esposta nella navigazione quotidiana;
6. confermare che la pagina interna precedente non sia stata cancellata.

## Esito della verifica locale

- la shell mostra una sola barra con Agenda, Settimana, Esperienze, Luoghi e Contatti;
- Agenda sostituisce la precedente etichetta Elenco;
- la destinazione corrente conserva `aria-current="page"` e i parametri continuano a selezionare la vista richiesta;
- Struttura & Calendari non compare nella barra, ma resta raggiungibile dallo strumento interno nel footer del superadmin;
- test mirati: 19 esecuzioni, 225 asserzioni, nessun errore.
