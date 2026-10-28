# Rete dei Node FlowPulse

## Decisione

La rete FlowPulse deve rappresentare i `Node` reali senza introdurre un secondo modello di rete.

- FlowPulse è il mondo contenitore dell'ecosistema: nella vista globale compare come radice visiva, anche se la proprietà e la responsabilità dei singoli Node continuano a essere determinate dalla loro struttura reale.
- `parent` mantiene la struttura gerarchica e proprietaria.
- Un Node ponte usa `link_node` per collegare un ramo a un Node già esistente. Più Node ponte possono quindi rendere lo stesso Node raggiungibile da contesti differenti.
- Le catene di montaggio rimangono una struttura distinta e non vengono sostituite da `NodeProcess`.
- I domini sono porte di ingresso associate ai Node, non elementi separati della progressione.

## Brand, Professional e Project Node

La rete globale ha due viste, senza una terza tab "Tutti":

- **Brand**: Node progetto con dominio e relativi Project Node;
- **Professional**: Node professionali, Project Node personali e Brand dei quali il Professional è responsabile.

Un Node senza dominio è un Project Node e deve appartenere a un Brand, a un Professional Brand oppure all'area di incubazione `generaimpresa / brand-in-costruzione`. Quando acquisisce un dominio viene presentato come Brand oppure Professional Brand in base al suo `node_type`.

`professional_owner_node_id` indica il Professional responsabile principale. Altri professionisti, responsabili, creator e aiutanti vengono autorizzati con `RoleAssignment` contestuali. I Node ponte con `link_node` rendono il medesimo Brand raggiungibile da più rami, ma non assegnano proprietà o permessi. Un eventuale ponte proposto da un altro Professional dovrà quindi essere confermato da un ruolo valido sul Node di destinazione.

## Sincronizzazione YAML e database

Per ora `config/nodes.yml` è autorevole soltanto sul database di sviluppo. Il comando `bin/rails nodes:sync_development` importa il catalogo e rimuove dal database locale i Node assenti dallo YAML. Il comando rifiuta di essere eseguito fuori dall'ambiente development e `NodeCatalog` vieta esplicitamente il pruning in produzione.

Il deploy continua a importare e aggiornare Node e domini senza eliminare record dalla produzione. L'allineamento inverso da produzione verso `config/nodes.yml` e `config/domains.yml` deve essere valutato separatamente prima di modificare i cataloghi versionati.

## Viste previste

### Show del Node

Lo show presenta identità, contenuto, domini e accesso alla vista della rete centrata sul Node.

### Rete globale FlowPulse

La rete globale mostra tutti i Node pubblicati, i rapporti padre/figlio, i ponti `link_node` e i domini associati. Può partire da un Node specifico e mettere in evidenza ciò che viene prima, ciò che viene dopo e i collegamenti diretti.

Percorso iniziale:

```text
/flowpulse/rete/globale
/flowpulse/rete/globale?node=posturacorretta
```

### Rete personale del profilo

La rete personale non coincide con la rete globale. Mostra soltanto i Node attivati o disponibili per una persona e dovrà essere collocata sotto il profilo.

Forma prevista:

```text
/profile/rete
```

Se in futuro sarà necessario consultare una rete diversa dalla propria, con autorizzazione esplicita, si potrà introdurre una rotta con identificativo del profilo. Per la propria rete è preferibile non esporre l’id nell’URL.

## Prima implementazione

La prima implementazione usa Cytoscape e contiene esclusivamente:

- Node reali e pubblicati;
- relazione padre/figlio;
- ponti verso `link_node`;
- domini associati;
- selezione e ricentratura su un Node;
- pannello descrittivo del Node selezionato.

Non comprende ancora:

- catene di montaggio;
- avanzamento personale;
- regole di sblocco;
- corsi, capitoli o lezioni rappresentati come stazioni;
- modifica della rete dall’interfaccia.

## Stato di Salute

`statodisalute` dovrà essere aggiunto come Node progetto autonomo collegato al dominio `statodisalute.it`. La configurazione applicativa può essere preparata prima della pubblicazione; DNS, certificato e host del proxy devono essere attivati soltanto quando il dominio è pronto a entrare in produzione.
