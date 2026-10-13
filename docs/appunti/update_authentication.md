# Autenticazione FlowPulse: User, BrandAccess e Session

## Decisione corrente

L’identità è globale, l’autorizzazione appartiene al Brand e la sessione attiva
è collegata direttamente al relativo `BrandAccess`.

```text
User globale
└── Profile
    └── BrandAccess
        └── Session
```

`DomainAccess` è stato eliminato: hostname e lingua non costituiscono
autorizzazioni personali.

## Responsabilità

- `User`: email, password e stato di verifica dell’identità globale.
- `Profile`: dati della persona condivisi nell’ecosistema.
- `BrandAccess`: autorizzazione della persona a un Brand/Node.
- `Session`: autenticazione attiva, associata a `User` e `BrandAccess`.
- `Domain`: indirizzo tecnico del Brand, canonical e redirect.
- `Site`: presentazione editoriale e variante linguistica.

La `Session` può non avere `brand_access_id` soltanto negli spazi globali di
FlowPulse. Su un dominio di Brand deve corrispondere al Node del dominio:

```text
Session.user == BrandAccess.profile.user
Domain.node == BrandAccess.brand_node
```

Se una condizione non coincide, la sessione viene revocata.

## Registrazione

```text
richiesta pubblica
→ approvazione del responsabile del Brand
→ link d'invito consegnato manualmente
→ email + password
→ User active tramite invito
→ BrandAccess
→ Session
```

Per l'MVP la registrazione libera è chiusa. Il token dell'invito è monouso,
scade dopo sette giorni e autorizza l'accesso al Brand, ma non rappresenta una
verifica tecnica della proprietà dell'indirizzo email. `email_verified_at`
resta quindi vuoto finché non verrà attivato un provider email.

## Inviti

`BrandInvitation` contiene email, Brand/Node, autore dell’invito, eventuale
ruolo e scadenza. Il responsabile copia il collegamento e lo consegna
personalmente. Se la persona è nuova crea `User`, `Profile`, `BrandAccess` e
`Session`; se possiede già un account vengono creati soltanto l'accesso al
nuovo Brand e la relativa Session.

## Login successivo

```text
email + password globale
→ User attivo
→ controllo del BrandAccess del dominio aperto
→ nuova Session del Brand
```

La password appartiene allo User, mai al dominio. Uno User privo di
`BrandAccess` e di un invito valido viene indirizzato al modulo di richiesta.
Uno User sospeso non può creare Session.

## Richiesta di invito

Il modulo pubblico crea un `Contact` e un `DataCommitment` non calendarizzato:

```text
status: requested
blocks_calendar: false
request_kind: access_invitation
subject: Node del Brand
domain: dominio dal quale arriva la richiesta
```

Il responsabile lo vede tra le richieste aperte, approva e genera una
`BrandInvitation`. Il link viene mostrato una sola volta per essere copiato.
Rigenerarlo revoca l'invito precedente. Quando l'invito viene accettato, la
richiesta collegata viene chiusa come `completed`.

## Domain e Site

Ogni Brand/Node può avere molti record `Domain`, ma un solo dominio canonico
con `primary: true`. Gli altri sono alias e reindirizzano al principale.

Le lingue appartengono ai Site:

```text
brand.example/it/
brand.example/en/
```

Cambiare lingua non crea un accesso né una sessione. Le cartelle editoriali
seguono la convenzione `<node_slug>_<locale>` e possono essere dichiarate nella
mappa `sites` del dominio principale.

## Servizi condivisi tra Brand

1Impegno, Rails4Business e le future Skill possono fornire funzioni a un altro
Brand senza diventare il suo perimetro di autenticazione.

Esempio: quando PosturaCorretta apre l'agenda o crea un `DataCommitment`, il
codice operativo appartiene a 1Impegno, ma richiesta, Session e autorizzazione
restano nel contesto di `posturacorretta.org`:

