# Guida Content, corsi e lezioni

## Obiettivo

Usare `Content` come unico sistema editoriale ed eliminare progressivamente `NodeContent`.

Il `Node` descrive identità, gerarchia e posizione nella rete. I testi, i capitoli, i materiali e le
pubblicazioni appartengono invece a `Content`.

## Modello generale

```text
MetroLine
├── Node corso
│   ├── Content mostrato nello show
│   ├── altri Content e materiali
│   └── Node lezione
│       ├── Content mostrato nello show
│       ├── Content capitolo
│       ├── Content capitolo
│       └── altri Content e materiali
└── Node corso successivo
```

La linea contiene Node corso e Node lezione. Non contiene gli ID o gli slug dei capitoli: i capitoli si
caricano dai `Content` assegnati alla lezione e ordinati tramite `position`.

## Contenuto mostrato nello show

Al `Node` va aggiunto:

```text
show_content_id -> contents.id
```

`show_content_id` seleziona esplicitamente il `Content` introduttivo mostrato nello show del corso, della
lezione o della risorsa. È preferibile a scegliere il primo contenuto pubblico, perché l'editor può cambiare
la selezione senza modificare ordine, stato o date dei contenuti.

Vincoli:

- il `Content` selezionato deve appartenere al Node oppure essere collegato esplicitamente al Node;
- se manca `show_content_id`, lo show presenta soltanto titolo, descrizione e contenuti collegati;
- il superadmin può cambiare il contenuto selezionato dall'editor del Node.

## Pubblicazione mostrata nello show

Un `Content` può avere più `ContentPublication`: sito, YouTube, Vimeo, social e altre destinazioni.

Al `Content` va aggiunto:

```text
show_publication_id -> content_publications.id
```

`show_publication_id` indica la pubblicazione incorporata nello show, per esempio il video principale. Non
si deve scegliere automaticamente la prima pubblicazione pubblica.

Vincoli:

- la pubblicazione selezionata deve appartenere allo stesso `Content`;
- per l'embed iniziale sono ammessi `youtube` e `vimeo` con formato `video`;
- il visitatore la vede soltanto se Content e ContentPublication sono accessibili;
- il superadmin la vede anche in bozza, con un badge editoriale;
- il caricamento dell'embed rispetta il consenso privacy già usato dal sito.

Un boolean come `show_in_content` sulla pubblicazione sarebbe possibile, ma richiederebbe un indice parziale
per garantire una sola selezione per Content. Il riferimento `show_publication_id` rende la scelta univoca e
più semplice da aggiornare.

## Più Content nello stesso Node

Il rapporto ordinario è già espresso da:

```text
Content belongs_to Node
Node has_many Content
```

Ogni `Content` deve avere un ruolo editoriale esplicito, per esempio:

- `introduction`: presentazione del corso, della lezione o della risorsa;
- `chapter`: capitolo della lezione;
- `material`: materiale aggiuntivo;
- `attachment`: allegato o scheda.

`position` stabilisce l'ordine tra contenuti dello stesso ruolo. Un campo `placement` può indicare dove
renderizzare un materiale:

- `before_body`;
- `after_body`;
- `after_chapters`.

`show_content_id` resta la scelta esplicita del contenuto principale e non dipende da ruolo o posizione.

## Quando usare ContentLink

`ContentLink` non serve per i Content che appartengono normalmente al Node: in quel caso bastano `node_id`,
ruolo, `placement` e `position`.

Si usa quando lo stesso Content deve comparire anche in un altro Node senza essere duplicato:

```text
Content “Respirazione”
├── appartiene alla Lezione A tramite node_id
└── compare nella Lezione B tramite ContentLink
```

Il legame specifica il significato (`material`, `approfondimento`, `prerequisito`) e `position` stabilisce
l'ordine nel Node che lo riutilizza.

## Markdown e Lexxy nello stesso Content

`Content` deve contenere entrambe le rappresentazioni dello stesso testo:

