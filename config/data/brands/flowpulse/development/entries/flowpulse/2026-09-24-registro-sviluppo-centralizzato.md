# Registro di sviluppo centralizzato

## Problema

Le decisioni prese prima di programmare non devono essere confuse con il changelog, che racconta ciò che è già stato completato. Allo stesso tempo, distribuire piani tecnici nei singoli Brand rende difficile seguire lo sviluppo complessivo della piattaforma.

## Obiettivo minimo

Flowpulse conserva un registro interno delle schede di implementazione, organizzato per Brand responsabile e visibile soltanto al superadmin.

Ogni scheda indica:

- problema e obiettivo;
- Brand responsabile;
- stato di avanzamento;
- confini della modifica;
- model, interfacce e migrazioni coinvolti;
- verifiche e procedura di distribuzione;
- eventuale collegamento al changelog finale.

## Compreso in questa implementazione

- indice YAML unico;
- un Markdown separato per ogni scheda;
- raggruppamento e filtro per Brand;
- filtro per stato;
- vista di dettaglio Markdown;
- accesso esclusivo superadmin;
- collegamento nel menu Flowpulse visibile soltanto al superadmin.

## Escluso

- modifica delle schede dal browser;
- creazione automatica di commit;
- pubblicazione dei piani nei changelog dei Brand;
- gestione di ticket o assegnazione del lavoro.

## Flusso concordato

```text
Scheda Flowpulse
→ approvazione
→ sviluppo
→ test
→ changelog del Brand
→ autorizzazione esplicita al commit
→ deploy
→ verifica in produzione
```

## Verifica

- il superadmin vede indice e dettaglio;
- un utente non autorizzato non può accedere;
- i filtri conservano soltanto le schede richieste;
- YAML e sorgenti Markdown restano confinati nella cartella di sviluppo Flowpulse.
