# Responsabilità più chiare tra gli strumenti

I modelli comuni appartengono alla piattaforma Flowpulse, ma ogni prodotto conserva una responsabilità comprensibile.

## Rails4Business

Progetta e gestisce i processi ripetibili. Il modello `BrandProcess` è implementato e può raccogliere Esperienze.

## GeneraImpresa

Gestisce la struttura dei Node: Brand, progetti, Brand professionali e servizi. Il modello `Service` è implementato e appartiene a un Node.

## 1Impegno

Gestisce il tempo operativo. I calendari appartengono a Node professionali e possono essere contestualizzati su Brand, progetti o altri Node. Esperienze, `DataSession`, `DataSlot` e `DataCommitment` descrivono ciò che viene realmente programmato e svolto.

## Backoffice Flowpulse

Per il pilota, la scheda amministrativa del Node permette al superadmin di verificare calendari, servizi e processi nello stesso punto. È un backoffice tecnico temporaneo: non cambia la responsabilità funzionale dei tre strumenti.

Questa separazione consente di sviluppare un pezzo alla volta senza duplicare dati o trasformare prematuramente ogni definizione in un evento di calendario.