- `body_md`: versione Markdown, utile per sviluppo, esportazione e versionamento;
- `has_rich_text :body`: versione Lexxy modificabile dall'editor web;
- `body_html`: copia derivata, soltanto se utile per rendering o esportazione.

Servono inoltre metadati di sincronizzazione separati:

- checksum dell'ultimo Markdown sincronizzato;
- checksum dell'ultima versione Lexxy sincronizzata;
- data di modifica Markdown;
- data di modifica Lexxy;
- stato `clean`, `markdown_changed`, `lexxy_changed` oppure `conflict`.

### Modifica da Lexxy

Lexxy salva il corpo, genera il Markdown e aggiorna entrambi i checksum. Lo stato torna `clean`.

### Importazione Markdown

Se Lexxy non è cambiato dopo l'ultima sincronizzazione, il Markdown aggiorna automaticamente anche Lexxy.

### Conflitto

Se Markdown e Lexxy sono cambiati entrambi, nessuna versione viene sovrascritta automaticamente. L'editor
mostra:

1. Markdown importato;
2. versione Lexxy esistente;
3. anteprima o differenze;
4. editor Lexxy per la fusione manuale.

Le azioni disponibili sono:

- usa Markdown;
- usa Lexxy;
- conferma fusione manuale;
- usa la versione più recente, soltanto come scelta esplicita.

Dopo la conferma, il sistema rigenera entrambe le rappresentazioni e aggiorna checksum e date.

## Show del corso

Lo show del Node corso presenta, nell'ordine:

1. titolo e descrizione del Node;
2. `show_content`;
3. eventuale `show_publication` video;
4. materiali collocati prima o dopo il corpo;
5. elenco delle lezioni del corso;
6. navigazione indietro/procedi lungo la linea.

Il titolo del corso nell'aside è cliccabile anche quando il contenuto introduttivo non è ancora presente; in
quel caso lo show presenta la struttura disponibile e un messaggio editoriale al superadmin.

## Show della lezione

Lo show del Node lezione presenta:

1. titolo e `show_content` introduttivo;
2. eventuale `show_publication` video;
3. riga della lezione con data, centro, insegnante e firma;
4. capitoli `Content` ordinati per `position`;
5. materiali aggiuntivi;
6. navigazione indietro/procedi lungo la linea.

L'indice generale mostra invece tutte le lezioni con le colonne complete, senza ripetere i capitoli.

## Aside e MetroLine

L'aside mostra l'intero percorso:

- corso come intestazione cliccabile;
- lezioni del corso come voci cliccabili;
- evidenza sul Node attivo;
- comandi indietro/procedi sotto la lista.

Gli identificatori portabili della linea sono gli slug univoci dei Node. Durante l'importazione gli slug
vengono risolti negli ID locali, usati per la lettura veloce:

```text
station_node_slugs -> dato portabile
station_node_ids   -> riferimenti locali
```

L'esportazione deve sempre ricostruire `station_node_slugs` dagli ID. Non si inseriscono nella linea gli
slug dei capitoli, perché questi derivano dai Content della lezione.

### Catena di risoluzione della linea

La linea non collega direttamente Content o ContentPublication. Ogni stazione viene risolta così:

```text
MetroLine.station_node_slugs
  -> Node locale risolto tramite slug
  -> Node.show_content_id
  -> Content.show_publication_id
  -> ContentPublication eventualmente incorporata nello show
```

In questo modo la linea resta una sequenza di entità strutturali, mentre contenuto principale e video possono
cambiare senza modificare la linea.

### Raggruppamento nell'aside

L'ordine dell'aside è quello di `MetroLine#ordered_nodes`. I Node con `view_type: course` aprono un gruppo; i
Node lezione successivi appartengono a quel corso fino al corso seguente.

- il corso è mostrato come intestazione cliccabile;
- le lezioni sono mostrate sotto il proprio corso;
- i capitoli non compaiono nell'aside;
- corso e lezione attivi hanno stati visivi distinti;
- stazioni non pubbliche sono visibili soltanto al superadmin.

### Indietro e procedi

“Indietro” e “Procedi” usano la posizione del Node attivo in `ordered_nodes`, non l'ordine dei capitoli.

