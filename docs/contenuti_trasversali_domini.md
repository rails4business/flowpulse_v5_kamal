# Contenuti trasversali tra domini

Ogni dominio conserva il proprio catalogo e i propri file Markdown:

```text
config/data/<dominio>/contenuti/catalog.yml
config/data/<dominio>/contenuti/articoli/<slug>.md
```

Il dominio determina chi pubblica e possiede il contenuto. Il campo `author` contiene invece lo `username` univoco del `Profile` che lo ha realizzato.

```yml
articles:
  - slug: esempio
    title: Titolo del contenuto
    excerpt: Breve presentazione
    author: markpostura
    data_pubblicazione_articolo: "2026-08-21"
    source: articoli/esempio.md
```

`DomainContentCatalog` legge i cataloghi presenti in `config/data/*/contenuti/catalog.yml` e permette due viste:

- `for_domain("posturacorretta")`: tutti i contenuti pubblicati dal dominio;
- `for_author("markpostura")`: tutti i contenuti attribuiti allo stesso profilo nei diversi domini.

La pagina `/markpostura/contenuti` utilizza la seconda vista. Non duplica i Markdown di PosturaCorretta: mostra l'autore e il dominio di provenienza e rimanda alla fonte originale.

## Identità dell'autore

L'identità pubblica viene da `Profile.username`, già protetto da validazione e indice univoci. Un profilo può essere proprietario di più domini, ma continua a utilizzare un solo username in tutti i cataloghi.
