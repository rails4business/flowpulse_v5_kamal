# Rails4Business — Skill e prodotti

> Appunto operativo interno. Consultabile nell'area superadmin; non è un
> contenuto pubblico di Rails4Business.

## Distinzione essenziale

```text
ProblemSolvingCycle → segue un problema concreto
ReusableSkill       → definisce una capacità riutilizzabile
ReusableSkillNode   → attiva la Skill su un Node
SkillProduct        → è il risultato prodotto da quell'attivazione
```

Problem Solving e Skill rimangono separati. Un problema può utilizzare una o
più Skill, ma non diventa una Skill. Una Skill è simile a un plugin: descrive
regole e funzionamento comuni, mentre materiali e dati appartengono al Node che
la utilizza.

## Stato implementato

- catalogo YAML delle Skill in `config/data/rails4b/skills.yml`;
- dipendenze esplicite fra Skill;
- attivazioni sui Node con stato `draft`, `active` o `suspended`;
- `SkillProduct` con Markdown in `body` e metadata in `data` JSONB;
- `source_path` facoltativo, relativo e limitato a `config/data/`;
- relazioni fra prodotti attraverso `SkillProductLink`;
- import, export, validazione e dump di Skill e prodotti;
- import automatico durante il deploy quando il catalogo dei prodotti esiste.
- proiezione anonima condivisa fra pagina HTML, sitemap, JSON-LD, `llms.txt` e
  API `/api/v1/resources`;
- esclusione automatica delle risorse in bozza, private, in abbonamento o in
  acquisto e delle risorse collegate a Skill, attivazioni o Node non pubblici.

## Sincronizzazione

Il database è la copia operativa. La repository conserva la copia versionata.
Gli import fanno upsert e non cancellano i record assenti dallo YAML.

```sh
bin/rails skills:validate OWNER=markpostura
bin/rails skills:import OWNER=markpostura
bin/rails skills:export OWNER=markpostura
bin/rails skills:dump OWNER=markpostura

bin/rails skill_products:validate OWNER=markpostura
bin/rails skill_products:import OWNER=markpostura
bin/rails skill_products:export OWNER=markpostura
bin/rails skill_products:dump OWNER=markpostura
```

Il dump dei prodotti include anche il Markdown. L'export lo separa nuovamente
nel file indicato da `source_path`.

## Attività rinviate e non bloccanti

### Primo contenuto reale

La prima prova userà in seguito:

```text
config/data/brands/posturacorretta/courses/inizia-con-posturacorretta/chapters/incontro-salute-metodiche.md
```

Verrà creato un solo prodotto `course_chapter` sul Node responsabile del
percorso online, verificando import, export e pagina pubblica prima di migrare
altri Markdown.

### Pannello delle attivazioni

È rinviata anche l'interfaccia completa di `ReusableSkillNode`: configurazione
JSON, responsabile, modifica dello stato e pagina amministrativa dedicata. La
selezione attuale del Node crea un'attivazione in bozza ed è sufficiente per la
fase corrente.

## Regola per continuare

La standardizzazione delle Skill rimane un'attività aperta e progressiva. Non
blocca il lavoro su Domain, Node, API e discovery pubblica. Una nuova risorsa
delle Skill viene resa pubblica soltanto dopo avere definito stato, visibilità,
autorizzazioni e proiezione anonima. Il contratto generico ora esiste; ogni
nuovo tipo di Skill dovrà aggiungere il proprio renderer e i propri metadata
pubblici senza aggirare `PublicDiscovery::AccessPolicy`.

La fonte architetturale completa resta
`docs/appunti/ARCHITETTURA_BRAND_NODE_DOMAIN_SITE.md`.
