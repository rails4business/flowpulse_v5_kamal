# Catalogo contenuti PosturaCorretta

## Obiettivo

La pagina Contenuti deve permettere alle persone di esplorare video, articoli, corsi ed esperienze attraverso una tassonomia comune: ambiti, aree, paradigmi, professionisti e luoghi.

## Tassonomia editoriale

La sorgente iniziale è `config/data/posturacorretta/contenuti/tassonomia.yml`.

- **Ambiti**: rappresentano la domanda o il contesto principale.
- **Aree**: indicano il punto di lavoro prevalente.
- **Paradigmi**: rendono leggibile il modello con cui un contenuto affronta l'argomento.
- **Sottoambiti**: possono avere figli e nipoti; ad esempio Stop al dolore → condizioni / zone anatomiche, Prevenzione → attività / fasi di vita e condizioni.
- **Professionisti e luoghi**: vengono dalla directory condivisa di PosturaCorretta, non dalla rubrica privata di Impegno.

## Metadata per un contenuto

Ogni contenuto del catalogo dovrà progressivamente avere:

```yml
taxonomy:
  ambito: dolore
  area: cura
  paradigma: fisiologico
  percorso: [stop-al-dolore, condizioni, lombalgia]
directory:
  professionisti: [giovanni-damiata]
  luoghi: []
```

Finché i metadata non sono completi, il catalogo conserva la categoria attuale come classificazione di base.

## Filtri e URL

I filtri devono restare nell'URL per poter condividere una ricerca:

`?categoria=dolore&tema=stop-al-dolore&area=cura&paradigma=fisiologico&professionista=giovanni-damiata`

## Gestione editoriale prevista

L'addetto ai contenuti avrà una pagina dedicata per creare nodi della tassonomia, collegare file e contenuti, assegnare professionisti e luoghi e controllare bozze, pubblicazioni e metadata mancanti. Per ora la fonte rimane YAML, così la struttura può essere verificata prima di introdurre un editor database.