```text
PosturaCorretta (BrandAccess + Session)
└── usa la funzione 1Impegno
    └── DataCommitment riferito a PosturaCorretta
```

Non deve essere richiesto un secondo `BrandAccess` a 1Impegno. La visita
autonoma a `/impegno` resta invece il prodotto pubblico di `1impegno.it` e usa
il proprio accesso. La stessa separazione dovrà valere per ogni Skill: il Node
che usa la funzione stabilisce accesso e visibilità; la Skill stabilisce il
processo e il tipo di prodotto creato.

### Implementazione 1Impegno come Skill

La definizione `1impegno` vive nel catalogo versionato di Rails4Business ed è
collegata ai Brand attraverso `ReusableSkillNode`:

```text
ReusableSkill: 1impegno
└── ReusableSkillNode: PosturaCorretta (active)
    └── DataCommitment
```

- il pannello amministrativo del Node permette di attivare o sospendere la
  Skill;
- un nuovo `DataCommitment` conserva `reusable_skill_node_id`, quindi è
  possibile risalire alla funzione e al Node che lo hanno prodotto;
- gli impegni storici mantengono il collegamento facoltativo;
- quando il catalogo contiene `1impegno`, un Node privo di attivazione attiva
  non può aprire l'agenda né creare nuovi impegni;
- il catalogo iniziale attiva la Skill sui Node `impegno` e
  `posturacorretta`.

Nel deploy `deploy:sync_catalogs` importa prima i Node e subito dopo le Skill:
le attivazioni dichiarate in `config/data/rails4b/skills.yml` vengono quindi
ricreate anche in produzione senza inserimenti manuali.

## Logout e revoca

- logout: revoca la Session corrente;
- cancellazione del BrandAccess: revoca tutte le Session collegate;
- cambio password: revoca tutte le Session dello User.

## Passi successivi

- la radice linguistica (`/it`, `/en`) è disponibile solo per i Site dichiarati
  nella mappa `sites`; resta da estendere il prefisso alle pagine editoriali
  interne quando verrà aggiunta una seconda lingua reale;
- valutare più avanti se alcuni Brand debbano usare modalità diverse
  dall'approvazione manuale e dall'invito;
- valutare in futuro un’autenticazione centrale FlowPulse per passare fra Brand
  differenti senza reinserire la password.

## Ordine operativo prima della UX superadmin

1. Completare la baseline automatizzata PageSpeed dei domini pubblici e
   correggere prima i problemi condivisi di layout, componenti e asset.
2. Provare il percorso manuale su un solo Brand pilota:
   richiesta, approvazione, invito, registrazione, `BrandAccess`, Session,
   logout e revoca.
3. Configurare Resend soltanto quando servirà automatizzare la verifica email.
4. Provare invito, accesso negato, token scaduto e tentativo di usare una
   Session su un Brand differente.
5. Ripetere lo stesso contratto sui domini con autenticazione attiva.
6. Soltanto dopo costruire l'interfaccia superadmin per domini, accessi,
   inviti, stato email e diagnostica delle Session.

PageSpeed e autenticazione restano verifiche distinte. Resend non è un
prerequisito del percorso manuale solo su invito.

## Identità globale e verifica per Brand

L'indirizzo email identifica uno `User` globale. Nell'MVP viene registrato
attraverso un invito consegnato personalmente ma non è ancora verificato da un
provider. Entrare in un altro dominio non crea un secondo User: crea o
conferma un `BrandAccess` distinto per il Node/Brand di quel dominio.

La comunicazione deve comunque partire con l'identità del dominio dal quale
è stata richiesta:

- PosturaCorretta usa `PosturaCorretta <accesso@posturacorretta.org>`;
- Canta che ti passa usa `Canta che ti passa <accesso@cantachetipassa.it>`;
- 1Impegno usa `1Impegno <accesso@1impegno.it>`;
- FlowPulse è il mittente di fallback soltanto quando manca un contesto Brand.

