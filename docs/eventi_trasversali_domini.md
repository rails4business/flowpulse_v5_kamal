# Eventi trasversali tra domini, progetti e persone

> **Documento in riallineamento.** Le regole trasversali ancora valide verranno adattate alla struttura `DataEvent` + `DataCommitment` definita in [DataEvent MVP — decisioni da analizzare](appunti/data_event_mvp_decisioni.md).

> **Stato del documento:** descrive il catalogo YAML attualmente in uso. Il target dell'MVP è trasferire progressivamente gli eventi operativi nel database tramite `DataEvent`; il catalogo YAML non sarà la fonte definitiva. Vedi [DataEvent MVP — decisioni da analizzare](appunti/data_event_mvp_decisioni.md).

Nella versione attuale ogni evento possiede una sola fonte YAML. Il record distingue:

- `canonical_domain`: il dominio che pubblica l'evento e ne conserva la fonte;
- `projects`: i progetti e i brand coinvolti nell'iniziativa;
- `organizer_usernames`: i profili che organizzano l'evento;
- `professional_slugs` e `teacher_usernames`: chi conduce le attività con un ruolo professionale o educativo;
- `place_slug`: il luogo nel quale si svolge.

Esempio:

```yml
- slug: accordare-il-corpo-autunno
  title: Accordare il corpo all'autunno
  canonical_domain: posturacorretta
  projects: [posturacorretta, giardino-del-corpo]
  organizer_usernames: [markpostura]
  professional_slugs: []
  teacher_usernames: []
  place_slug: gaver
```

Lo stesso record può essere recuperato con:

```ruby
DomainEventCatalog.for_domain("posturacorretta")
DomainEventCatalog.for_project("giardino-del-corpo")
DomainEventCatalog.for_organizer("markpostura")
```

Il catalogo attuale di PosturaCorretta utilizza valori predefiniti dichiarati all'inizio del file. Gli eventi che includono l'ambito `giardino` vengono collegati anche al progetto `giardino-del-corpo`. Eventuali eccezioni possono sovrascrivere i valori nel singolo evento.
