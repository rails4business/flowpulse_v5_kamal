# Dependabot, pull request e credenziali Kamal

Data decisione: 26 settembre 2026.

Procedura operativa aggiornata: 4 novembre 2026.

## Obiettivo

Integrare gradualmente gli aggiornamenti proposti da Dependabot senza
introdurre regressioni e senza perdere la configurazione locale usata da
Kamal per leggere le credenziali cifrate di Rails.

## Stato attuale verificato

- `.kamal/secrets` esiste ed è ignorato da Git.
- `config/master.key` esiste ed è ignorato da Git.
- `.kamal/secrets` non contiene direttamente le credenziali: usa sostituzioni
  di comando per ricavare i valori necessari.
- Le variabili attualmente risolte sono:
  - `KAMAL_REGISTRY_PASSWORD`;
  - `RAILS_MASTER_KEY`;
  - `POSTGRES_PASSWORD`;
  - `DATA_COMMITMENT_SYNC_TOKEN`.
- `config/deploy.yml` dichiara queste variabili come segreti di Kamal.
- Dependabot apre le pull request, ma non deve unirle automaticamente.

## Perché `.kamal/secrets` può scomparire

Un normale `git pull` non elimina un file ignorato. Anche `git stash`, senza
opzioni aggiuntive, non dovrebbe rimuoverlo.

Il file può invece mancare nei seguenti casi:

1. si lavora in un nuovo clone o in una nuova worktree: i file ignorati non
   vengono copiati da Git;
2. si usa `git stash --all` o `git stash -a`: vengono inclusi e rimossi anche
   i file ignorati fino al successivo `git stash pop` o `git stash apply`;
3. si usa `git clean -fdX`: vengono eliminati proprio i file ignorati;
4. una cartella di lavoro viene sostituita, rigenerata o riclonata;
5. uno script locale rimuove `.kamal` o i file ignorati.

La cartella temporanea creata da Kamal per costruire l'immagine è un clone e
non contiene `.kamal/secrets`, ma questo è normale: Kamal deve risolvere i
segreti dalla cartella originale prima di avviare build e deploy.

## Regola per le credenziali

La fonte delle credenziali resta Rails encrypted credentials. Il file
`.kamal/secrets` resta soltanto un ponte locale che esegue i comandi necessari
per leggerle.

Non devono essere versionati:

- `.kamal/secrets`;
- `config/master.key`;
- valori estratti dalle Rails credentials;
- token del registry o password del database.

Si conserva invece nel repository un template privo di valori reali:
`.kamal/secrets.production-template`.

Prima di un deploy deve essere possibile controllare:

- che `.kamal/secrets` esista;
- che `config/master.key` esista;
- che tutte le variabili richieste siano risolvibili;
- che nessun valore venga stampato nei log.

## Regola per Dependabot

Non viene imposto per ora un nuovo limite volontario alle pull request aperte.
Il numero delle PR non autorizza però merge automatici o aggiornamenti in
blocco.

Ogni aggiornamento viene classificato come:

- **patch**: correzione compatibile, da verificare;
- **minor**: nuova funzionalità compatibile, da verificare;
- **major**: possibile modifica incompatibile, da esaminare separatamente.

Le pull request si integrano una alla volta. Dopo ogni merge, le altre PR
devono essere aggiornate sulla nuova `main` prima di essere valutate.

## Integrazione senza `stash` e senza `clean`

Per questo repository non usare `git stash`, `git stash -a`, `git clean` o
comandi equivalenti come preparazione all'integrazione di una pull request.

Il flusso consigliato per le pull request Dependabot è:

1. terminare e verificare il lavoro applicativo corrente;
2. creare il relativo commit soltanto dopo approvazione esplicita;
3. verificare che la working tree principale sia pulita;
4. esaminare una sola pull request Dependabot;
5. attendere che tutti i controlli CI siano verdi;
6. integrare la pull request;
7. aggiornare la copia locale con `git pull --ff-only`;
8. rieseguire i controlli locali pertinenti prima di passare alla PR seguente.