Nome e indirizzo sono ricavati automaticamente dal `Domain` canonico. Anche
il collegamento di conferma o invito deve riportare allo stesso dominio. In
questo modo la regola vale per ogni dominio presente e futuro senza duplicare
configurazioni nel codice.

## Configurazione Resend rinviata

Resend non è richiesto dall'MVP solo su invito e `RESEND_API_KEY` non è un
segreto obbligatorio del deploy. I mailer e la configurazione SMTP restano nel
codice per una futura attivazione.

L'applicazione usa Action Mailer tramite SMTP. La configurazione prevista è:

```text
host: smtp.resend.com
porta: 587 con STARTTLS
username: resend
password: RESEND_API_KEY
mittente: <nome Brand> <accesso@dominio-canonico>
```

Il deploy passa un solo `RESEND_API_KEY` come segreto Kamal. Il valore reale deve
esistere soltanto in `.kamal/secrets` sulla macchina di deploy e non deve
essere versionato. Poiché lo stesso account deve inviare per più domini, la
chiave deve avere **Sending access** per tutti i domini verificati e non deve
essere limitata a uno solo. `AUTH_MAILER_HOST=flowpulse.net` resta il fallback
per i collegamenti email privi di un contesto Brand.

Checklist esterna:

- [ ] aggiungere e verificare in Resend ogni dominio con autenticazione attiva;
- [ ] pubblicare nel DNS di ciascuno i record richiesti da Resend per l'invio;
- [ ] creare una API key con permesso **Sending access** per i domini verificati;
- [ ] aggiungere `RESEND_API_KEY=...` al file locale `.kamal/secrets`;
- [ ] eseguire il deploy;
- [ ] inviare un'email reale di verifica a un indirizzo controllato;
- [ ] verificare mittente, link, scadenza del token e impossibilità di
      riutilizzare lo stesso token;
- [ ] verificare successivamente invito e recupero password.

Questa checklist sarà ripresa soltanto quando vorremo verifica automatica
dell'email, consegna automatica degli inviti e recupero password via email.

## Audit locale del 13 ottobre 2026

Verificato con test automatici:

- [x] richiesta pubblica salvata come `Contact` e `DataCommitment`;
- [x] prevenzione delle richieste aperte duplicate;
- [x] approvazione amministrativa e generazione del link da copiare;
- [x] registrazione consentita soltanto con invito valido;
- [x] creazione contestuale di `User`, `Profile`, `BrandAccess` e `Session`;
- [x] chiusura della richiesta quando l'invito viene accettato;
- [x] invito monouso, con email non modificabile durante la registrazione;
- [x] accettazione dell'invito da parte di uno User già esistente;
- [x] blocco degli User sospesi e degli accessi privi di invito;
- [x] stesso User con accessi separati a due Brand;
- [x] revoca della Session e del `BrandAccess`;
- [x] rifiuto dei percorsi di ritorno esterni o appartenenti a un altro Brand.

Suite mirata aggiornata: 61 test e 501 asserzioni; le tre aspettative di
navigazione emerse nell'ultima esecuzione sono state corrette e ricontrollate
con 32 test e 339 asserzioni, senza errori. Su Ruby 4.0.3 i test
paralleli possono provocare un crash nativo del driver PostgreSQL durante il
fork; la suite è stata quindi verificata serialmente con `PARALLEL_WORKERS=1`.

Ancora da completare prima dell'apertura agli utenti:

- [x] accesso iniziale solo tramite richiesta approvata o invito diretto;
- [ ] verifica DNS dei domini mittenti e prova SMTP reale con Resend, rinviata;
- [ ] aggiungere in futuro modalità diverse per Brand (`open`, `invitation`,
      `manual_approval`) se serviranno;
- [ ] automatizzare il recupero password, che attualmente passa da una
      richiesta gestita dal superadmin;
- [ ] costruire la diagnostica superadmin per email, inviti, accessi e Session.
