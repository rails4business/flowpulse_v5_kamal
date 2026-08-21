# Contenuti trasversali tra domini

Ogni dominio conserva il proprio catalogo e i propri file Markdown:

```text
config/data/<dominio>/contenuti/catalog.yml
config/data/<dominio>/contenuti/articoli/<anno>/<AAAA-MM-GG-slug>.md
```

Il dominio determina chi pubblica e possiede il contenuto. Il campo `author` contiene invece lo `username` univoco del `Profile` che lo ha realizzato.

```yml
articles:
  - slug: esempio
    title: Titolo del contenuto
    excerpt: Breve presentazione
    author: markpostura
    source: articoli/2026/2026-08-21-esempio.md
```

La data di pubblicazione ha una sola fonte di verità: il prefisso del file Markdown. Il catalogo la ricava automaticamente per ordinamento, programmazione e visualizzazione. Il titolo pubblico e lo slug restano indipendenti dalla data, quindi URL e collegamenti non cambiano quando il contenuto viene spostato nell'archivio annuale.

I contenuti storici ancora privi di un file datato continuano a funzionare e vengono mostrati dopo quelli con data. Le date interne di lavorazione video (`data_registrazione_video` e `data_pubblicazione_video`) restano nel catalogo perché descrivono attività differenti dalla pubblicazione dell'articolo.

`DomainContentCatalog` legge i cataloghi presenti in `config/data/*/contenuti/catalog.yml` e permette due viste:

- `for_domain("posturacorretta")`: tutti i contenuti pubblicati dal dominio;
- `for_author("markpostura")`: tutti i contenuti attribuiti allo stesso profilo nei diversi domini.

La pagina `/markpostura/contenuti` utilizza la seconda vista. Non duplica i Markdown di PosturaCorretta: mostra l'autore e il dominio di provenienza e rimanda alla fonte originale.

## Identità dell'autore

L'identità pubblica viene da `Profile.username`, già protetto da validazione e indice univoci. Un profilo può essere proprietario di più domini, ma continua a utilizzare un solo username in tutti i cataloghi.
