# Esperienze, eventi e partecipazioni

> **Documento in riallineamento.** Il vocabolario definitivo di eventi e partecipazioni segue l'analisi corrente in [DataEvent MVP — decisioni da analizzare](appunti/data_event_mvp_decisioni.md); questo testo resta temporaneamente come riferimento concettuale.

> **Stato del documento:** distinzione concettuale precedente. Per l'MVP, evento, sessione e slot vengono valutati come nodi dello stesso albero `DataEvent`, mentre `DataCommitment` rappresenta anche registrazione e partecipazione. La futura `Activity` potrà recuperare il ruolo qui attribuito all'Esperienza. Vedi [DataEvent MVP — decisioni da analizzare](appunti/data_event_mvp_decisioni.md).

## Distinzione

- **Esperienza**: descrive che cosa si fa. È una scheda riutilizzabile e non richiede una data.
- **Evento**: stabilisce quando, dove e da chi vengono organizzate una o più esperienze.
- **Sessione o slot**: serve soltanto quando un evento offre più turni, appuntamenti individuali o gruppi.
- **DataCommitment**: registra la partecipazione o l'impegno della singola persona.

```text
Esperienza → Evento → eventuale sessione/slot → DataCommitment
```

## Esperienza

```yml
- slug: mobilita-articolare
  title: Mobilità articolare
  creator_username: markpostura
  projects: [posturacorretta]
  duration_minutes: 60
  type: pratica
```

Può rappresentare una pratica di Igiene Posturale, una camminata, un laboratorio, una presentazione o un formato di incontro riutilizzabile.

## Evento

```yml
- title: Giornata PosturaCorretta al Gaver
  date: "2026-10-17"
  place_slug: gaver
  organizer_usernames: [markpostura]
  experiences:
    - slug: mobilita-articolare
      starts_at: "09:30"
      ends_at: "10:30"
      conductor_usernames: [markpostura]
```

Un incontro unico con una persona è già un evento. Diventa anche un'esperienza riutilizzabile soltanto quando il suo formato può essere riproposto in altre date o contesti.

## Compatibilità degli URL

Il catalogo pubblico utilizza `/eventi`. I precedenti URL `/esperienze` e `/esperienze/:id` rimangono disponibili come redirect permanenti, così i collegamenti esistenti non vengono interrotti.