- dallo show del corso, “Procedi” apre la prima lezione successiva;
- dallo show di una lezione, “Procedi” apre la stazione successiva della linea;
- se la stazione successiva è un corso, si apre prima lo show del corso;
- le stazioni non accessibili vengono saltate per il visitatore, ma restano navigabili dal superadmin;
- l'ultima stazione mostra il completamento della linea o il collegamento alla linea successiva.

I capitoli hanno una navigazione interna separata, basata sulla loro `position`, e al termine ritornano allo
show della lezione oppure procedono alla stazione seguente.

## URL e vista unificata

“Percorso online” e “Lezioni” diventano un'unica vista `Percorso`. Il parametro della tappa deve accettare lo
slug di un Node corso o lezione della linea.

```text
/posturacorretta/percorsi/postura-recupero?tappa=<node-slug>
```

`Prenota` può restare una vista separata perché contiene disponibilità, centri e insegnanti. Le vecchie URL
con `tab=online` o `tab=lezioni` devono essere mantenute temporaneamente e reindirizzate alla tappa corretta.

## ContentPublication nella linea e negli show

La linea non possiede direttamente ContentPublication. La pubblicazione mostrata dipende dal Content scelto
dal Node attivo.

Nello show:

- `show_publication` viene incorporata vicino al `show_content`;
- le altre pubblicazioni del Content sono elencate al superadmin;
- pubblicazioni pubbliche aggiuntive possono essere mostrate come materiali consultabili;
- pubblicazioni private o in bozza non entrano nella navigazione pubblica;
- cambiare `show_publication_id` non cambia l'ordine della linea né l'URL del corso o della lezione.

## Dati della lezione

Data, ora, centro, insegnante e firma descrivono una specifica esecuzione della lezione, non il Node lezione.
Non devono essere salvati nel Node o nel Content. Lo show legge l'eventuale sessione/prenotazione collegata;
in sua assenza mostra una sola riga vuota compilabile nella versione stampabile.

La tabella generale mostra tutte le lezioni e le rispettive sessioni. Lo show della lezione mostra la sola
riga della lezione o della sessione selezionata, seguita dai capitoli.

## Visibilità editoriale

Il visitatore vede soltanto Content e ContentPublication pubblicati e accessibili. Il superadmin vede anche:

- bozze;
- contenuti privati;
- materiali non selezionati;
- pubblicazioni alternative;
- stato di sincronizzazione Markdown/Lexxy;
- eventuali conflitti da risolvere.

Nello show riservato al superadmin deve essere possibile scegliere `show_content`, `show_publication`, ruolo,
placement, posizione e visibilità.

## Migrazione da NodeContent

La rimozione di `NodeContent` va eseguita per fasi:

1. aggiungere Lexxy e sincronizzazione a `Content`;
2. aggiungere `show_content_id` al Node e `show_publication_id` al Content;
3. trasformare ogni `NodeContent` in un `Content` associato allo stesso Node;
4. copiare corpo Lexxy, Markdown, HTML e informazioni sulla sorgente;
5. impostare il nuovo Content come `show_content` del Node;
6. modificare editor e show affinché leggano soltanto `Content`;
7. verificare che nessun `NodeContent` resti utilizzato;
8. rimuovere associazione, tabella e campi legacy di `NodeContent`.

La migrazione non deve scegliere automaticamente tra Markdown e Lexxy quando risultano entrambi modificati:
questi record entrano nello stato `conflict` e richiedono conferma editoriale.

## Contratto tecnico da approvare prima della migrazione

Nomi proposti:

- `nodes.show_content_id`;
- `contents.show_publication_id`;
- `contents.role`: `introduction`, `chapter`, `material`, `attachment`;
- `contents.placement`: `before_body`, `after_body`, `after_chapters`;
- `contents.editor`: `markdown`, `lexxy`;
- `contents.sync_status`: `clean`, `markdown_changed`, `lexxy_changed`, `conflict`;
- checksum e date separate per Markdown e Lexxy;
- `has_rich_text :body` su Content.

