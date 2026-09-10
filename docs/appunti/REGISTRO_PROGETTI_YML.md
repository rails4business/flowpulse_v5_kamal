# Registro YAML dei progetti Flowpulse

La fonte iniziale è `config/data/flowpulse/projects.yml`.

Serve a distinguere con poche informazioni i progetti della rete, gli strumenti
interni e le proposte da valutare. Non sostituisce gli archivi già presenti in
PosturaCorretta e GeneraImpresa: quei file restano consultabili come storico,
finché non saranno rivisti uno per uno.

## Regola operativa

Un solo elemento ha `status: active_pilot`. Ora è `posturacorretta`.
Gli altri sono `queued` o `review`: non ricevono nuove funzioni, calendario o
modellazione dati finché il pilota non ha completato un ciclo reale.

## Campi minimi

- `slug`, `title`, `kind`, `ownership`, `status`, `visibility`;
- dominio/percorso, solo quando già esistono;
- una descrizione breve e le aree a cui contribuisce;
- `current_goal` e `next_step`;
- `legacy_sources`, quando esiste un vecchio dettaglio da recuperare.

## Roadmap operativa

La sequenza concreta è descritta in
[`ROADMAP_PILOTA_POSTURACORRETTA_E_VISTA_OPERATIVA.md`](ROADMAP_PILOTA_POSTURACORRETTA_E_VISTA_OPERATIVA.md):

1. usare e testare il pilota PosturaCorretta;
2. progettare la vista comune Root → Day → Session → Task;
3. solo dopo uso reale: `Project`, `ProjectUpdate`, `ProjectNeed`,
   `ProjectParticipation`, e infine organizzazioni/sovranità.
