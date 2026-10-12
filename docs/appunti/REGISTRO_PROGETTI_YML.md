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
2. provare i YAML comuni `DataSession → DataSlot`, collegati ai contenuti;
3. usare i `Node` per Brand, progetti e sottoprogetti, senza introdurre un
   modello `Project` duplicato;
4. registrare avanzamenti con `NodeEvent`, ricerca delle soluzioni con
   `ProblemSolvingCycle` e funzioni riutilizzabili con `ReusableSkill`;
5. modellare partecipazioni o organizzazioni ulteriori solo dopo casi reali
   non rappresentabili dalle relazioni esistenti.
