# Siti editoriali

Questa cartella contiene le configurazioni editoriali dei siti costruiti con
Page Builder e componenti YAML.

## Convenzione del nome

```text
<node_slug>_<locale>
```

Il suffisso rappresenta la lingua o variante editoriale, non l'estensione del
dominio. Di conseguenza il sito italiano pubblicato su `posturacorretta.org`
usa la cartella:

```text
posturacorretta_it
```

Alias e redirect, come `www.posturacorretta.org`, non hanno una cartella
separata. Una nuova cartella è necessaria soltanto per una versione editoriale
realmente diversa.

## Struttura prevista

```text
<node_slug>_<locale>/
├── site.yml
├── mounts.yml
├── pages/
├── tracks/
├── documents/
└── shared/
```

`mounts.yml` è l'unica fonte degli indirizzi delle pagine editoriali del
Site. I domini e i loro alias restano definiti in `config/domains.yml`.

I file in `documents/` e le fonti in `tracks/` e `shared/` vengono richiamati
tramite chiavi locali al Site, mai tramite percorsi liberi del filesystem.

## PWA per dominio

La sezione opzionale `site.pwa` di `site.yml` abilita manifest, service worker
e pagina offline per il Site. La stessa infrastruttura viene servita su ogni
dominio, ma configurazione, icona, colori, scope e cache restano separati.
In locale `local_prefix` identifica il prefisso del Site; sul dominio dedicato
lo scope diventa `/`. Se `enabled` non è `true`, il sito resta un normale sito
web e gli endpoint PWA rispondono `404`.

Le pagine personali non devono entrare nella cache: vanno elencate in
`excluded_paths`. Il service worker condiviso salva soltanto la pagina offline,
l'icona e gli asset pubblici; le navigazioni HTML non vengono conservate.

Non spostare qui cataloghi Content, eventi, settimane, Accademia o dati
operativi. Queste fonti potranno essere incorporate in futuro attraverso
componenti e sorgenti registrate.

La fonte completa delle decisioni è
`docs/appunti/ARCHITETTURA_PAGINE_STATICHE_YML_E_COMPONENTI.md`.
## Testi Markdown

I campi testuali dei componenti supportano Markdown sicuro. Per testi articolati usare
un blocco YAML, così il file resta leggibile:

```yml
body: |-
  Un concetto **importante** e una parola *in evidenza*.

  - primo punto
  - secondo punto
```

Sono supportati grassetto, corsivo, link, paragrafi ed elenchi. L'HTML inserito
direttamente nel testo viene filtrato.
