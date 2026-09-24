# Il modello dei processi entra nella piattaforma

Rails4Business è lo spazio in cui un modo di lavorare viene progettato, descritto e migliorato fino a diventare un processo ripetibile.

Il modello `BrandProcess` è stato implementato con una struttura minima:

```text
node_id
title
slug
description
status
created_by_user_id
```

Il processo appartiene a un Node, può essere in bozza, attivo o archiviato e può raccogliere più `DataExperience`. Il collegamento dell’Esperienza al processo rimane facoltativo: si può iniziare da un’esperienza concreta e organizzarla in seguito.

La gestione tecnica attuale è riservata al superadmin nella scheda del Node. L’interfaccia dedicata di Rails4Business dovrà rendere il processo leggibile e gestibile senza confonderlo con il calendario operativo.

La responsabilità rimane distinta:

- Rails4Business progetta e organizza il processo;
- GeneraImpresa definisce il Node e i servizi offerti;
- 1Impegno usa Esperienze, calendari, Session, Slot e Commitment per svolgerlo.
