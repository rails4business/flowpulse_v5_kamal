# Il primo nucleo operativo di 1Impegno

La vista Esperienza ha permesso di validare la prima struttura operativa comune:

```text
DataExperience
├── DataSession
│   ├── DataSlot
│   │   └── DataCommitment
│   └── DataCommitment
├── DataSlot
│   └── DataCommitment
└── DataCommitment
```

La struttura è progressiva: si può iniziare dall’impegno più piccolo e aggiungere in seguito Slot e Session. Gli elementi vengono visualizzati per giorni quando hanno date oppure nei registri Session, Slot e Commitment quando sono ancora da programmare.

La stessa pagina consente:

- vista per giorni o lista tramite parametri URL;
- inserimento contestuale con modali;
- modifica diretta con Hotwire e Stimulus;
- ordinamento manuale per gli elementi senza data;
- date di inizio e fine per Session, Slot e Commitment.

Durante il pilota la modifica resta riservata al superadmin. I permessi degli operatori verranno definiti usando casi reali.