Se non si vuole interrompere un lavoro locale ancora in corso, la pull request
si verifica in una `git worktree` separata. La worktree non riceve i file
ignorati e quindi non deve essere usata per il deploy. Test, lint, analisi di
sicurezza e build possono essere eseguiti lì; `kamal deploy` deve invece essere
eseguito soltanto dalla cartella principale che contiene i file locali delle
credenziali.

Non usare una pull request Dependabot per includere anche modifiche applicative
non correlate.

## Procedura operativa collaudata con clone temporaneo

Questa è la procedura da usare quando la cartella principale contiene lavoro
locale o file di configurazione che non devono essere toccati. La pull request
viene prima scaricata in un clone isolato; nella cartella principale vengono
poi riportate soltanto le modifiche approvate.

### 1. Identificare una sola pull request

Elencare le PR aperte e scegliere un solo aggiornamento:

```bash
gh pr list --repo rails4business/flowpulse_v5_kamal --state open
```

Annotare numero, dipendenza, versione iniziale e versione proposta. Iniziare
preferibilmente da una patch o da un minor circoscritto. Major e aggiornamenti
di database, code, browser o deploy richiedono una verifica dedicata.

### 2. Creare un clone temporaneo isolato

Creare una directory univoca fuori dal progetto principale e clonare il
repository:

```bash
review_dir=$(mktemp -d /private/tmp/flowpulse-prNUMERO.XXXXXX)
git clone https://github.com/rails4business/flowpulse_v5_kamal.git "$review_dir"
cd "$review_dir"
gh pr checkout NUMERO --repo rails4business/flowpulse_v5_kamal
```

Il clone non contiene `.kamal/secrets`, `config/master.key`, `.env` o altri
file ignorati. Non copiarvi le credenziali e non usarlo per il deploy.

La directory temporanea non viene cancellata automaticamente. La sua eventuale
rimozione avviene soltanto dopo aver verificato l'integrazione e con un comando
esplicito rivolto al percorso esatto creato da `mktemp`.

### 3. Analizzare la PR nel clone

Controllare il diff e lo stato dei job GitHub:

```bash
git diff --stat origin/main...HEAD
git diff origin/main...HEAD
gh pr checks NUMERO --repo rails4business/flowpulse_v5_kamal
```

Verificare in particolare:

- che la PR modifichi soltanto i file attesi;
- che non introduca credenziali, migration inattese o modifiche applicative;
- che checksum e piattaforme del lockfile siano completi;
- che eventuali fallimenti CI dipendano realmente dalla PR e non da una base
  ormai superata.

### 4. Implementare selettivamente nella cartella principale

Tornare nel progetto reale e riportare soltanto le modifiche approvate. Non
eseguire `git pull`, `checkout`, `reset`, `stash`, `clean` o copie integrali
della directory per applicare la PR.

Prima di modificare un file, confrontarlo con la versione corrente: il progetto
principale può contenere cambiamenti più recenti rispetto alla base della PR.
Se la PR modifica un lockfile, i valori devono coincidere esattamente con il
diff isolato; non trascrivere checksum o versioni senza un confronto finale.

### 5. Installare localmente le dipendenze aggiornate

Dopo una modifica a `Gemfile.lock`, installare la nuova versione prima di
eseguire Rails o Kamal:

```bash
bundle install
bundle check
```

Questo passaggio è obbligatorio anche quando la PR modifica soltanto il
lockfile. `bin/kamal` carica il bundle locale prima del deploy: se la nuova gem
non è installata, il deploy può concludere con `Bundler::GemNotFound` e il hook
`post-deploy` fallisce.

Per verificare che Kamal possa essere caricato senza avviare un deploy:

```bash
bin/kamal version
```

Non usare `thrust --version` per verificare Thruster: il comando può avviare il
proxy e tentare di occupare la porta HTTP. Per controllare la gem usare invece:

