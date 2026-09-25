# Weekplan ed Esperienze nello stesso flusso

La navigazione principale di 1Impegno rimane composta da **Agenda**, **Luoghi** e **Contatti**. Durante il pilota, il superadmin trova **Esperienze** come vista interna dell’Agenda, accanto a Elenco e Settimana.

## Cosa è stato collegato

- l’indice delle Esperienze si apre nel workspace di 1Impegno;
- una `DataSession` programmata compare nel Weekplan anche se non possiede ancora un `DataCommitment`;
- un `DataCommitment` associato a un’Esperienza resta visibile nell’Agenda personale;
- le voci collegate del Weekplan e dell’Elenco aprono lo show dell’Esperienza;
- **Registra** può avviare un’attività dentro un’Esperienza, mantenendo un unico Commitment tra registrazione, Agenda e show.

## Confine del pilota

La gestione delle Esperienze e la scelta dell’Esperienza nel pulsante **Registra** restano riservate al superadmin. Node, Service, pagamenti, capienza e permessi operativi definitivi non sono stati ampliati in questo passaggio.
