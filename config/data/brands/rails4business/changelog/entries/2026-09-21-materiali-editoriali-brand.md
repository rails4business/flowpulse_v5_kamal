# Materiali editoriali organizzati per Brand

È stata fissata una convenzione comune per distinguere i materiali editoriali:

```text
config/data/brands/<brand>/
├── books/
├── contents/
├── courses/
└── docs/
```

I testi rimangono in Markdown, mentre YAML mantiene metadati, indici e ordine. In questo modo i materiali possono essere revisionati a mano, letti dai programmatori e interpretati dagli strumenti AI senza dipendere subito dal database.

Per PosturaCorretta sono stati distinti:

- il percorso educativo online;
- i corsi e i relativi capitoli teorici o pratici;
- il programma delle lezioni in presenza;
- i contenuti editoriali;
- i documenti tecnici;
- i libri.

I documenti propri del Percorso Integrato sono stati separati da PosturaCorretta. Il registro amministrativo del materiale permette di individuare sorgenti, bozze e contenuti da revisionare.
