# Produzione come fonte unica

Piano da verificare **un punto alla volta**: ogni punto passa da ⏳ a ✅ solo dopo la conferma.
Segue il piano dei contenuti (`contenuti_pubblicazioni_prompt.md`), che resta valido per il modello dei dati.

## Decisioni (2026-11-23)

- **Si scrive tutto in produzione**: contenuti, node, domini, luoghi, mappe, skill. Vale anche per markpostura.
- **Lo sviluppo è una copia della produzione**, scaricata quando serve. Non si sincronizza nei due sensi.
- **In locale resta il codice** (pagine, campi, migrazioni, tipi nuovi), che va online con il deploy.
- **I file YAML e Markdown non sono più la fonte**: diventano una copia esportata dal DB (punto 3). Quelli che
  esistono oggi non si cancellano.
- **Gli altri professionisti** (scaricare i propri dati come creator o professionisti, repository personali)
  si vedono dopo.

## Com'è oggi

`.kamal/hooks/post-deploy` lancia `bin/rails deploy:sync_catalogs OWNER=markpostura` dopo ogni deploy. Il
comando riscrive in produzione, dai file:
- node (`config/nodes.yml`, `NodeCatalog`), e alla fine toglie i node di `removed_slugs`;
- contenuti (`config/data/brands/*/`, `ContentCatalog`) e collegamento degli impegni (solo storia);
- skill e prodotti skill di `OWNER` (`ReusableSkillSnapshot`, `SkillProductSnapshot`);
- domini (`Domain.import_from_config!`);
- linee, offerte e mappe (`LineOfferCatalog`, `MetroMapCatalog`).

Quindi una modifica fatta in produzione su questi dati si perde al deploy successivo, se il file dice altro.

Gli impegni (`data_commitments`) hanno già un loro percorso da sviluppo a produzione (`sync_key`, esportazione
JSON, `data_commitments:push_pending_imports`, conferma dell'admin): resta com'è.

Editor già presenti in produzione: node (`/admin/nodes`, `/<brand>/admin/nodes`), domini (`/admin/domains`),
luoghi (`/flowpulse/rete/luoghi`), skill, mappe. Per i contenuti c'è solo la pubblicazione
(`/<brand>/admin/contents`).

## Punto 1 — Il deploy non sovrascrive più ⏳

- Prima un ultimo deploy con l'import, così la produzione parte allineata ai file di oggi (metodiche, schede,
  node tolti, articoli).
- Poi l'hook `post-deploy` non lancia più `deploy:sync_catalogs`. **Deciso**: non serve più nessun import dai
  file, nemmeno a mano. Se un cambiamento di codice ha bisogno di un dato nuovo (es. un node per una pagina
  nuova), si crea dall'admin in produzione dopo il deploy, oppure con una migrazione di dati una tantum.
- Gli importer (`NodeCatalog`, `ContentCatalog`, …) restano nel codice per ora (li usano i test); si decide dopo
  se toglierli.

## Punto 2 — Editor dei contenuti nell'admin del brand ⏳

- Dalla tabella di `/<brand>/admin/contents`: modifica di titolo, descrizione, testo Markdown, posizione,
  genitore; creazione di un contenuto nuovo (nasce in bozza e privato).
- Da decidere: legami, autori e campi dei dati (`data`) in questo punto o dopo.

## Punto 3 — Scaricare la produzione in locale ⏳

- Un comando che fa il dump della produzione e lo carica nel DB di sviluppo.
- Lo stesso comando (o uno accanto) esporta dal DB i file YAML e Markdown: **pubblici in chiaro** (nel repo),
  **non pubblici cifrati** (in locale o in una repo privata).
- Da decidere: dove vanno i file esportati rispetto a quelli di oggi; chiave di cifratura (proposta: una
  chiave nelle credentials di Rails).

## Punto 4 — Backup della produzione ⏳

- Il backup vero è il **dump del DB cifrato**: è l'unico completo (utenti, impegni, calendari e richieste non
  stanno nei file). I file del punto 3 sono una copia leggibile in più, non il backup.
- Da decidere: ogni quanto, dove si tiene (locale, repo privata, altro) e quante copie.

## Punto 5 — Dati degli altri professionisti ⏸

- Ognuno scarica i propri dati come creator o professionista; repository personali solo per chi lo chiede.
- Rimandato: si riprende dopo i punti 1–4.
