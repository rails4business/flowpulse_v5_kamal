# Distinguere Node professionali e Node progetto

## Decisione

`Node#node_type` distingue soltanto la natura dell'entità:

- `professional`: attività o identità professionale;
- `project`: progetto, processo o contenitore organizzativo.

Un Node diventa anche un **Brand** quando possiede almeno un `Domain`. Il tipo del Node non cambia quando viene associato il dominio.

## Migrazione

Il precedente booleano `professional` viene assorbito dall'enum `node_type`. I Node precedentemente professionali diventano `professional`; tutti gli altri diventano `project`.

## Primo caso pilota

Radioestesia viene predisposta senza dominio nella gerarchia gestionale temporanea:

```text
GeneraImpresa · project
└── Brand in costruzione · project
    └── Radioestesia e Benessere · professional
```

La posizione sotto **Brand in costruzione** descrive il lavoro ancora in preparazione. Quando Radioestesia avrà il proprio dominio, potrà essere resa un Node principale eliminando il `parent_id`, senza cambiare `node_type`.

L'associazione al profilo di Elisa e i relativi ruoli non vengono creati finché l'utente non è disponibile.

## Verifica

- migrazione locale completata;
- catalogo Node aggiornato;
- accessi basati su `professional?` conservati tramite enum;
- 51 test mirati, 348 asserzioni, nessun errore;
- suite Rails completa: 404 test, 2.878 asserzioni, nessun errore;
- test eseguiti con un worker per evitare un crash nativo locale di `pg 1.6.3` durante il fork parallelo con Ruby 4.0.3.
