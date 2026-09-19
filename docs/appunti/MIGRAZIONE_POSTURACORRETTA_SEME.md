# Migrazione PosturaCorretta Seme → PosturaCorretta

## Obiettivo

Eliminare **Seme** come nome e percorso pubblico, senza eliminare contenuti,
programmi, lezioni o pagine ancora utilizzate da PosturaCorretta.

`PosturacorrettaSemeController` non identifica più un prodotto autonomo: è il
contenitore tecnico storico da cui oggi vengono ancora rese alcune pagine del
percorso PosturaCorretta.

## Regola di sicurezza

Prima si sposta o rinomina una pagina, poi si verificano le rotte e i test.
I file in `config/data/posturacorretta/` sono la fonte didattica da conservare;
non si cancella alcun file YAML o Markdown in questa migrazione.

## Fonti da conservare

| Ambito | Fonte |
| --- | --- |
| Indice guida storico | `config/data/posturacorretta/guide/indice.yml` |
| Percorso e Section | `config/data/posturacorretta/contenuti/percorso.yml` |
| Indici dei corsi | `config/data/posturacorretta/accademia/posturacorretta_percorso.yml` |
| Programma guidato | `config/data/posturacorretta/accademia/posturacorretta_percorso_guidato.yml` |
| Programma lezioni | `config/data/posturacorretta/programmi/programma_lezioni_posturacorretta.yml` |
| Calendario gruppi | `config/data/posturacorretta/programmi/calendario_lezioni_gruppo.yml` |
| Schede pratiche | `config/data/posturacorretta/accademia/schede_pratiche/` |
| Catalogo contenuti | `config/data/posturacorretta/contenuti/contents.yml` |
| Presentazione PDF | `docs/handouts/Presentazione PosturaCorretta.pdf` |

## Mappa delle rotte

| URL attuale | Stato | Destino nella migrazione |
| --- | --- | --- |
| `posturacorretta.org/` e `/posturacorretta` | attivo | home PosturaCorretta; cambiare solo il controller tecnico in un secondo momento |
| `/posturacorretta/seme` | già redirect alla home | mantenere il redirect 301, poi togliere la rotta nominata `seme` quando non più necessaria |
| `/posturacorretta/seme/percorso` | già redirect alla home | mantenere il redirect 301 |
| `/posturacorretta/seme/percorsi-integrati` | redirect 301 | la pagina duplicava le prime lezioni PosturaCorretta; le fonti sono già conservate nei YAML di percorso e corsi |
| `/posturacorretta/corsi/:corso` | attivo | mantenere: è l’indice di un corso |
| `/posturacorretta/corsi/:corso/capitoli/:capitolo` | attivo | mantenere: è lo show di un capitolo |
| `/posturacorretta/corsi/postura-corretta-in-un-mese` | già redirect | mantenere verso il libro `Il corpo, un mondo da scoprire` |
| `/posturacorretta/lezioni` | attivo | mantenere; è il programma lezioni attuale |
| `/posturacorretta/lezioni/appuntamenti` | attivo e autenticato | mantenere; spostare dopo l’implementazione di DataSession/DataSlot |
| `/posturacorretta/seme/dashboard/studente` | redirect 301 | alias storico verso `/posturacorretta/lezioni` |
| `/posturacorretta/seme/dashboard/insegnante` | strumento interno | spostare a un URL senza `seme`, dopo revisione dell’area insegnanti |
| `/posturacorretta/profilo` | attivo e autenticato | già migrato al controller moderno |
| `/posturacorretta/presentazione-posturacorretta` | attivo | già migrato al controller moderno |
| `/posturacorretta/programma` e `/posturacorretta/percorso-educativo` | compatibilità | mantenere come redirect finché esistono link esterni |

## Ordine di lavoro

1. **Pulizia pubblica immediata**
   - nessun link interno deve più usare `/posturacorretta/seme`;
   - lasciare i redirect 301 per gli URL storici;
   - togliere la voce tecnica “Dashboard insegnante” dall’esplora pubblica,
     lasciandola solo negli strumenti interni/superadmin.

2. **Separare ciò che è già definitivo**
   - home, corsi, capitoli, lezioni, centri e insegnanti restano
     PosturaCorretta;
   - il libro resta nella sezione libri;
   - il programma lezioni continua a leggere il proprio YAML dedicato.

3. **Migrare il nome tecnico senza cambiare comportamento**
   - completato il primo confine: le rotte didattiche attive usano
     `Posturacorretta::LearningController`;
   - completato lo spostamento delle viste in
     `app/views/posturacorretta/learning/`; la cartella di viste `seme` è vuota;
   - completato lo spostamento della logica didattica nel controller Learning;
     gli URL storici `/seme` restano soltanto come nomi di route e redirect;
   - cambiare una rotta/pagina alla volta e verificare i test.
   - i nomi in conflitto, come `percorso`, richiedono una migrazione tramite
     concern o rinomina esplicita: non vanno uniti in modo automatico.

4. **Chiudere Seme**
   - quando nessuna rotta attiva usa più controller o viste `seme`, rinominare
     i test e rimuovere i file tecnici residui;
   - conservare per un periodo solo gli URL 301 indispensabili.

## Non fa parte di questa migrazione

- modello database `DataSession → DataSlot → DataCommitment`;
- servizi, cicli, prenotazioni e pagamenti;
- contenuti editoriali dinamici.

Questi aspetti restano disciplinati da
`docs/appunti/ARCHITETTURA_CICLI_CONTENUTI_E_SERVIZI.md`.
