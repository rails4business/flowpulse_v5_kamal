# Flusso dei dati: sviluppo, produzione, DB, YAML e Markdown

Un punto alla volta (⏳ → ✅ solo dopo conferma). Prima si decide tutto, poi si applica. Il modello dei dati resta
quello di `contenuti_pubblicazioni_prompt.md`.

## Decisioni

- **2026-11-23** La produzione è la fonte di verità; gli altri professionisti scrivono solo lì. markpostura può
  scrivere anche in sviluppo. Il codice resta in locale e va online col deploy. I file di oggi (`config/data/`,
  `config/*.yml`) non si cancellano.
- **2026-11-24** Standard dei file in `docs/dati/<username-creator>/`:
  - `nodes.yml`: tutti i node del creator;
  - `nodes/<slug-node>/<key-contenuto>.md`: un file per contenuto, campi nell'intestazione e testo sotto;
    cartelle piatte (il genitore sta in `nodes.yml`); un node senza contenuti non ha cartella;
  - `nodes/<slug-node>/index.md` facoltativo: testo della pagina del node (`node_contents`);
  - solo in `markpostura/` (superadmin, parte generale): `domains.yml` e `places.yml`.
- Il **creator è il titolare del node** e dei suoi contenuti; gli altri al massimo sono coautori.
- Nei file niente `id`: chiavi stabili (`content.key`, `node.slug`, `domain.hostname`, `place.slug`; `parent:` =
  chiave del genitore; coautori = username).
- Si va in tutti e due i versi (DB → file, file → DB). Se un record è cambiato da tutte e due le parti dopo
  l'ultimo allineamento è un **conflitto**: non si sovrascrive, si segnala.

```markdown
---
key: metodica-gds
format: metodica
title: Biomeccanica Comportamentale GDS
position: 1
parent:
coauthors: []
publication_status: published
publication_visibility: public
published_at: 2026-08-30
links_from_nodes: { metodica: [biomeccanica-comportamentale-gds] }
data: { founder: Godelieve Denys-Struyf }
---

# Biomeccanica Comportamentale GDS
```

## Com'è oggi

- `.kamal/hooks/post-deploy` lancia `deploy:sync_catalogs`, che **riscrive** la produzione dai file: node (e toglie
  `removed_slugs`), contenuti, skill e prodotti skill, domini, linee, offerte, mappe. Una modifica fatta in
  produzione si perde al deploy dopo.
- Gli impegni hanno già un loro percorso sviluppo → produzione (`sync_key`, JSON, token, conferma): resta com'è.
- Editor in produzione: node, domini, luoghi, skill, mappe; per i contenuti solo la pubblicazione.
- Backup del 2026-11-23 in `docs/backup/2026-11-23/` (file e dump del DB di sviluppo), fuori da git; la repo
  privata la gestisce l'utente.

## Deciso (2026-11-24) — i file viaggiano col deploy

1. Si scrive in sviluppo (admin o file).
2. `dati:export` in sviluppo scrive in `docs/dati/` i record cambiati.
3. Commit e deploy; l'hook lancia `dati:import` in produzione, che per ogni record confronta file, DB e registro:
   file uguale → niente; cambiato solo il file → applica; cambiati tutti e due → conflitto, segnalato.
4. Si scarica la produzione in sviluppo (dump) per riallinearsi, anche alle modifiche degli altri; i record
   cambiati in produzione (lo dice il registro) si riesportano nei file, così i file restano completi.

Così non serve un endpoint con token: un solo meccanismo (export/import), e l'import al deploy è sicuro.
Per sicurezza il **registro** (punto 3) annota per ogni record da dove arriva l'ultimo cambiamento: dai file col
deploy, oppure scritto in produzione.

## Punti

1. ⏳ **Ultimo deploy con l'import di oggi**, poi in produzione `contents:publish_backlog` e
   `places:import_directory` (prima `DRY_RUN=1`) e la Sede in `/flowpulse/rete/luoghi`. Dopo, l'hook non lancia
   più `deploy:sync_catalogs` (lo sostituisce `dati:import`, se la proposta è confermata).
2. ⏳ **Export e import** di `docs/dati/` secondo lo standard.
3. ⏳ **Registro `sync_entries`** (appuntato: si crea a standard deciso). Una riga per record:
   `record_type` + `record_key`, `file_path`, `origin` (dove è nato: sviluppo/produzione), `last_change_source`
   (ultimo cambiamento: `file` = arrivato col deploy, `produzione` = scritto lì), `checksum` (impronta attuale,
   aggiornata a ogni salvataggio), `synced_checksum` + `synced_at` (ultimo allineamento con i file). Stato:
   allineato, modificato in produzione (da riportare nei file e in sviluppo), nuovo. Dopo, eventualmente, uno
   storico (chi, cosa, quando).
4. ⏳ **Editor dei contenuti** in `/<brand>/admin/contents`: titolo, descrizione, testo, posizione, genitore,
   creazione (nasce in bozza e privato). Legami, coautori e `data` ora o dopo.
5. ⏳ **Scaricare la produzione in locale**: dump caricato nel DB di sviluppo.
6. ⏳ **Backup della produzione**: dump del DB cifrato, l'unico completo (utenti, impegni, calendari non sono nei
   file). Frequenza, posto e numero di copie da decidere.
7. ⏸ **Altri professionisti**: scaricare i propri dati, repository personali per chi lo chiede. Dopo.

## Domande aperte

1. ✅ "I file viaggiano col deploy", con il registro per sicurezza.
2. Tabelle del primo passo (proposta: node, contenuti, domini, luoghi).
3. File non pubblici: cifrati, o in chiaro in una repo privata?
4. Titolare del contenuto: oggi `contents.profile_id` viene dall'autore nel YAML; si allinea alla regola "il
   contenuto è del creator del node"?