Vincoli da aggiungere:

- `show_content` valido soltanto se appartiene o è collegato al Node;
- `show_publication` valido soltanto se appartiene al Content;
- slug del Node univoco e usato nell'import/export della linea;
- posizione non negativa;
- ruoli e placement ammessi;
- eliminazione protetta quando un Content o una pubblicazione sono selezionati per uno show.

## Ordine di implementazione

1. Migrazioni e associazioni, senza cambiare le pagine pubbliche.
2. Lexxy su Content e servizi di sincronizzazione/conflitto.
3. Backfill da NodeContent a Content, con report e rollback.
4. Editor Node: scelta di show Content e show publication, elenco di tutti i materiali.
5. Show corso e show lezione.
6. Aside unificato e navigazione indietro/procedi.
7. Unificazione delle tab `online` e `lezioni`, con compatibilità delle vecchie URL.
8. Import/export della linea tramite slug e cache degli ID locali.
9. Verifica dei contenuti migrati e rimozione definitiva di NodeContent.

## Checklist prima di rimuovere NodeContent

- [ ] Tutti i Node con NodeContent hanno uno show Content verificato.
- [ ] Nessun conflitto Markdown/Lexxy è irrisolto.
- [ ] Course show, lesson show e risorse leggono da Content.
- [ ] Gli embed YouTube/Vimeo rispettano visibilità e consenso privacy.
- [ ] Aside e procedi attraversano correttamente tutti i Node della linea.
- [ ] Le vecchie URL hanno redirect o compatibilità esplicita.
- [ ] Esportazione e reimportazione ricostruiscono la linea dagli slug.
- [ ] Superadmin vede bozze e materiali; il pubblico vede soltanto quelli autorizzati.
- [ ] Test e report confermano che nessun testo è stato perso.

## Stato di implementazione

### Fase 1 completata — struttura non distruttiva

- aggiunti `Node#show_content` e `Content#show_publication`;
- aggiunti ruolo, placement, editor, stato e metadati di sincronizzazione a Content;
- aggiunto Lexxy a Content tramite Action Text;
- aggiunti slug portabili e ID locali sincronizzati a MetroLine;
- salvata la linea `postura-recupero` con 45 slug e 45 ID nello stesso ordine.

### Fase 2 avviata — sincronizzazione e pilota

- `ContentEditing::BodySynchronizer` gestisce inizializzazione, Markdown, Lexxy, conflitto e risoluzione;
- nessun conflitto viene risolto automaticamente;
- `ContentEditing::NodeContentBackfill` conserva sempre il vecchio NodeContent;
- pilota Node 314: collegato il Content 99 `introduzione-percorso-integrato-posturacorretta`, senza creare
  duplicati e senza cancellare NodeContent;
- le pagine pubbliche non sono ancora state spostate sul nuovo show Content.

### Fase 3 avviata — editor Content

- il Node editor permette di scegliere `show_content` tra Content propri e collegati;
- mostra ruolo, posizione, stato, visibilità, conflitti e pubblicazione selezionata;
- ogni Content ha un editor dedicato per metadati, Markdown e Lexxy;
- `show_publication` si sceglie esplicitamente tra le pubblicazioni del Content;
- Markdown e Lexxy hanno azioni di salvataggio separate;
- in conflitto compaiono le azioni esplicite “Usa Markdown” e “Usa Lexxy”;
- l'accesso è limitato ai Content appartenenti o collegati al Node amministrato.

### Fase 4 avviata — show pubblico del corso

- la pagina canonica `/posturacorretta/corsi/:corso` legge il Content selezionato dal relativo Node corso;
- senza `Node#show_content` mantiene il rendering precedente come fallback;
- Lexxy ha precedenza nel rendering, con Markdown come fallback;
- `Content#show_publication` seleziona esplicitamente il video;
- sono supportati embed YouTube e Vimeo con consenso privacy;
- Content e pubblicazioni non pubblici sono visibili soltanto in anteprima al superadmin;
- la presentazione viene mostrata tra testata del corso e indice dei capitoli.
