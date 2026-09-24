# Brand, progetti, professionisti e servizi hanno uno spazio comune

GeneraImpresa diventa il punto in cui si dà forma alle entità economiche e organizzative prima che il lavoro venga inserito in calendario.

La struttura comune è il `Node`, che può rappresentare:

- un Brand dotato di dominio;
- un progetto interno a un Brand;
- il Brand personale di un professionista;
- un altro nodo organizzativo utile al progetto.

Qui ha senso definire anche i `Service`, perché descrivono l’offerta di un Node. Il modello minimale è implementato e contiene identità, descrizione e stato attivo; prezzi, capienza, luoghi, operatori e regole commerciali verranno aggiunti soltanto dopo il pilota.

La gestione tecnica di Node e servizi è oggi disponibile al superadmin nel backoffice Flowpulse. La destinazione funzionale prevista è GeneraImpresa.

GeneraImpresa non sostituisce il calendario: quando un servizio deve essere svolto, 1Impegno lo collega facoltativamente a una `DataSession` e organizza il lavoro tramite Slot e Commitment. I processi ripetibili restano invece nell’ambito Rails4Business.
