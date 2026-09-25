# Riunire ruoli, calendari e servizi nello spazio Professionista

## Problema

Ruoli operativi, calendari professionali e servizi attivi esistono già, ma sono consultabili soltanto in punti amministrativi separati. Chi usa 1Impegno non dispone di una lettura unica del proprio contesto operativo.

## Obiettivo minimo

Aggiungere a 1Impegno la voce condizionale **Professionista**, visibile al superadmin, a chi possiede un Node professionale oppure a chi ha almeno un `RoleAssignment` di tipo `operator`.

## Compreso

- mostrare il Node professionale collegato al profilo, quando presente;
- elencare tutti i ruoli assegnati all’utente e il relativo Node di contesto;
- mostrare i calendari attivi appartenenti al Node professionale;
- mostrare i servizi attivi dei Node sui quali l’utente opera o dei quali è responsabile professionale;
- mantenere la gestione dei servizi in GeneraImpresa;
- mantenere temporaneamente creazione e modifica di Node e calendari negli strumenti superadmin;
- impedire l’accesso diretto agli utenti privi dei requisiti.

## Escluso

- autocertificazione pubblica del ruolo professionale;
- creazione automatica di un Node professionale;
- modifica di prezzi, capienza e condizioni commerciali in 1Impegno;
- ampliamento dei permessi degli operatori.

## Verifica prevista

1. un utente normale non vede Professionista;
2. un operatore vede la voce e i propri ruoli contestuali;
3. un profilo collegato a un Node professionale vede i propri calendari;
4. sono mostrati soltanto i servizi attivi dei Node pertinenti;
5. il superadmin dispone dei collegamenti agli strumenti amministrativi;
6. un accesso diretto non autorizzato torna all’Agenda.

## Esito della verifica locale

- Professionista compare soltanto per superadmin, profili con Node professionale e utenti con un ruolo `operator`;
- la pagina mostra tutti i ruoli dell’utente, distinguendo ruolo generale, funzione operativa e Node di contesto;
- i calendari appartengono al Node professionale collegato al profilo;
- i servizi mostrati sono attivi e appartengono ai Node sui quali l’utente opera o dei quali è responsabile professionale;
- GeneraImpresa rimane il punto indicato per la configurazione dell’offerta;
- test di regressione 1Impegno: 40 esecuzioni, 391 asserzioni, nessun errore.