```bash
bundle info thruster
```

### 6. Verificare il progetto reale

Eseguire almeno:

```bash
bundle check
git diff --check
RUBOCOP_CACHE_ROOT=tmp/rubocop bin/rubocop --format simple
RAILS_ENV=test PARALLEL_WORKERS=1 bin/rails db:test:prepare test
RAILS_ENV=test PARALLEL_WORKERS=1 bin/rails test:system
bundle exec brakeman --no-pager
```

Quando la dipendenza interessa asset, browser, database, container o deploy,
aggiungere i controlli specifici pertinenti. Un aggiornamento non è pronto se
uno dei controlli termina senza un risultato interpretabile.

### 7. Commit e deploy manuali

Prima del commit controllare che siano inclusi soltanto i file previsti:

```bash
git status --short
git diff --stat
```

Il proprietario esegue personalmente commit, push e deploy. Prima del deploy:

```bash
bundle check
bin/kamal version
```

Il deploy deve partire dalla cartella principale, dove sono presenti le
credenziali locali ignorate da Git, e non dal clone temporaneo.

### 8. Concludere la pull request

Dopo il push su `main`, Dependabot può riconoscere che la versione richiesta è
già presente e chiudere automaticamente la PR. Se resta aperta, chiuderla
manualmente specificando che l'aggiornamento è stato integrato e verificato
nel progetto principale.

Non passare alla PR successiva prima di aver verificato CI e deploy della PR
corrente. Dopo ogni integrazione rivalutare le PR rimanenti sulla nuova base.

Il hook locale mostra soltanto un promemoria quando il proprietario esegue un
push diretto verso `main` o `master`: non blocca il push. La richiesta di una
pull request resta obbligatoria come regola di lavoro per Dependabot e per i
file critici, senza impedire il normale flusso applicativo del proprietario.

## Verifiche prima di integrare una PR

1. leggere changelog e note della dipendenza;
2. controllare quali file sono cambiati;
3. eseguire i controlli CI pertinenti:
   - `scan_ruby`;
   - `scan_js`;
   - `lint`;
   - `test`;
   - `system-test`;
4. eseguire `bin/rails zeitwerk:check`;
5. verificare la compilazione degli asset;
6. verificare la build Docker;
7. provare manualmente le funzioni coinvolte quando l'aggiornamento tocca
   runtime, deploy, browser o database;
8. unire la PR solo quando i controlli sono verdi.

## Ordine iniziale delle pull request già aperte

1. patch applicative semplici: Puma, Thruster, SQLite, Bootsnap, Brakeman e
   Jbuilder;
2. Kamal e Selenium, con verifica specifica di deploy e system test;
3. aggiornamenti major, ciascuno come lavoro separato:
   - Solid Cable 4;
   - Image Processing 2;
   - major delle GitHub Actions.

Non chiudere né unire automaticamente le PR già aperte.

## Passi di implementazione

Procedere uno alla volta e verificare ogni passo prima del successivo:

1. aggiungere un controllo locale non distruttivo per i prerequisiti Kamal;
2. correggere e semplificare `CONTRIBUTING.md`;
3. restringere `CODEOWNERS` ai file realmente critici;
4. decidere se installare un vero hook `scripts/pre-push` oppure affidarsi
   soltanto alle regole protette di GitHub;
5. creare un comando unico `bin/ci-local` coerente con la CI;
6. rivedere `.github/dependabot.yml` senza auto-merge e senza raggruppare
   aggiornamenti rischiosi;
7. esaminare e integrare una PR Dependabot alla volta.

## Primo passo approvabile

Il primo intervento consigliato è un comando di sola verifica, senza valori
segreti e senza modificare il deploy. Dovrà terminare con un errore leggibile
se manca il file ponte o se una variabile non può essere risolta, evitando di
scoprire il problema soltanto durante `kamal deploy`.
