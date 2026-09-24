# Calendari professionali e Node di contesto

Abbiamo separato i concetti che prima rischiavano di sovrapporsi:

- il **calendario professionale** organizza il tempo di un professionista;
- il **servizio** descrive ciò che un Node offre, ma viene amministrato attraverso GeneraImpresa;
- il **processo** raccoglie il modo ripetibile con cui viene realizzato il lavoro ed è gestito attraverso Rails4Business;
- `DataSession`, `DataSlot` e `DataCommitment` descrivono il lavoro concreto e rimangono nell’area operativa di 1Impegno.

## ProfessionalCalendar

Ogni calendario conserva:

```text
professional_node_id
context_node_id
```

`professional_node_id` identifica il proprietario del calendario. `context_node_id` può indicare un Brand, un Project oppure un Node interno, per esempio il progetto YouTube di PosturaCorretta.

Dal Node di contesto il sistema risale tramite `parent_node_id` fino al primo antenato dotato di Domain. Non vengono quindi duplicati Brand e dominio dentro le Session.

Il proprietario deve essere un Node professionale. Per questo la creazione e la gestione quotidiana dei calendari appartengono all’area professionale di 1Impegno. Un Brand non professionale può essere il contesto del calendario, non il suo proprietario.

## Confine con servizi e processi

`BrandActivity` è stato eliminato e sostituito dal modello minimale `Service`. Il modello è già presente, ma il servizio non viene amministrato come parte del calendario:

```text
node_id
title
slug
description
active
created_by_user_id
```

Una `DataSession` può indicare un servizio, ma non è obbligatorio. GeneraImpresa definirà il servizio; 1Impegno lo userà per organizzare Session, Slot e Commitment. Prezzo, capienza, luogo, operatori e regole di partecipazione verranno introdotti dopo la validazione del pilota.

Allo stesso modo, Rails4Business definisce i processi e le Esperienze possono collegarsi a essi senza rendere obbligatoria l’appartenenza.

## Week Plan

I cinque spazi iniziali di MarkPostura sono ora veri calendari professionali. Gli URL condivisibili usano `calendars=`; il precedente parametro `spaces=` rimane temporaneamente compatibile.

Il modello, il registro YAML, la validazione e l’import sono implementati. La gestione attuale è disponibile al superadmin nella scheda del Node; l’interfaccia autonoma per il professionista in 1Impegno è il passaggio successivo.

Per ora lo sviluppo di `DataSession`, `DataSlot` e `DataCommitment` resta fermo al nucleo già realizzato, in attesa di verificare i calendari in produzione.
