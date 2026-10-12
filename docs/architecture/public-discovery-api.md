# Public Discovery API — Domain, Node e risorse

La Public Discovery API espone la proiezione anonima del Domain, dei Node e dei
prodotti pubblici generati dalle Skill. È read-only, non richiede
autenticazione e usa esattamente la stessa policy di pagine HTML, sitemap,
robots, JSON-LD e `llms.txt`.

## Endpoint

```text
GET /api/v1/domain
GET /api/v1/nodes
GET /api/v1/nodes/:slug
GET /api/v1/resources
GET /api/v1/resources/:id
```

Ogni dominio pubblico offre anche il documento testuale complementare:

```text
GET /llms.txt
```

`llms.txt` riassume il dominio e collega sito, sitemap, API e Node pubblici.
Viene generato da `PublicDiscovery::Projection`, quindi applica gli stessi
confini dell'API e non espone Node privati, appunti, attivazioni o prodotti
delle Skill riservati.

Gli endpoint vengono interpretati rispetto all'host richiesto. Per esempio:

```text
https://posturacorretta.org/api/v1/domain
https://posturacorretta.org/api/v1/nodes
```

Un alias viene rediretto permanentemente all'host canonico. Un dominio con
Node radice non pubblico restituisce `404`.

## Un'unica regola pubblica

`PublicDiscovery::AccessPolicy` è la fonte di verità. Un elemento entra nella
discovery soltanto quando è pubblicato e visibile al pubblico. Per un prodotto
di una Skill devono inoltre essere vere tutte queste condizioni:

- il Domain canonico è attivo e il suo Node radice è `published/public`;
- il Node del prodotto e tutti i suoi antenati nel dominio sono
  `published/public`;
- l'attivazione della Skill sul Node è `active`;
- la Skill è `available` oppure `maintenance`;
- il prodotto è `published/public`.

Le visibilità `subscription`, `purchase` e `private` restano fuori da HTML
pubblico, sitemap, API e AI. Non esiste un secondo interruttore `visibility_ai`:
ciò che è anonimamente accessibile è anche ricercabile; ciò che richiede un
accesso non viene proiettato.

## Contratto

Le risposte contengono `schema_version: 2`, un riepilogo del dominio, URL
canonici e dati già filtrati da `PublicDiscovery::Projection`.

- `/domain` restituisce identità, Node radice, numero di Node e link API;
- `/nodes` restituisce Node radice e lista piatta dei Node pubblici;
- `/nodes/:slug` restituisce il Node richiesto e i suoi figli pubblici diretti.
- `/resources` restituisce i prodotti pubblici delle Skill attive;
- `/resources/:id` restituisce metadata e corpo pubblico della risorsa, senza
  percorsi locali o metadata amministrativi.

Se uno slug non è pubblico nel dominio viene restituito:

```json
{
  "error": {
    "code": "node_not_found",
    "message": "Il Node non è pubblico su questo dominio."
  }
}
```

Un raro slug duplicato nello stesso dominio produce `409
ambiguous_node_slug` invece di scegliere silenziosamente un Node.

## HTTP e sicurezza

- `Cache-Control` pubblico: 5 minuti, con `stale-while-revalidate` di un'ora;
- `ETag` e richieste condizionali con risposta `304`;
- `Access-Control-Allow-Origin: *` perché vengono esposti soltanto dati già
  anonimi e pubblici;
- `X-Content-Type-Options: nosniff`;
- errori e risorse non pubbliche usano `Cache-Control: no-store`.

Non vengono esposti DataCommitment, richieste, utenti, ruoli amministrativi,
processi, eventi di sviluppo, note interne o ProblemSolving. Le future Skill
specializzate potranno aggiungere campi pubblici propri, ma dovranno passare
dalla stessa policy e dalla stessa proiezione.
