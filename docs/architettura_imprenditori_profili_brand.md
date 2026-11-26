# Identità, autenticazione, BrandAccess, ruoli e Node

Documento architetturale unico di riferimento. Autenticazione, autorizzazione, ruoli e navigazione
devono evolvere con un solo piano di migrazione.

- Prima analisi: 23 novembre 2026.
- Revisione completa: 24 novembre 2026.
- Piano operativo aggiornato: 26 novembre 2026, inclusa la registrazione al Brand.
- Caso guida: Elisa Corubolo / Radioestesia e Benessere.
- Incorpora e sostituisce `docs/creator_node_profile_ruoli.md`.

**Stato corrente:** passi 1–5 del [piano operativo unico](#piano-operativo-unico) implementati e
verificati in locale il 26 novembre; per il passo 5 sono conclusi i test mirati, mentre resta
da concludere la suite indispensabile completa (dettagli sotto).
Resta il collaudo dopo il deploy. Il prossimo intervento pianificato è il
passo 6, migrazione dei consumatori legacy. Prima consolidare registrazione, Profile e BrandAccess; poi uniformare
ruoli, autorizzazioni e navigazione; soltanto alla fine rimuovere i campi legacy.
Gli inventari datati sono storici: non certificano lo stato attuale della produzione e non sono
ulteriori sequenze da eseguire.

## Decisione sintetica

Il modello distingue sette elementi:

1. `Profile` è l'identità globale e identifica la persona.
2. `User` è un contenitore tecnico transitorio per associazioni e fallback legacy.
3. `BrandAccess` autorizza un Profile a entrare nel perimetro di un Brand.
4. `BrandCredential` autentica quel Profile con email e password specifiche del Brand.
5. `RoleAssignment` stabilisce cosa può fare quel Profile, su quale Node e attraverso quale
   `BrandAccess`.
6. `Session` registra Profile, credenziale e perimetro autenticato.
7. `Node` rappresenta Brand, progetti e risorse governate.

Regola fondamentale:

> Nessun `RoleAssignment` operativo può esistere senza un `BrandAccess` attivo e compatibile.

`BrandAccess` risponde a «può entrare nel Brand?»; `RoleAssignment` risponde a «che cosa può fare
e su quale Node?». Nessuno dei due sostituisce l'altro.

Il ruolo generico `creator_flowpulse` non viene introdotto. `creator_generaimpresa` viene rinominato
`imprenditore_generaimpresa`. I ruoli strutturali legacy `ideatore`, `admin` e `responsabile`
devono essere migrati e rimossi; `superadmin` resta un privilegio di sistema.

Il flusso parte **prima dei ruoli**:

```text
Domain → Brand Node → richiesta / invito autorizzato
  → crea o collega il Profile → concede BrandAccess → configura BrandCredential → Session Brand
  → eventuale RoleAssignment → ruolo corrente → azioni e navigazione consentite
```

L'approvazione concede l'accesso, non un ruolo `utente`. Profile, accesso e credenziale vengono
riutilizzati quando già presenti e validi; non si crea una persona nuova per ogni dominio.
`PlatformCredential` e `SystemRoleAssignment` gestiscono separatamente il superadmin.

---

## 1. Entità e responsabilità

### User — transitorio

`User` resta temporaneamente per compatibilità con associazioni e codice legacy.

- conserva ancora flag e password legacy come fallback; il percorso primario del superadmin usa
  già `PlatformCredential` e `SystemRoleAssignment`;
- obiettivo successivo: password opzionale, poi rimossa; oggi la registrazione genera ancora una
  password tecnica casuale sullo User e salva la password scelta nella BrandCredential;
- non è la fonte dei ruoli di Brand;
- non deve contenere duplicati come `role`, `active_role`, `creator` o `digital`;
- conserva temporaneamente `active_role` e `current_role_assignment_id` per i consumatori legacy;
  la selezione corretta è sul BrandAccess e non deve dipendere da questi campi globali.

Il superadmin può configurare qualsiasi risorsa senza dipendere da un `BrandAccess`, ma le
assegnazioni create per altre persone devono rispettare il nuovo modello.

L'isolamento del superadmin è già implementato. User potrà essere eliminato soltanto dopo la
migrazione delle dipendenze residue e dell'identità email, non insieme alla sola rimozione di
`active_role`.

### Profile — identità globale

`Profile` rappresenta la persona nel dominio applicativo.

- durante la transizione appartiene a un `User`; questa dipendenza non fa parte del modello finale;
- può essere pubblico o privato;
- riceve `BrandAccess` e `RoleAssignment`;
- può essere associato a un Node professionale principale;
- non diventa proprietario di un Node per la sola presenza di `Profile#primary_node`;
- la visibilità pubblica è indipendente dai permessi.

### Node

`Node` rappresenta Brand, progetti, attività, corsi e altri oggetti della rete.

- un progetto o un profilo professionale può esistere senza dominio;
- il dominio è una porta di pubblicazione, non una prova di proprietà;
- ogni Node può avere un `responsible_profile_id`, cioè il responsabile corrente e trasferibile;
- i permessi concreti del responsabile restano espressi dalle assegnazioni contestuali.

### BrandAccess

`BrandAccess` collega un `Profile` al Node radice di un Brand e contiene almeno:

- `profile_id` e `brand_node_id`;
- stato (`pending`, `active`, `revoked` o equivalente);
- origine della concessione/richiesta;
- eventuali scope e dati di audit.

Un accesso revocato rende immediatamente inefficaci tutte le assegnazioni che ne dipendono, anche se
restano registrate per la storia.

### BrandCredential

`BrandCredential` autentica un Profile nel perimetro di un singolo Brand.

- appartiene a un solo BrandAccess;
- conserva email normalizzata, password cifrata, stato, verifica e ultimo accesso;
- l'email è unica nel Brand, non globalmente e non per singolo hostname;
- domini canonici, `www` e alias dello stesso Brand condividono la credenziale;
- la stessa email può avere password differenti in Brand differenti;
- sospensione o revoca della credenziale invalida le Session collegate.

`BrandAccess` risponde «può entrare?»; `BrandCredential` risponde «ha dimostrato la propria
identità per questo Brand?». Le password non vanno conservate sul BrandAccess.

### Session

La Session Brand collega:

- `profile_id`, identità autenticata;
- `brand_access_id`, perimetro autorizzato;
- `brand_credential_id`, credenziale utilizzata;
- temporaneamente `user_id`, finché il codice legacy lo richiede.

Il dominio determina automaticamente il Brand. La Session non può essere riutilizzata in un Brand
diverso e diventa inefficace quando BrandAccess o BrandCredential non sono più attivi. Il login
FlowPulse del superadmin usa una Session di piattaforma con Profile e PlatformCredential; il
riferimento a User e il fallback legacy restano temporaneamente.

### Modello finale dell'identità

```text
Profile
├── ProfileEmail / identità verificata
├── BrandAccess
│   ├── BrandCredential
│   └── RoleAssignment
├── eventuale PlatformCredential
└── eventuale SystemRoleAssignment
```

`PlatformCredential` e `SystemRoleAssignment` sono già implementati e il primo collaudo di
produzione è registrato nello storico del 25 novembre. Isolano password e privilegio del superadmin
senza trasferire credenziali Brand sul Profile. Il fallback User non è ancora rimosso.

Il Profile necessita inoltre di un'identità verificata indipendente dalle credenziali Brand. Il
nome definitivo (`ProfileEmail`, `ProfileIdentity` o equivalente) va confermato nel relativo gate,
ma la responsabilità è già stabilita:

- collegare uno o più indirizzi email verificati alla stessa persona;
- impedire che la sola uguaglianza testuale di un'email non verificata unisca due Profile;
- permettere a BrandCredential differenti di usare lo stesso indirizzo o indirizzi differenti;
- sostituire il vincolo globale oggi nascosto in `users.email_address` prima di eliminare User.

Durante la prima transizione `users.email_address` resta il ponte legacy per riconoscere il Profile.
Non va ancora reso nullable né privato del vincolo univoco. La sua eliminazione avverrà soltanto
dopo l'introduzione e il backfill dell'identità verificata del Profile.

### RoleAssignment

`RoleAssignment` è l'unica fonte dei permessi operativi e contestuali.

| Campo | Significato |
|---|---|
| `profile_id` | persona che riceve l'incarico |
| `brand_access_id` | accesso attivo da cui deriva l'incarico; obbligatorio |
| `node_id` / `context` | Node sul quale si può operare |
| `role_code` | funzione assegnata |
| `assigned_by_profile_id` | chi ha assegnato il ruolo |
| `status` | attivo, sospeso o revocato |
| `starts_at`, `ends_at` | validità temporale opzionale |
| audit | autore, date e motivazione delle modifiche |

Vincoli:

- Profile dell'assegnazione e del BrandAccess devono coincidere;
- il Node contestuale deve appartenere al Brand del BrandAccess;
- il BrandAccess deve essere attivo quando il ruolo viene usato;
- il codice deve essere ammesso nel Brand e nel tipo di Node;
- database, modello e servizio devono impedire assegnazioni incompatibili;
- l'assegnante può conferire soltanto i ruoli autorizzati dalla propria regola di delega e nel
  perimetro previsto; il potere di assegnare un ruolo è esplicito e non deriva da una graduatoria
  generica fra ruoli;
- la revoca dell'accesso prevale sullo stato del ruolo.

Durante la migrazione `context` può restare polimorfico, ma il contesto operativo deve essere un
Node verificabile.

---

## 2. Tassonomia definitiva

### Ruolo di sistema

| Codice | Collocazione | Significato |
|---|---|---|
| `superadmin` | `SystemRoleAssignment`, con fallback temporaneo a `users.superadmin` | governo globale della piattaforma |

Non è un `RoleAssignment`, non è delegabile da un Brand e non richiede BrandAccess.

### Ruoli contestuali di ecosistema

| Codice | Brand principale | Significato |
|---|---|---|
| `gestore_generaimpresa` | GeneraImpresa | amministra richieste, accessi, persone e progetti dell'intero Brand |
| `imprenditore_generaimpresa` | GeneraImpresa | sviluppa e amministra progetti affidati |
| `insegnante_posturacorretta` | PosturaCorretta | insegna e gestisce attività abilitate |
| `professionista_percorso_integrato` | Percorso Integrato | opera professionalmente nel perimetro |
| `professionista_rails4business` | Rails4Business | svolge attività digitali abilitate |
| `organizzatore_eventi_ilgiardinodelcorpo` | Il Giardino del Corpo | organizza eventi nel perimetro |

`creator_generaimpresa` è un nome legacy da migrare a `imprenditore_generaimpresa` in dati,
configurazione, interfaccia e controlli.

Non si introduce `creator_flowpulse`: sarebbe un permesso globale ambiguo e duplicherebbe
BrandAccess + ruolo contestuale sul Node.

`gestore_generaimpresa` è assegnato sulla radice GeneraImpresa, richiede un BrandAccess attivo ed è
assegnabile e revocabile soltanto dal superadmin. Non può vedere l'indice globale degli User
FlowPulse, creare superadmin o cancellare User/Profile.

Come estensione futura si annota `gestore_node_project`: un incarico assegnato su uno specifico
Node progetto, limitato al relativo sottoalbero, che potrebbe approvare BrandAccess e attivare un
`imprenditore_generaimpresa` sul proprio Node. **Non viene implementato nella fase corrente**:
prima vanno consolidati audit, limiti di delega e protezione dall'escalation dei privilegi.

### Ruoli condivisi

In futuro possono esistere codici riutilizzabili, per esempio `segreteria`, purché siano sempre
assegnati con BrandAccess e Node. «Condiviso» significa stessa funzione in più Brand, non permesso
globale.

### Registro unico dei ruoli

I codici e le loro regole devono avere una sola fonte applicativa: l'esistente
`RoleDefinitions::Registry`. Non devono più essere definiti in modo concorrente fra enum,
`nodes.yml`, `domains.yml`, helper e controller.

Per ogni `role_code` il registro descrive almeno:

- `scope`: ruolo di uno specifico Brand (`brand`) oppure condiviso (`shared`);
- `enabled`: se è utilizzabile oppure riservato a un'estensione futura;
- etichetta e Brand compatibili;
- tipi di Node sui quali è assegnabile;
- azioni/capability consentite;
- possibilità e limiti di delega;
- ereditarietà eventuale nel sottoalbero;
- requisiti specifici e stato legacy del codice.

Il registro definisce le regole; `RoleAssignment` conserva l'assegnazione concreta. Eventuali dati
variabili per una singola assegnazione restano nel database e non nel registro.

Le definizioni specificano `node_types`, oggi `professional` e `project` per i ruoli esistenti,
e conservano il limite di sette Node dell'imprenditore. Un ruolo `brand` deve avere una lista
esplicita di Brand compatibili. `segreteria` è una definizione `shared` **disabilitata**: resta
consultabile come codice/etichetta, ma non viene proposta per nuove assegnazioni e non concede
capability. Utente ordinario e superadmin non sono definizioni di ruolo contestuale.

`delegatable_role_codes` è l'unica lista dei ruoli che l'assegnante può conferire: il vecchio flag
`delegatable` è stato rimosso. Le liste attuali sono tutte vuote. `delegation_allowed?` verifica
definizione attiva, Brand compatibile e codice destinatario esplicitamente consentito; la policy
deve inoltre verificare Profile, accesso e perimetro concreto. Le strutture delle definizioni sono
immutabili, per evitare modifiche accidentali ai permessi durante l'esecuzione.

### Base standard ed estensibilità — decisione del 26 novembre 2026

Prima di sostituire le dipendenze da `users.active_role`, consolidare un comportamento comune:
dominio corrente → Brand Node → BrandAccess del Profile → RoleAssignment corrente → definizione
del ruolo e azioni consentite. Il dominio viene risolto dall'host in produzione e dal parametro
locale; più domini dello stesso Brand condividono le definizioni dei ruoli.

La base distingue:

| Caso | Rappresentazione |
|---|---|
| Utente ordinario del Brand | BrandAccess attivo, senza incarico operativo corrente; nessun RoleAssignment `utente` |
| Ruolo specifico di un Brand | Definizione nel registro con Brand compatibili espliciti |
| Ruolo condiviso | Definizione riutilizzabile, ma ogni assegnazione resta legata a BrandAccess e Node; `segreteria` è un esempio futuro |
| Superadmin | SystemRoleAssignment di sistema, separato dai ruoli contestuali |

L'operazione comune è **assegnare un RoleAssignment**. Tra un ruolo gestionale e un eventuale ruolo
di «mastro insegnante» cambia l'elenco dei ruoli che ciascuno può assegnare. Per questa base non si
introduce un flusso separato di formazione o promozione: l'esempio formativo esprime una diversa
regola di assegnazione.

Esempi illustrativi, senza attivare nuovi ruoli o permessi:

| Ruolo dell'assegnante | Ruoli assegnabili, se previsti dalla definizione |
|---|---|
| Responsabile incaricato del Brand | Mastro insegnante e/o insegnante nel Brand affidato |
| Mastro insegnante | Insegnante nel proprio perimetro |
| Insegnante | Soltanto gli eventuali ruoli esplicitamente abilitati; lista vuota in assenza di delega |

Il registro esprime questa relazione tramite `delegatable_role_codes`; la policy verifica
l'incarico concreto dell'assegnante, il Node di destinazione e il BrandAccess del destinatario.
Un ruolo può autorizzare l'assegnazione di un ruolo differente senza che l'assegnante debba possedere
personalmente anche quel ruolo. Non esiste una scala fissa «superiore/inferiore» che conceda
automaticamente tutti i permessi dei ruoli successivi.

L'esempio MarkPostura / PosturaCorretta indica un requisito di estensione: un
`imprenditore_generaimpresa` incaricato del governo di uno specifico Brand Node potrà ricevere
la facoltà di assegnare determinati ruoli di quel Brand. La facoltà dovrà essere dichiarata dalla
policy per il Brand affidato, senza estendersi a tutti i Brand di GeneraImpresa. Il solo
`responsible_profile_id` o una relazione padre/figlio tra Node non concede tale facoltà.

Quando Brand di origine dell'incarico e Brand di destinazione sono diversi, occorrerà una regola
esplicita che riconosca l'incarico di governo sul Brand affidato. Il RoleAssignment creato resta
collegato al BrandAccess attivo del destinatario nel Brand di destinazione e deve essere compatibile
con quel Brand e Node. Non basta aggiungere un codice alla lista per abilitare una delega tra Brand:
il caso va prima supportato e verificato dalla policy.

L'identità rimane sempre un Profile: un utente già ammesso al Brand potrà ricevere successivamente
il ruolo di insegnante, senza creare un'altra persona o un altro tipo di account. Nomi dei ruoli,
relazioni di delega e gerarchie degli esempi non sono decisioni operative definitive.

Stato: requisito progettuale documentato. La policy corrente dell'imprenditore mantiene la lista
dei ruoli delegabili vuota. In questa fase non vengono attivati mastro insegnante, segreteria o
deleghe tra Brand. Dopo il consolidamento della base comune, la ricerca del legacy servirà a
migrare ogni utilizzo verso questo comportamento standard.

### Ruoli legacy da eliminare

- enum strutturali `ideatore`, `admin`, `responsabile`;
- enum `creator` e `digital`;
- alias `creator_of_worlds`;
- codici ambigui `creator`, `insegnante`, `professionista`, `teacher`, `professional`, `tutor`
  quando non sono legati a una semantica Brand esplicita;
- `users.role` e `users.active_role`;
- helper che controllano soltanto il nome del ruolo.

I valori numerici rimossi dagli enum non devono essere riutilizzati.

---

## 3. Proprietà e governo dei Node

Il Node dispone già di `responsible_profile_id`, non del generico `profile_id`. Il campo indica il
**responsabile principale corrente** e può essere trasferito a un altro Profile. Serve per mostrare
rapidamente il referente, costruire gli indici dei progetti e rappresentare il passaggio di
responsabilità.

Il trasferimento deve essere un'operazione applicativa esplicita e sottoposta ad audit. Nella stessa
transazione si aggiornano il responsabile e, quando necessario, i relativi RoleAssignment. Il solo
valore di `responsible_profile_id` non concede però un permesso: evita che un campo diretto sul Node
diventi una seconda sorgente autorizzativa in contrasto con BrandAccess e RoleAssignment.

Il governo è espresso tramite `RoleAssignment`:

- l'assegnazione sulla radice GeneraImpresa indica la funzione nell'ecosistema;
- quella sul progetto affidato indica il perimetro concreto amministrabile;
- i permessi sui discendenti possono essere ereditati secondo policy esplicita;
- più profili possono ricevere incarichi diversi sul medesimo Node;
- trasferire un progetto significa chiudere/revocare un incarico e crearne un altro conservando
  l'audit.

`nodes.role_assignment_id`, oggi usato per l'appartenenza storica al mondo dell'ideatore, non deve
essere confuso con l'incarico operativo; verrà trasformato solo dopo la migrazione legacy.

### Caratteristiche specifiche dei RoleAssignment

Ogni tipo di RoleAssignment potrà avere progressivamente regole particolari: azioni consentite,
possibilità di delega, profondità nel sottoalbero, durata, limiti e workflow specifici. Queste
differenze non devono produrre subito una colonna diversa per ogni ruolo.

La base comune resta normalizzata (`profile`, `brand_access`, `node`, `role_code`, stato e audit),
mentre le particolarità vengono definite da una matrice/policy per `role_code`. Solo quando emerge
un dato realmente persistente e strutturato si aggiunge una configurazione o un record associato.
In questo modo i ruoli si possono affinare uno alla volta senza modificare il significato comune di
RoleAssignment.

### Regola di autorizzazione

Un profilo può amministrare un Node se:

1. possiede BrandAccess attivo sul Brand che contiene il Node;
2. opera con un RoleAssignment corrente valido sul Node o su un antenato ereditabile;
3. il ruolo corrente include l'azione richiesta;
4. non esistono revoche o limiti più restrittivi.

Il controllo riceve azione, Node e contesto risolto del Profile nel Brand. Non basta mai
`user.has_role?(codice)` senza contesto.

---

## 4. Flusso GeneraImpresa

### Ingresso

1. La persona richiede accesso a GeneraImpresa, oppure riceve un invito diretto autorizzato.
2. Il superadmin o il `gestore_generaimpresa` verifica la richiesta sulla radice GeneraImpresa.
3. Se il Profile è già collegato, può approvare il BrandAccess; altrimenti emette l'invito che
   permette di creare o collegare il Profile e attivare l'accesso durante la registrazione.
4. La persona configura la BrandCredential mancante oppure accede con quella esistente. User
   resta un ponte tecnico durante la transizione; non è la credenziale scelta per il Brand.
5. Soltanto con BrandAccess attivo può essere assegnato un eventuale RoleAssignment.

La richiesta accettata non assegna automaticamente un incarico amministrativo: accesso e ruolo
restano due decisioni esplicite e tracciate.

### Affidamento di un progetto

1. Il superadmin crea il Node progetto sotto GeneraImpresa.
2. Verifica il BrandAccess attivo della persona.
3. Individua il perimetro concreto dell'incarico; un ruolo sulla radice concede poteri sulla radice
   e non va usato come semplice etichetta identificativa.
4. Assegna `imprenditore_generaimpresa` sul Node progetto affidato.
5. Imposta `responsible_profile_id` del progetto sul Profile affidatario.
6. Il profilo può amministrare il progetto e, secondo policy, i figli.
7. Un dominio può essere collegato in seguito; se introduce un Brand distinto, accessi e incarichi
   nel nuovo perimetro vanno definiti esplicitamente, senza estensione automatica dei permessi.

Nella prima fase l'imprenditore non crea progetti direttamente sotto la radice GeneraImpresa: può
creare discendenti di progetti già affidati. Una futura estensione richiederà una capability
esplicita, non `creator_flowpulse`.

### Delega futura

La delega ordinaria dell'imprenditore all'interno dello stesso Brand sarà ammessa soltanto:

- a profili con BrandAccess attivo sul medesimo Brand;
- sul proprio Node o sottoalbero;
- entro una matrice di ruoli delegabili;
- senza concedere privilegi globali;
- tramite un servizio unico con audit.

L'eventuale delega verso un Brand affidato distinto è l'estensione descritta in «Base standard ed
estensibilità»: richiede una regola esplicita di governo del Brand di destinazione e non è ancora
abilitata.

### Policy iniziale di `imprenditore_generaimpresa`

Nella prima versione l'imprenditore:

- può creare e gestire al massimo **7 Node per Brand** nel proprio perimetro;
- il conteggio riguarda i Node dei quali è responsabile nel Brand, inclusi quelli creati o affidati;
- può operare soltanto sul proprio Node affidato e sui relativi discendenti;
- non approva gli accessi dalla radice GeneraImpresa: la conferma spetta al superadmin o al
  `gestore_generaimpresa`;
- approva richieste e concede/revoca BrandAccess esclusivamente nei domini o progetti che gli sono
  stati affidati, entro il proprio perimetro;
- il BrandAccess rappresenta già l'utente ordinario e non genera un RoleAssignment `utente`;
- per ora non può assegnare alcun ruolo ad altri profili;
- non può assegnare `imprenditore_generaimpresa`, ruoli professionali, ruoli strutturali o
  `superadmin`;
- non può superare il limite creando Node indirettamente o spostandoli tra rami.

Il limite e l'elenco, attualmente vuoto, dei ruoli delegabili vivono nel registro unico dei ruoli e
vengono applicati dal manager e dalla policy, non direttamente dai controller. Ruoli futuri come
`segreteria` verranno abilitati soltanto quando saranno definite capability e responsabilità reali.

---

## 5. Caso Elisa / Radioestesia e Benessere

```text
User Elisa
└── Profile Elisa
    ├── BrandAccess attivo: GeneraImpresa
    ├── RoleAssignment: imprenditore_generaimpresa su GeneraImpresa
    └── RoleAssignment: imprenditore_generaimpresa su Radioestesia e Benessere
        └── Node progetto (`responsible_profile_id`: Elisa) e figli amministrabili
```

Decisioni:

- il Node progetto è sufficiente per far parte di GeneraImpresa;
- un Node professionale personale è facoltativo;
- il progetto può inizialmente non avere dominio;
- aggiungere un dominio non cambia ruolo o proprietà logica;
- il profilo può restare privato senza perdere i permessi;
- collegare una richiesta per email non concede automaticamente accesso o ruolo;
- l'eccezione YAML `panel_usernames` va sostituita dalle autorizzazioni database.

La scheda superadmin aperta da `👤 Profilo: Elisa Corubolo (@elisa_corubolo)` deve mostrare User,
Profile, verifica email, richieste, BrandAccess, ruoli, Node professionale facoltativo e progetti
amministrati anche senza dominio, con azioni esplicite di concessione e revoca.

---

## 6. Pannello GeneraImpresa

La sezione va chiamata **Imprenditori GeneraImpresa**, non Creator of World o Creator GeneraImpresa.

La query non parte da `Node#brand?`, perché tende a coincidere con la presenza di un dominio. Parte
da BrandAccess attivi, RoleAssignment `imprenditore_generaimpresa` e relativi Node, anche senza
dominio.

Ogni scheda distingue:

- persona e visibilità del profilo;
- accesso al Brand e stato;
- Node professionale facoltativo;
- progetti amministrati;
- domini o stato «in costruzione»;
- incarichi ricevuti e delegabili.

---

## 7. Servizio e policy unici

L'esistente `RoleAssignments::Manager` diventa l'unico punto ordinario di scrittura. Deve
verificare assegnante, destinatario, BrandAccess attivo, compatibilità Profile/Brand/Node, ruolo
ammesso, perimetro, assenza di escalation, idempotenza e audit.

Le letture passano dall'esistente `RoleAssignments::AccessPolicy`, ricevendo il contesto risolto
da `AccessContext::Resolver`: accesso, incarico corrente, Node, ereditarietà consentita e stati.
Non serve introdurre un secondo modello `AccessRole` o un altro manager concorrente.

### Compatibilità del superadmin

Durante tutte le fasi il superadmin conserva l'accesso completo alle funzioni esistenti. La policy
riconosce il superadmin tramite il controllo centrale `superadmin_user?`, già basato sul ruolo di
sistema con fallback legacy, prima di valutare BrandAccess e ruoli.

Il bypass vale per l'accesso del superadmin, non per la qualità dei dati che crea: quando assegna un
ruolo a un altro Profile deve comunque usare il servizio unico, collegare un BrandAccess valido e
produrre un RoleAssignment coerente e verificabile.

---

## 8. Debito tecnico noto

- `RoleAssignment` usa enum `admin`, `ideatore`, `creator`, `digital`, `responsabile`, `operator`.
- `User` usa `active_role`, label e switcher legacy.
- `creator_of_worlds` viene convertito in `ideatore`.
- `Node#role_assignment_id` è obbligatorio e propagato ai discendenti.
- alcuni controlli verificano soltanto `insegnante`, `professionista`, `teacher`, `tutor` o
  `professional`, senza Node.
- `domains.yml#operational_roles` duplica `nodes.yml#operator_roles` e può sovrascriverlo.
- restano alias e dati storici `creator_generaimpresa`; il nome corrente è
  `imprenditore_generaimpresa`, da preservare nei flussi nuovi.

Da sostituire almeno: `creator_user?`, `digital_user?`, `responsabile_user?`, `teacher_user?`,
`tutor_user?`, `professional_user?`, `operator_access?` senza contesto, dashboard basate su
`active_role` e autorizzazioni Node basate sul ruolo strutturale.

---

## 9. Piano di migrazione

<a id="piano-operativo-unico"></a>
### Piano operativo unico — 26 novembre 2026

**Obiettivo:** un ingresso al Brand e un comportamento amministrativo comuni, riusando il codice
già presente. Ogni passo produce una modifica circoscritta, verificabile prima del successivo.
Non si parte cancellando colonne o ricreando le funzionalità esistenti.

| Passo | Risultato atteso | Punto di partenza |
|---|---|---|
| 1. Registrazione al Brand | Profile, BrandAccess, credenziale e richiesta collegati correttamente | implementato e verificato in locale; collaudo di produzione dopo il deploy |
| 2. Contratto dei ruoli | un registro definisce azioni, Brand e ruoli assegnabili | consolidato e verificato in locale |
| 3. Contesto corrente | dominio + accesso + incarico corrente determinano il contesto | consolidato e verificato in locale |
| 4. Autorizzazioni e assegnazioni | la stessa policy protegge azioni e concessione dei ruoli | implementato e verificato in locale |
| 5. Dashboard e aside | stessa struttura, contenuti limitati a Brand e ruolo corrente | implementato; 103 test mirati verdi, suite completa da concludere |
| 6. Sostituzione del legacy | nessuna lettura o scrittura dei vecchi selettori User | migrazione per area, colonne ancora conservate |
| 7. Rimozione dei campi | eliminare i due selettori User ormai inutilizzati | solo dopo distribuzione e verifica del passo 6 |

#### Passo 1 — Completare l'ingresso nel Brand

**Riutilizzare:** `BrandAccessRequestsController`, `BrandInvitationsController`, `UsersController`,
`AuthenticationBrandContext`, `BrandRequests::AccessApprover`, `BrandAccesses::Manager` e
`BrandAccessGrants::Manager`.

- Prima fotografare con i test esistenti i due casi: persona nuova e Profile già esistente.
  Correggere soltanto le differenze rispetto al [flusso obiettivo](#flusso-obiettivo).
- Risolvere un solo Brand coerente fra pagina, richiesta, invito e login: host canonico in
  produzione, parametro locale riconosciuto su localhost. Un parametro o un token di un altro
  Brand non deve cambiare silenziosamente il perimetro della richiesta.
- Richiesta con Profile collegato: l'approvazione autorizzata concede o riattiva il BrandAccess.
  Senza Profile: invito autorizzato, poi creazione o collegamento del Profile alla registrazione.
  Non creare persone soltanto perché è stato compilato il modulo di richiesta.
- Riutilizzare il Profile solo con una prova dell'identità; il solo confronto fra email inserite
  non è sufficiente. Per ora mantenere il ponte User e i flussi di verifica esistenti; casi ambigui
  richiedono riconciliazione, senza unire automaticamente persone o duplicarle.
- Garantire un accesso per Profile e Brand, credenziale specifica del Brand, audit della richiesta
  e dell'approvatore; nessun ruolo `utente`. L'invito non deve assegnare ruoli operativi impliciti.
- Invito e approvazione devono applicare lo stesso limite: root GeneraImpresa a superadmin/gestore;
  imprenditore soltanto nei progetti o Brand esplicitamente affidati. La via dell'invito non può
  aggirare un divieto della via «Approva accesso».
- Completare ciascuna operazione in transazione, aprire la Session dopo il commit, impedire
  duplicati e riuso concorrente dell'invito. Non sovrascrivere una credenziale esistente e non
  riattivare un accesso revocato senza una nuova autorizzazione valida.

**Verifica di uscita:** nuova persona, persona esistente in un altro Brand, credenziale già
presente, invito scaduto/revocato/già usato, email o Brand errati, approvatore fuori perimetro,
errore a metà registrazione e doppio invio. L'accesso ordinario non produce incarichi né strumenti
amministrativi. Il login di piattaforma del superadmin continua a funzionare.

**Esito del 26 novembre — implementato e verificato in locale:**

- `BrandAccesses::Authorization` applica la stessa regola a inviti e approvazioni: GeneraImpresa
  richiede superadmin o gestore; gli altri Brand mantengono il perimetro autorizzato e i proprietari
  legacy compatibili. Il solo referente del Node non acquisisce nuovi poteri.
- `BrandInvitations::Issuer` emette e rigenera l'invito nella transazione della richiesta. Se la
  rigenerazione fallisce, il precedente invito resta valido; una richiesta chiusa non genera inviti.
- `BrandInvitations::Acceptance` riusa o crea Profile/accesso/credenziale, registra il grant e
  collega la richiesta nella stessa transazione. Registrazione, login con invito e accettazione da
  una Session Brand già autenticata usano questo punto comune. Non viene creato alcun ruolo.
- Il token deve corrispondere al Brand della pagina; un token esplicito non valido non ripiega su
  un altro invito ricordato. I domini alias dello stesso Brand restano utilizzabili.
- L'accettazione blocca i record di richiesta/invito e lo User esistente durante l'operazione;
  rilegge lo stato prima di procedere. L'invito usato non concede un secondo accesso e una password
  già configurata non viene sostituita. Gli indici univoci esistenti impediscono i duplicati.
- Un invito precedente alla revoca dell'accesso non lo riattiva. Un nuovo invito autorizzato può
  riattivarlo usando la credenziale esistente; senza invito un accesso cancellato non apre Session.
- La concessione conserva progetto, richiesta e autore. Revocare una concessione di progetto
  mantiene le altre concessioni attive, secondo la gestione già presente.
- Verifiche mirate: **61 test, 384 asserzioni**, nessun errore o fallimento.
- Suite indispensabile: **763 test, 4.681 asserzioni**, nessun errore o fallimento, 4 skip.
  Eseguita con `PARALLEL_WORKERS=1`: il driver PostgreSQL locale su macOS ha avuto un crash nel
  fork dei processi paralleli. RuboCop completo: **576 file, nessuna violazione**.
- Allineate cinque aspettative dei test alla navigazione già implementata: i collegamenti legacy
  stanno nel main della Dashboard e l'aside conserva il solo collegamento Dashboard.

Non sono state aggiunte migrazioni né modificati dati di produzione. Il ponte verso User e la
relativa email restano fino al blocco successivo dedicato all'identità verificata del Profile.

**Collaudo dopo il deploy:** su un Brand di prova autorizzato, inviare una richiesta, generare
l'invito come gestore/superadmin e aprirlo in una finestra privata. Completare la registrazione,
verificare la presenza del Profile e del relativo BrandAccess nella scheda amministrativa e
provare logout/login con la password del Brand. Ripetere con una persona già esistente e
controllare il riuso del Profile. Controllare anche il login superadmin FlowPulse. Il deploy e
queste verifiche manuali non sono stati eseguiti in questo intervento.

#### Passo 2 — Consolidare il contratto dei ruoli

**Riutilizzare:** `RoleDefinitions::Registry` e `RoleAssignment`.

- Esplicitare per ogni ruolo: codice, Brand compatibili, azioni, ereditarietà, limiti e
  `delegatable_role_codes`; eliminare il flag duplicato `delegatable` per mantenere un'unica
  regola di delega.
- Separare utente ordinario (nessun incarico), ruoli specifici, ruoli condivisi e ruolo di sistema.
  «Capability» significa soltanto un'azione consentita, per esempio gestire richieste.
- Un solo meccanismo assegna gli incarichi: fra imprenditore e futuro mastro insegnante cambia
  l'elenco dei ruoli assegnabili e il perimetro. Non servono un modello `AccessRole`, gerarchie
  numeriche o un secondo flusso di «formazione».
- Mantenere le deleghe attuali vuote. Non attivare nuovi ruoli, incluso un uso operativo di
  `segreteria`, né deleghe fra Brand in questo lavoro.

**Verifica di uscita:** codici sconosciuti, Brand incompatibili e deleghe non dichiarate sono
rifiutati. Le definizioni attuali conservano le sole facoltà già autorizzate.

**Esito del 26 novembre — implementato e verificato in locale:**

- `RoleDefinitions::Registry` definisce scope, stato di abilitazione e tipi di Node, oltre ad
  azioni, ereditarietà, limiti e lista delle deleghe. `find`/`fetch` conservano la consultazione
  delle definizioni riservate; `for_brand` e `assignable_to?` espongono quelle utilizzabili.
- Modello e manager applicano il registro alle assegnazioni operative con BrandAccess: la lista
  `operator_roles` del Node non può abilitare un codice sconosciuto, disabilitato o di un altro Brand.
  La compatibilità dei vecchi record senza BrandAccess resta nel ramo legacy da migrare: non
  conferisce permessi tramite la nuova policy e non costituisce il modello per nuovi incarichi.
- La policy ignora anche eventuali assegnazioni storiche con definizioni disabilitate o
  incompatibili. Resolver e aside non ne ricavano capability. Le opzioni di affidamento Node
  mostrano soltanto ruoli abilitati e compatibili.
- Nessun nuovo ruolo è stato attivato; tutte le deleghe restano vuote. Il test dell'esempio
  «mastro insegnante → insegnante» usa una definizione temporanea, senza registrarla né salvarla.
- Aggiornati i test del contesto e del selettore: usano Brand compatibili e i due ruoli reali
  GeneraImpresa, invece della futura segreteria o di slug arbitrari.
- Test mirati iniziali: **44 test, 174 asserzioni**, nessun errore o fallimento. Suite finale
  indispensabile con `PARALLEL_WORKERS=1`: **774 test, 4.761 asserzioni**, nessun errore o
  fallimento, 4 skip. RuboCop sui **14 file del blocco**: nessuna violazione.
- RuboCop globale segnala soltanto due violazioni `Style/StringLiterals` nel `Gemfile`, aggiunto
  alla modifica in corso da un lavoro parallelo. Il Gemfile non è stato modificato da questo passo.

Questo passo non aggiunge migrazioni. La selezione e validazione completa dell'incarico corrente
restano il passo 3; la migrazione dei consumatori legacy resta nei passi successivi.

#### Passo 3 — Unificare il contesto corrente

**Riutilizzare:** `CurrentDomain`, `AccessContext::Resolver` e `BrandAccessRolesController`.

- Il resolver restituisce Profile, Domain/Brand, BrandAccess, ruoli validi e ruolo corrente;
  autenticazione, controller e menu devono concordare sullo stesso Brand.
- La preferenza è `brand_accesses.current_role_assignment_id`: unico ruolo valido selezionabile
  automaticamente; più ruoli richiedono una scelta valida; nessun ruolo significa utente ordinario
  soltanto se il BrandAccess è attivo. Un visitatore senza accesso è un caso diverso.
- Scadenza, revoca, incompatibilità del ruolo o revoca dell'accesso invalidano il contesto operativo.
  Il cambio ruolo resta limitato al Profile e al BrandAccess correnti.
- Il ruolo corrente determina le azioni svolte in quel momento, senza sommare i poteri di tutti
  gli altri incarichi. Il superadmin mantiene il bypass di sistema.

**Verifica di uscita:** due Brand e due ruoli nello stesso Brand rimangono separati; cambiare ruolo
cambia sia le azioni ammesse sia la navigazione. URL e selezioni manipolati non allargano l'accesso.

**Esito del 26 novembre — implementato e verificato in locale:**

- `RoleAssignment#effective_for_access?` verifica insieme stato e date, Profile, BrandAccess,
  definizione abilitata, tipo di Node e appartenenza al Brand. Il primo Domain attivo risalendo
  dal Node determina il confine: un sotto-Brand non eredita automaticamente il contesto superiore.
- Il resolver espone soltanto gli incarichi operativi validi per l'accesso corrente. Esclude
  record storici incompatibili, incarichi futuri/scaduti/revocati, Profile diversi, contesti non
  Node o fuori Brand e accessi/account/domìni non attivi. I codici restituiti sono canonici.
- `user?` indica la persona ammessa con BrandAccess attivo e senza incarichi validi; `guest?`
  indica l'assenza dell'accesso. Chi ha più incarichi senza scelta è invece in
  `selection_required?` e non riceve la somma delle loro capability.
- Un solo ruolo valido viene usato automaticamente. Con più ruoli, il selettore propone
  «Scegli come operare»; una scelta vuota richiede una nuova selezione. Con un solo ruolo la
  scelta vuota conserva quell'incarico e non annuncia erroneamente il passaggio a utente.
- Il selettore usa gli stessi incarichi del resolver e rilegge accesso e assegnazione prima di
  salvare. Una selezione divenuta invalida viene ignorata in lettura; se resta un solo incarico
  valido viene usato quello. Alla successiva modifica dell'accesso il riferimento invalido viene
  pulito. Non viene aggiunta una scrittura automatica a ogni lettura della pagina.
- Il controllo dei ruoli contestuali nella vista condivisa è utilizzabile anche fuori dalle due
  aside già uniformate. Le capability e le voci dell'aside seguono l'incarico corrente; con due
  ruoli GeneraImpresa, la voce Richieste compare soltanto scegliendo il gestore.
- Su localhost i parametri di percorso `admin_brand_slug`, `brand_slug` e `path_slug` hanno
  precedenza sul parametro `site`. Un parametro query omonimo non sostituisce quello della route;
  un Brand esplicito sconosciuto non ripiega su un altro Brand ricordato o sul login globale.
- In produzione l'host resta autorevole; alias dello stesso Brand risolvono lo stesso contesto.
  La sessione locale può ricordare il sito per login/dashboard privi di prefisso, ma il fallback
  non viene usato per scegliere un altro Brand su un host reale. L'admin Brand rifiuta una route
  riferita a un Brand diverso da quello dell'host conosciuto.
- Rimossa la risoluzione di autenticazione locale cablata su due soli Brand: usa la ricerca
  comune dei Domain. `dashboard_access_context` mantiene coerenti contesto di autenticazione e
  contesto della dashboard anche negli URL locali senza prefisso.
- Verifiche mirate: **86 test, 434 asserzioni**, nessun errore o fallimento. Suite indispensabile
  con `PARALLEL_WORKERS=1`: **795 test, 4.843 asserzioni**, nessun errore o fallimento, 4 skip.
  RuboCop sui **16 file Ruby del blocco**: nessuna violazione.

Nessuna migrazione, commit o distribuzione in questo passo. Il bypass superadmin resta di sistema.
All'uscita del solo passo 3 la policy generale non usava ancora il ruolo corrente. Il passo 4
descritto sotto ha completato questa conversione per policy e manager operativi; i vecchi ruoli
strutturali e i relativi consumatori restano nella migrazione legacy del passo 6.

**Collaudo dopo il deploy:** con un Profile di prova già abilitato ai due incarichi GeneraImpresa,
cambiare funzione e verificare selettore e voci dell'aside; revocare o far scadere l'incarico scelto
e controllare il successivo contesto risolto. Ripetere i controlli su localhost e sul dominio del
Brand, verificando che non si possa selezionare l'accesso di un altro Brand tramite parametri.

#### Passo 4 — Unificare policy e scritture

**Riutilizzare:** `RoleAssignments::AccessPolicy` e `RoleAssignments::Manager`.

- Passare il contesto corrente alle decisioni operative, sostituendo le autorizzazioni ricavate
  dall'unione indiscriminata degli incarichi. I task senza richiesta ricevono un contesto esplicito.
- Il manager verifica assegnante, ruolo delegabile, BrandAccess attivo del destinatario, stesso
  Profile, compatibilità Brand/Node e sottoalbero autorizzato; ripetere l'operazione non duplica
  l'incarico. Conservare autore e revoca nell'audit.
- Distinguere la facoltà di assegnare da quella di revocare: nessun ampliamento implicito.
  Non attraversare la radice di un altro Brand tramite la sola ereditarietà dei Node.
- Il futuro governo di PosturaCorretta da un incarico GeneraImpresa richiederà una regola esplicita
  sul Brand affidato. Per ora la delega fra Brand resta negata, anche se un ruolo è nell'allowlist.
- Il superadmin conserva l'accesso globale, ma crea soltanto assegnazioni strutturalmente valide.

**Verifica di uscita:** permessi e deleghe fuori perimetro negati anche invocando direttamente
l'azione; revoca immediatamente efficace. Testare il meccanismo di delega con definizioni di prova,
senza abilitare ruoli futuri nei dati applicativi.

**Esito del 26 novembre — implementato e verificato in locale:**

- `Current.access_context` viene inizializzato dopo il ripristino della Session e condiviso dalla
  dashboard e dalla policy. Nei controller i manager ricevono il contesto corrente; la chiamata
  al modello `Node#administered_by?` può usare lo stesso contesto della richiesta.
- `RoleAssignments::AccessPolicy` controlla il solo incarico scelto. Prima di autorizzare rilegge
  dominio, account e contesto: accessi revocati, incarichi scaduti e snapshot di una scelta ormai
  cambiata vengono rifiutati. Non sceglie il Brand o il ruolo a partire dal Node destinatario.
- Fuori da HTTP, le operazioni contestuali devono ricevere un contesto esplicito. Esempio:

  ```ruby
  context = AccessContext::Resolver.new(user: actor, domain: domain).resolve
  NodeManagement::Manager.new(actor: actor, context: context)
    .create_child!(parent: project, attributes: { title: "Nuova attività" })
  ```

- La policy verifica Brand, ramo assegnato ed ereditarietà. La radice di un altro Brand interrompe
  l'accesso, anche se è discendente nella stessa gerarchia dei Node. Anche il superadmin deve usare
  il BrandAccess corretto del destinatario quando assegna un ruolo; conserva il bypass operativo
  di sistema.
- `RoleAssignments::Manager` esegue controlli e scritture nella transazione, rileggendo e bloccando
  i record interessati. Ripetere un'assegnazione già efficace non crea duplicati e non riscrive
  autore, date o audit. Revoca e riattivazione conservano lo stesso incarico con eventi successivi.
- Assegnare e revocare sono autorizzazioni distinte. Nessuna delega è stata abilitata nel registro
  reale; la revoca degli incarichi resta riservata al superadmin. Il test della delega usa una
  definizione temporanea limitata allo stesso Brand/ramo, ripristinata alla fine del test.
- È possibile revocare un incarico operativo anche se il suo accesso è stato cancellato, senza
  riattivarlo. Il riferimento al ruolo selezionato viene pulito nella stessa transazione. I ruoli
  strutturali non possono essere revocati con il manager degli incarichi operativi.
- `NodeManagement::Manager` ricontrolla permessi e limite di sette Node nella transazione di
  creazione, serializzando le creazioni del medesimo Profile. Gli aggiornamenti bloccano e
  rileggono il Node prima della verifica del perimetro.
- I manager di accessi e concessioni ricevono il contesto e verificano il Brand destinatario.
  Una concessione di progetto non autorizza a cancellare l'intero BrandAccess; si revoca il grant
  del progetto e si conservano le altre concessioni valide.
- Persone del Brand, persone del progetto, richieste e operazioni sui progetti usano il contesto
  corrente. L'indice dei progetti non espone tutti i rami di cui la persona è responsabile quando
  opera con un incarico limitato a un solo ramo. Le chiamate dirette agli URL sono verificate
  indipendentemente dalle voci visibili nell'aside.
- Resta un ponte esplicito per i proprietari strutturali legacy nei servizi di accesso, limitato
  al Brand compatibile col contesto. Il solo `responsible_profile_id` o profilo professionale non
  abilita quel ponte. Il ritiro di questi percorsi resta il passo 6.
- L'accettazione pubblica di un invito risolve esplicitamente il contesto dell'emittente per il
  Brand dell'invito: non usa il contesto del visitatore per autorizzare l'emittente. La lettura
  anticipata del contesto locale viene invalidata quando si apre il token, conservando il sito
  corretto nei successivi passaggi di registrazione.

**Storico e schema:** aggiunta `role_assignments.audit_log`, JSONB con default `[]`, mediante
`20261126120000_add_audit_log_to_role_assignments.rb`. Ogni evento registra tipo
(`assigned`, `revoked`, `reactivated`), `actor_profile_id` e data ISO 8601. I record precedenti
partono con uno storico vuoto: non vengono inventati eventi o autori per il passato. Se un
superadmin legacy non ha ancora Profile, la prima operazione tracciata lo crea nella stessa
transazione; le sue facoltà restano disponibili.

Migrazione applicata ai database locali di sviluppo e test; **da applicare anche in produzione
al deploy**. Nessun commit, push o deploy eseguito in questo passo.

**Verifiche:** 68 test mirati iniziali e 60 test di regressione sui casi corretti, senza errori o
fallimenti. Suite indispensabile finale con `PARALLEL_WORKERS=1`: **813 test, 4.918 asserzioni**,
nessun errore o fallimento, 4 skip. RuboCop sui **27 file del blocco**: nessuna violazione.

**Collaudo dopo il deploy:** verificare il cambio fra due incarichi sullo stesso Brand e provare
un'operazione diretta sul ramo non selezionato: deve essere negata. Confermare che assegnazione,
revoca e riattivazione da superadmin registrino gli eventi, che la ripetizione dell'assegnazione
non duplichi l'incarico e che il login/amministrazione del superadmin restino disponibili.

#### Passo 5 — Collegare dashboard e aside alla stessa policy

- Una definizione comune delle sezioni alimenta dashboard e menu, usando contesto e policy dei
  controller. La sola presenza di una capability non deve mostrare link a pagine vietate.
- FlowPulse espone il controllo globale al superadmin; ogni Brand espone persone, accessi,
  richieste e Node nel perimetro consentito. L'imprenditore vede le persone dei propri progetti,
  non automaticamente l'intero indice del Brand.
- Su localhost usare il parametro di Brand nelle route comuni; in produzione usare l'host.
  Riutilizzare i controller e mantenere gli alias necessari, senza copiare un admin per dominio.
- Aside breve, voci legacy raccolte nell'index principale. Il normale utente non vede funzioni
  amministrative; il selettore propone solo i suoi incarichi validi nel Brand corrente.

**Verifica di uscita:** la stessa matrice di accesso vale per localhost e host reali, inclusi
collegamenti, breadcrumb, cambio ruolo e tentativi di apertura diretta di pagine vietate.

**Intervento del 26 novembre — implementato e verificato con test mirati:**

- `DashboardNavigation::Registry` definisce le sezioni, i titoli e le destinazioni; `Policy`
  riusa `AccessContext` e `RoleAssignments::AccessPolicy`. Dashboard, aside e guardie dei
  controller amministrativi Brand consultano queste regole comuni.
- Aside breve per tutti i Brand: home e dashboard quando consentita; il normale utente vede
  il proprio profilo. Il superadmin può raggiungere anche l'amministrazione globale FlowPulse.
  I collegamenti storici restano raccolti nell'index principale FlowPulse, senza dipendere
  dal selettore legacy per comporre l'aside.
- Le pagine Brand adottano il layout condiviso con selettore, aside e breadcrumb. I pannelli
  principali usano lo stesso partial delle sezioni. Il cambio sito propone al normale utente
  soltanto i Brand accessibili; il superadmin conserva tutti i domini.
- Sul dominio dedicato l'ingresso Brand è `/admin`; su localhost è `/:brand_slug/admin`.
  Le route riusano i medesimi controller attraverso concern comuni; gli alias precedenti
  restano validi. Anche il pannello globale ha l'alias completo `/flowpulse/admin` in locale.
  I link globali da altri domini puntano a `https://flowpulse.net/admin/...`.
- Il gestore GeneraImpresa vede richieste, persone e progetti nel perimetro autorizzato;
  l'imprenditore raggiunge le persone attraverso il proprio progetto. I pannelli tecnici
  richiedono assistenza superadmin o autorità legacy sul Brand, non il solo incarico gestore.
- Gli amministratori strutturali legacy conservano l'accesso durante la transizione; la loro
  mappatura e la rimozione dei selettori User restano nel passo 6. Nessuna nuova delega di ruolo
  e nessuna migrazione del database introdotte da questo passo.

Verifiche: **103 test, 790 asserzioni, nessun fallimento, errore o skip**. Coperti dashboard
FlowPulse e Brand, Profile, persone e progetti, richieste, nodi e pannello legacy Ideatore,
oltre a registry e builder. RuboCop pulito sui **22 file Ruby** interessati, con ricontrollo
dei cinque file ritoccati per ultimi; `git diff --check` senza errori.

La suite indispensabile è stata interrotta dopo circa 576 secondi durante il test
`MetroLineCatalogTest#test_imports_the_explicitly_ordered_compatibility_line_idempotently`,
impegnato nella ricostruzione delle gerarchie del catalogo. Aveva eseguito 237 test con due
fallimenti: aspettativa del vecchio menu Ideatore e compatibilità dell'amministratore delegato.
Entrambi corretti e ricontrollati nei 103 test conclusi. **La suite completa non è certificata
verde da questo intervento**: va conclusa prima della distribuzione; il rallentamento del
catalogo resta da approfondire separatamente.

**Ripristino CI del 26 novembre:** nel run GitHub `45822816806` tutti e quattro i job
(`scan_ruby`, `scan_js`, `lint`, `test`) fallivano prima dei controlli, nel passo Set up Ruby:
Bundler non trovava `../rails4b_ai_flow`. La dipendenza locale è sostituita con il repository
pubblico `https://github.com/marcobeffa/rails4b_ai_flow.git`, bloccato alla revisione
`1bcf1507f949ef45a59da92d5b7ed4fc03f1fb88` (0.5.0), in Gemfile e lockfile. Le versioni
delle altre gemme restano invariate. Installazione con `BUNDLE_FROZEN=true` riuscita;
RuboCop completo, Brakeman, bundler-audit e importmap audit conclusi con esito positivo
in locale. La conferma dei quattro job remoti richiede il push e una nuova esecuzione CI.

**Allineamento dei test del menu — 26 novembre:** nel run GitHub `45841113533` le scansioni
Ruby/JavaScript e lint sono verdi. I quattro fallimenti della suite riguardano aspettative
del precedente aside in `Admin::PasswordResetRequestsControllerTest`, `HomeControllerTest`,
`ResourcesControllerTest` e `PagesControllerTest`. I test ora verificano l'aside compatto,
gli accessi Brand nel main e la raggiungibilità di reset password e risorse attraverso
l'indice amministrativo. Verifica mirata: **21 test, 137 asserzioni, nessun errore o fallimento**;
RuboCop pulito sui quattro file. La nuova esecuzione completa locale è stata interrotta
dopo oltre cinque minuti sul catalogo delle linee, senza nuovi fallimenti fino a quel punto;
non costituisce una verifica completa. Il nuovo run GitHub dovrà confermare l'intera suite.

#### Passo 6 — Migrare gli usi legacy, una zona alla volta

- Censire ogni uso di `users.active_role`, `users.current_role_assignment_id` e helper correlati
  indicando il sostituto concreto. Cercare anche test, task, seed e import, non solo le viste.
- Sostituire prima letture/autorizzazioni, poi switcher e scritture: `FlowRoles.active_role_for`,
  `active_dashboard_role`, `HomeController#dashboard_role`/`#dashboard_channel`,
  `ApplicationController#ensure_active_role_assignment`, enum e costanti User correlate.
- Gli accessi legati a `ideatore/admin/responsabile` richiedono una mappatura dei dati verso
  incarichi espliciti: non tradurre un vecchio nome in poteri globali. Conservare i riferimenti
  strutturali Node ancora necessari finché i relativi consumatori non sono migrati.
- Lasciare a User soltanto i ponti tecnici ancora necessari. Dopo aver rimosso tutti i consumatori
  dei due selettori, dichiararli `ignored_columns` e distribuire con le colonne ancora presenti.

**Verifica di uscita:** nessun uso eseguibile residuo dei due selettori, salvo la dichiarazione di
compatibilità e i file storici. Suite indispensabile e RuboCop verdi; collaudo di login, selezione
ruolo e amministrazione dopo la distribuzione. `nodes.role_assignment_id` non viene eliminato
insieme ai selettori User.

#### Passo 7 — Rimuovere i due selettori User

- Solo dopo il passo 6 distribuito e verificato, confermare che processi web, job e task usino
  codice compatibile. Conservare un inventario dei dati prima della rimozione.
- Migrazione separata per eliminare `users.active_role` e `users.current_role_assignment_id`.
  Non eliminare ora User, password, email o flag superadmin.
- Il rollback applicativo torna alla versione compatibile del passo 6; ricreare una colonna non
  ripristina i valori cancellati. Un eventuale recupero dei dati richiede la copia precedente.

**Verifica di uscita:** migrazione e suite di riferimento passano; registrazione, login, ruoli e
dashboard continuano a funzionare senza i due campi.

### Metodo di esecuzione

- Un passo alla volta: verifica del codice interessato, modifica minima, test mirati, aggiornamento
  dello stato in questa guida. Se un requisito è già soddisfatto, verificarlo senza riscriverlo.
- Eseguire i test pertinenti a ogni modifica; suite `test:indispensabili` e RuboCop prima della
  distribuzione del blocco. Ripetere o ampliare i test quando cambiano codice o rischi verificati.
- Nessuna nuova tabella per standardizzare ruoli e menu; eventuali vincoli mancanti emersi nel
  passo 1 vanno aggiunti in modo compatibile. La prima attività è il collaudo dell'ingresso Brand.
- Nessuna rimozione distruttiva per anticipare i tempi. Implementazione, commit e deploy sono
  attività distinte; registrare per ciascun passo quali sono stati effettivamente eseguiti.

### Lavori successivi, fuori da questa sequenza

Prima di eliminare **User interamente** serviranno identità email verificata del Profile
(`ProfileEmail`/`ProfileIdentity`), recupero credenziali per Brand e piattaforma, migrazione delle
associazioni residue e rimozione dei fallback. Il passo 1 deve funzionare col ponte attuale senza
pretendere che la sola email inserita provi l'identità; non richiede di completare ora tutto questo
rifacimento. Restano successive anche nuove deleghe, ruoli condivisi e governo esplicito fra Brand.

### Inventario storico di produzione — 24 novembre 2026

I dati seguenti descrivono l'inizio della migrazione. Non sono il punto da cui ripartire oggi.

```ruby
RoleAssignment.group(:role, :role_operator).count
User.group(:active_role).count
User.where.not(current_role_assignment_id: nil).count
BrandAccess.group(:status).count
```

Verificare inoltre assegnazioni senza Profile, contesti non Node, duplicati, accessi revocati ancora
usati e Node dipendenti da ruoli strutturali.

#### Risultato del 24 novembre 2026

Inventario locale:

- due RoleAssignment: `ideatore` (`role = 6`) e un record legacy `role = 2` non riconosciuto
  dall'enum corrente;
- nessun utente con `current_role_assignment_id`;
- un BrandAccess attivo;
- `BrandAccess#source_domain_id` è oggi obbligatorio;
- nessun `responsible_profile_id` sulla tabella Node.

Inventario produzione:

- un RoleAssignment `ideatore` (`role = 6`), globale;
- un RoleAssignment operatore `creator_generaimpresa` (`role = 11`, Profile 5, Node 9, parent 1);
- tutti i 185 Node dipendono dall'unica assegnazione strutturale `ideatore`;
- nessun utente usa `current_role_assignment_id`;
- cinque BrandAccess, tutti attivi;
- `active_role`: tre utenti con valore `0`, uno con valore legacy non riconosciuto `1`, uno con
  valore `7` (`superadmin` nell'enum corrente);
- la colonna legacy `users.role` non esiste più in produzione.

Conseguenze:

- la migrazione dei RoleAssignment operativi è piccola e può partire dal solo caso GeneraImpresa;
- `nodes.role_assignment_id` non può essere eliminato nella prima fase perché è richiesto da tutti
  i Node di produzione;
- `active_role = 1` deve essere classificato/corretto prima di eliminare `active_role`;
- il vincolo BrandAccess può essere introdotto inizialmente nullable e applicato subito alle nuove
  assegnazioni tramite il manager, quindi reso `NOT NULL` dopo il backfill;
- occorre verificare che Profile 5 possieda uno dei cinque BrandAccess compatibile con Node 9.

Verifica conclusiva di produzione:

- il Profile 5 possiede il BrandAccess attivo 5 sul Node GeneraImpresa 9, tramite il Domain 11;
- il RoleAssignment `creator_generaimpresa` esistente e il BrandAccess indicano quindi lo stesso
  Profile e lo stesso Brand: il backfill di `brand_access_id = 5` è deterministico;
- l'utente con `active_role = 1` non è superadmin e non possiede alcun
  `current_role_assignment_id`; il valore non appartiene all'enum corrente e va normalizzato a
  `traveler` durante la migrazione, conservandone traccia nel report;
- l'utente con `active_role = 7` è il superadmin reale e mantiene il proprio accesso completo.

L'inventario consentì lo schema additivo iniziale, in seguito implementato. Le vecchie fasi
progettuali sono sostituite dai sette passi operativi sopra; non vanno rieseguite come un secondo
piano. Prima di migrare altri dati occorre una lettura aggiornata, senza dedurne lo stato da questo
inventario.

### Test indispensabili

- ruolo senza BrandAccess o con accesso pending/revoked: rifiutato/inefficace;
- Profile diverso da quello dell'accesso: rifiutato;
- Node fuori Brand o ruolo non ammesso: rifiutato;
- delega fuori sottoalbero o escalation: rifiutata;
- revoca accesso: permessi rimossi subito;
- superadmin configura ma produce assegnazioni valide;
- progetto senza dominio resta amministrabile;
- profilo privato mantiene i permessi;
- trasferimento conserva audit;
- cambiare il responsabile senza incarico compatibile non produce autorizzazioni implicite;
- nessuna contaminazione tra Brand.

---

## 10. Dashboard, registrazione e navigazione per perimetro

### Separazione delle dashboard

Le interfacce amministrative non devono mostrare gli stessi dati in tutti i domini.

| Perimetro | Utente | Contenuto della dashboard |
|---|---|---|
| `flowpulse.net` | superadmin | tutti gli User, tutti i Profile, stato di registrazione e verifica, BrandAccess, RoleAssignment, Node e richieste di tutti i Brand |
| `generaimpresa.it` | superadmin | richieste rivolte a GeneraImpresa e BrandAccess GeneraImpresa; collegamento alla scheda globale FlowPulse della persona |
| `generaimpresa.it` | `gestore_generaimpresa` | richieste e BrandAccess della radice GeneraImpresa, persone e progetti del Brand; nessun accesso all'amministrazione globale FlowPulse |
| `generaimpresa.it` | `imprenditore_generaimpresa` | soltanto progetti affidati, discendenti consentiti, persone e richieste comprese nel proprio perimetro |
| altro Brand | responsabile delegato futuro | richieste, persone e accessi del solo Brand o sottoalbero autorizzato |

La tabella globale **Profile** appartiene quindi a FlowPulse e, durante la transizione, mostra anche
lo User tecnico associato. La scheda globale della persona
deve permettere al superadmin di tornare all'indice e di consultare separatamente:

- dati dell'account User e stato della registrazione;
- dati del Profile;
- BrandAccess attivi, pendenti o revocati;
- incarichi contestuali (`RoleAssignment`);
- Node affidati o associati;
- richieste e inviti che spiegano l'origine degli accessi.

GeneraImpresa non deve duplicare questo pannello: mostra una proiezione limitata ai dati di
GeneraImpresa e, soltanto al superadmin, offre il collegamento alla scheda globale FlowPulse.

L'aside FlowPulse futuro espone una voce sintetica **Amministrazione**. La relativa pagina index nel
main conserva e organizza tutte le voci del menu legacy con titolo, descrizione e collegamento
originale (dashboard, produzione, risorse, pagine, appunti, contenuti, mappe ruoli, reset password,
import e strumenti). Questa pagina funziona da contenitore di migrazione: nessun collegamento viene
perso mentre l'aside viene semplificato.

### User e privilegi globali durante la migrazione

La destinazione architetturale resta:

- `SystemRoleAssignment` per il privilegio globale e `PlatformCredential` per il login di sistema;
- User come contenitore tecnico residuo, poi eliminabile; flag e password legacy restano solo
  durante la transizione, finché i relativi consumatori non sono migrati;
- accesso ai Brand espresso da `BrandAccess`;
- poteri operativi espressi da `RoleAssignment` contestuali.

`users.active_role` non deve più determinare autorizzazioni o contenuto dell'aside. Durante la
migrazione può restare valorizzato a `superadmin` per il superadmin e a `traveler` per tutti gli
altri, esclusivamente per compatibilità con codice legacy. Alla fine va rimosso insieme allo
switcher dei vecchi ruoli.

### Registrazione, invito e approvazione

**Stato riscontrato nel codice il 26 novembre 2026; non un nuovo collaudo di produzione:**

| Componente | Comportamento già presente | Verifica/completamento richiesto |
|---|---|---|
| Richiesta pubblica | crea richiesta e contatto, non concede accesso | origine e perimetro coerenti col Brand corrente |
| Registrazione | richiede un invito valido e l'email invitata | controlli uniformi su host, token e stato dell'accesso |
| Apertura invito | porta al login se la credenziale del Brand esiste, altrimenti alla registrazione | nessun passaggio intermedio di scelta, nessuna sostituzione della credenziale |
| Profile | cerca lo User tramite email e costruisce il Profile se manca | collegamento con identità dimostrata, non semplice corrispondenza testuale |
| Accettazione invito | `BrandInvitations::Acceptance`: Profile/accesso/credenziale/grant, accettazione e richiesta in transazione; Session successiva | verificata in locale; collaudo dopo il deploy |
| Approvazione con Profile | `BrandRequests::AccessApprover` concede accesso e grant nella stessa transazione; autorizzazione comune agli inviti | verificata in locale; collaudo dopo il deploy |
| Password scelta | salvata nella BrandCredential | User conserva ancora una password tecnica casuale per compatibilità |

La registrazione è stata consolidata e verificata localmente come primo passo della base standard.
Il Profile è unico per la persona; può avere più accessi, ma per ogni Brand usa la relativa
credenziale. Il suo riconoscimento dipende ancora da User: questa dipendenza è esplicita e verrà
rimossa in un blocco successivo dedicato all'identità verificata.

Per i dati storici possono esistere User attivi provenienti da inviti o import. Lo stato attivo
dello User non prova, da solo, che il BrandAccess o la credenziale di un determinato Brand siano
validi. La scheda amministrativa deve rendere verificabile l'origine di ciascun accesso.

Gli indirizzi Gmail che differiscono soltanto per i punti nella parte locale possono raggiungere la
stessa casella, pur risultando User distinti per il vincolo univoco applicativo. La normalizzazione
attuale esegue soltanto `strip` e `downcase`. Non va applicata una riscrittura globale degli indirizzi,
perché le regole non sono uguali per tutti i provider: l'indice FlowPulse deve invece segnalare i
**possibili alias duplicati** e demandare al superadmin una verifica e un'eventuale unione,
sospensione o cancellazione controllata.

Alla registrazione tramite invito il codice marca verificata l'email della BrandCredential, mentre
il nuovo User può conservare `email_verified_at = nil`. Le due verifiche non vanno confuse nella UI:
una credenziale Brand verificata non certifica automaticamente tutte le identità della persona.
Il collegamento di un Profile preesistente deve verificare il possesso dell'identità; un caso
ambiguo resta da riconciliare. Il flusso di verifica delle credenziali importate ancora pendenti
resta distinto dall'approvazione dell'accesso.

### Flusso obiettivo

Tenere distinti questi passaggi, senza obbligare chi ha già un'identità a registrarsi di nuovo:

1. **Brand di destinazione**: Domain risolto dall'host o dal parametro locale e collegato al Brand
   Node. Alias dello stesso Brand non creano credenziali o accessi distinti.
2. **Richiesta e autorizzazione**: la richiesta pubblica non concede accesso. Un responsabile
   autorizzato la approva oppure emette l'invito che autorizza l'ingresso. È ammesso anche un invito
   diretto autorizzato: conservare l'emittente anche quando non esiste una richiesta iniziale.
3. **Identificazione**: se il Profile manca, viene creato completando l'invito; se esiste, viene
   collegato dopo la verifica dell'identità. Una richiesta può quindi precedere il Profile.
4. **BrandAccess**: si crea o si riutilizza il collegamento Profile + Brand. L'approvazione può
   attivarlo subito per un Profile collegato; l'invito lo attiva alla sua accettazione. Si conserva
   il legame con richiesta, approvatore e, per i progetti, `BrandAccessGrant`.
5. **Credenziale e Session**: se manca la BrandCredential si configura con la password del Brand;
   se esiste si usa il login. Accesso approvato e credenziale verificata/attiva sono condizioni
   distinte. Non aprire Session Brand finché non sono soddisfatte entrambe.
6. **Eventuale incarico**: soltanto dopo l'accesso attivo, un assegnante autorizzato può conferire
   un RoleAssignment. Senza incarichi la persona è un utente ordinario; non si crea un ruolo
   `utente` e non compare un'amministrazione vuota da gestire.

Il completamento che crea o collega Profile, accesso e credenziale deve essere atomico e
idempotente. Un invito scaduto o riutilizzato non concede accesso; un errore non lascia un Profile
nuovo o un accesso parziale. La revoca resta efficace finché non interviene una nuova autorizzazione.

Per le concessioni di progetto, revocare un `BrandAccessGrant` non deve togliere gli accessi concessi
legittimamente da altri progetti; resta valida la gestione delle concessioni già implementata.

Una richiesta può essere eliminata definitivamente da chi amministra il relativo perimetro soltanto
se non ha prodotto BrandAccessGrant, attività o inviti accettati. La cancellazione è destinata a spam
e duplicati, richiede conferma esplicita e revoca gli eventuali inviti pendenti. Le richieste con
storia operativa vengono invece chiuse, rifiutate o archiviate per conservarne l'audit.

Per la radice GeneraImpresa l'approvatore è il superadmin oppure un `gestore_generaimpresa`. Nei
domini o progetti delegati l'approvatore è l'imprenditore soltanto nel proprio perimetro. Un invito emesso dopo
l'approvazione può completare automaticamente la registrazione, ma deve conservare il riferimento
alla richiesta e all'approvatore che lo hanno autorizzato.

### Aside basato sul contesto, non sul vecchio ruolo attivo

L'aside deve essere composto in base a host, Profile corrente, BrandAccess e incarichi:

1. se superadmin di sistema, mostra il collegamento **Amministrazione FlowPulse**; le funzioni
   globali stanno nell'index principale, non tutte replicate nell'aside;
2. se il dominio corrente è GeneraImpresa, mostra richieste, progetti e persone consentiti dal
   contesto GeneraImpresa;
3. per gli altri Brand, mostra soltanto funzioni autorizzate dal BrandAccess e dai RoleAssignment
   validi nel Brand corrente;
4. il semplice BrandAccess consente l'ingresso, ma non fa comparire strumenti gestionali;
5. il selettore cambia l'incarico corrente nel Brand; il Brand è dato dal dominio, non da una
   selezione globale sullo User.

Il codice attuale usa ancora `FlowRoles.active_role_for`, `active_dashboard_role`, lo switcher di
`users.active_role` e blocchi legacy per `ideatore/creator/digital`. Va migrato per gruppi, iniziando
dalla dashboard globale FlowPulse e dalla proiezione GeneraImpresa.

#### Matrice delle funzioni disponibili

| Contesto attivo | Voci principali |
|---|---|
| superadmin su FlowPulse | Dashboard di sistema; User e Profile; Brand e domini; richieste globali; ruoli e accessi; Node; strumenti tecnici |
| superadmin su GeneraImpresa | Home GeneraImpresa; richieste; persone con BrandAccess; gestori; imprenditori; progetti; collegamento all'amministrazione globale |
| `gestore_generaimpresa` | Riepilogo; richieste GeneraImpresa; persone; BrandAccess; imprenditori; progetti |
| `imprenditore_generaimpresa` | I miei progetti; persone del progetto; richieste del perimetro quando abilitate; impostazioni consentite |
| semplice BrandAccess GeneraImpresa | Home; profilo; contenuti o servizi accessibili, senza voci amministrative |
| ruolo professionale di un altro Brand | voci definite dalle capability del ruolo e limitate al Brand/Node attivo |

La matrice descrive funzioni disponibili, non un obbligo di mostrarle tutte nell'aside né URL
cablati nel ruolo. L'aside resta breve e la dashboard raccoglie i collegamenti. Una definizione
comune delle sezioni usa contesto e policy per comporre entrambe le viste. Ogni controller continua
ad applicare la stessa policy: nascondere una voce non è una misura di sicurezza.

#### Dove conservare il ruolo corrente nel Brand

Non esiste un Brand globale da selezionare: in produzione il dominio determina il Brand corrente e
il sistema trova il `BrandAccess` attivo del Profile compatibile con quel Brand. Non servono quindi
`users.active_brand_access_id` o `profiles.active_brand_access_id`.

Un Profile può però avere più `RoleAssignment` nello stesso Brand. In quel caso serve una preferenza
persistente per decidere con quale funzione sta operando e quale aside mostrare. La collocazione
coerente è il `BrandAccess`, perché rappresenta già la relazione Profile + Brand:

- usare l'esistente `brand_accesses.current_role_assignment_id`, nullable;
- il riferimento deve indicare un RoleAssignment attivo appartenente allo stesso Profile e allo
  stesso BrandAccess;
- se esiste un solo ruolo valido, può essere selezionato automaticamente;
- se ne esistono più di uno, l'aside mostra un selettore di funzione;
- se non ne esiste nessuno, la persona opera come semplice utente del Brand;
- se il ruolo corrente viene revocato o scade, il riferimento viene azzerato o sostituito con
  l'unico ruolo ancora valido;
- il superadmin non ha bisogno di questa selezione per il proprio bypass globale, ma può usarla in
  anteprima per verificare l'esperienza di un ruolo.

`users.active_role` e `users.current_role_assignment_id` restano quindi legacy da eliminare: sono
globali e non possono rappresentare correttamente una persona che è, per esempio, gestore in
GeneraImpresa e insegnante in PosturaCorretta.

#### Rimozione di `users.active_role` — decisione del 26 novembre 2026

La colonna va eliminata, ma non prima di avere rimosso le letture legacy che ancora la rendono
operativa. Non esiste un modello `AccessRole`: la selezione corretta del ruolo nel Brand è
`BrandAccess#current_role_assignment`, mentre `BrandAccessRolesController` aggiorna tale
preferenza verificando dominio, accesso, Profile e validità del RoleAssignment.

La sequenza esecutiva è quella dei passi 6 e 7 del [piano operativo unico](#piano-operativo-unico):
prima migrare letture e scritture, distribuire il codice compatibile mantenendo le colonne,
poi rimuoverle con una migrazione separata. Non è un intervento parallelo al consolidamento
di registrazione, contesto e policy.

Il privilegio `superadmin` non viene trasferito su `active_role`: è già rappresentato da
`SystemRoleAssignment` con fallback legacy temporaneo. Eliminare anticipatamente la colonna senza
questa sequenza romperebbe ancora menu, controller Creator World, risorse, demo e diversi test,
oltre a nascondere dipendenze che devono essere migrate esplicitamente.

Il ruolo corrente governa presentazione, navigazione e azioni eseguite in quel momento; non
cancella gli altri incarichi posseduti. La policy deve ricevere il RoleAssignment corrente e
verificare sempre:

1. dominio e BrandAccess compatibili;
2. stesso Profile fra BrandAccess e RoleAssignment;
3. RoleAssignment attivo e collegato a quel BrandAccess;
4. Node contestuale compreso nel Brand o sottoalbero consentito;
5. capability richiesta presente nel ruolo corrente.

In questo modo il cambio nel selettore dell'aside significa **opera come**, mentre il dominio
continua a stabilire automaticamente **dove** si sta operando.

### Gestione degli account dalla dashboard FlowPulse

Il superadmin deve poter sospendere e riattivare un account. La cancellazione definitiva deve
essere un'azione separata, protetta da conferma esplicita e non disponibile sul proprio account
superadmin.

Non va proposta la cancellazione del solo User lasciando un Profile orfano: User e Profile formano
l'identità della persona e il modello corrente usa `User has_one :profile, dependent: :destroy`.
Prima della cancellazione completa vanno mostrati e verificati BrandAccess, incarichi, responsabilità,
inviti e altri record soggetti a vincoli. Per gli account con storia operativa la sospensione è la
scelta ordinaria; la cancellazione completa è riservata a duplicati, errori o account privi di dati
da conservare.

### Collegamento al piano operativo

La dashboard rientra nel passo 5, riusando indice e schede già presenti. Controllare breadcrumb,
provenienza degli accessi e visibilità per ruolo. Ampliamenti della gestione account, filtri avanzati
e cancellazioni non sono prerequisiti per uniformare contesto e navigazione e restano separati.

#### Stato dashboard per dominio — 25 novembre 2026

- in produzione il dominio corrente continua a essere ricavato dall'host;
- su localhost `CurrentDomain` ricava il Brand da `:brand_slug`, `:admin_brand_slug` o `:site`;
- `/:brand_slug/admin` è la dashboard amministrativa comune del Brand;
- la navigazione amministrativa del Brand espone una sola voce sintetica **Dashboard**;
- le precedenti voci Nodi, Schema, Sviluppo, Richieste, Contenuti, Impegni e Privacy sono raccolte
  come schede nel main della dashboard;
- superadmin e proprietario vedono l'indice completo;
- `gestore_generaimpresa` vede soltanto Richieste, Persone e Progetti;
- la visibilità delle schede deriva dalle capability, mentre ogni controller continua ad applicare
  autonomamente la propria policy.

## 11. Stato delle attività

La tabella registra componenti presenti e lavoro residuo; non certifica il collaudo completo del
nuovo contratto. I passi 1–5 sono implementati e verificati in locale, con la limitazione della
suite completa indicata nel passo 5; i passi 6–7 restano da eseguire.
I risultati di produzione più sotto sono fotografie datate.

| Attività | Stato |
|---|---|
| Scheda profilo superadmin | implementata |
| Link profilo dalle richieste GeneraImpresa | implementato |
| Assegnazione legacy `creator_generaimpresa` | sostituita nel flusso nuovo; alias e storico da ritirare dopo verifica |
| Inventario dati di produzione | completato il 24/11/2026 |
| Schema additivo RoleAssignment + BrandAccess | implementato; vincolo DB ancora nullable |
| Registro unico dei nuovi ruoli | passo 2 consolidato e verificato in locale; scope, abilitazione, compatibilità e deleghe espliciti |
| Manager unico di assegnazione/revoca | passo 4: transazioni, idempotenza, contesto e audit; revoca riservata al superadmin |
| Rinomina `imprenditore_generaimpresa` | implementata con alias legacy e backfill |
| Eliminazione `creator_flowpulse` dal disegno | decisa |
| Migrazione `ideatore/admin/responsabile` | da progettare sui dati reali |
| Policy unica azione + Node | passo 4: usa il solo ruolo corrente e rifiuta contesti scaduti, cambiati o fuori perimetro |
| Storico incarichi | `role_assignments.audit_log`, migrazione applicata in locale; da distribuire |
| `nodes.responsible_profile_id` | schema, associazioni e trasferimento implementati |
| Affidamento Node tramite incarico contestuale | implementato per il superadmin |
| Indice Imprenditori GeneraImpresa | da implementare |
| Delega controllata | nessun ruolo delegabile per ora; utente ordinario = BrandAccess |
| Area GeneraImpresa “I miei progetti” | implementata nella prima versione |
| Limite di 7 Node | applicato dalla policy e dal manager di creazione |
| Approvazione richieste di accesso | implementata: crea/riattiva BrandAccess senza ruolo `utente` |
| Approvazione accessi root GeneraImpresa | superadmin o `gestore_generaimpresa` |
| Scope richieste dell'imprenditore | limitato ai domini/progetti delegati; esclusa la root GeneraImpresa |
| Concessioni BrandAccess per progetto | implementate con `BrandAccessGrant` |
| Sezione “Persone del progetto” | implementata con revoca scoped |
| Area superadmin Profile a tab | implementata: Riepilogo, BrandAccess e Node |
| Index/show BrandAccess e Node con breadcrumb | implementati |
| Modello BrandCredential | implementato e distribuito |
| Migrazione e backfill BrandCredential | completati e verificati in produzione |
| Login e inviti per Brand | passo 1 implementato e verificato in locale; collaudo dopo il deploy |
| Autorizzazione inviti e approvazioni | regola condivisa in `BrandAccesses::Authorization` |
| Accettazione invito e concessioni | transazione condivisa in `BrandInvitations::Acceptance`; Profile/accesso riutilizzati |
| Standard dominio + ruolo corrente | passi 3–5 verificati localmente; dashboard e aside condivise, suite completa passo 5 da concludere |
| Rimozione selettori User | pianificata nei passi 6–7; nessuna rimozione in questo aggiornamento |
| Password User ordinaria rimossa | da completare |
| `sessions.profile_id` | implementato; backfill completo, nessuna Session senza Profile |
| Reset password Brand | da implementare dopo il consolidamento del login |

#### Pulizia dati di produzione — 25 novembre 2026

Prima del rollout sono stati rimossi in una transazione gli User/Profile di prova 2, 3, 4 e 6,
insieme a quattro Session e ai BrandAccess 2, 3 e 6. Richieste e inviti con valore storico sono
rimasti conservati, scollegando i riferimenti alle persone eliminate.

Al controllo del 25 novembre risultavano:

- User/Profile 1, superadmin verificato;
- User/Profile 5, Elisa Corubolo, email ancora da verificare;
- BrandAccess 1 e 4 del superadmin;
- BrandAccess 5 GeneraImpresa di Elisa.

Il backfill BrandCredential assegnava `pending_verification`, non `active`, alle credenziali con
indirizzo non ancora verificato. La verifica era quindi necessaria per il login Brand di Elisa;
lo stato attuale va letto nuovamente, senza ricavarlo da questo resoconto.

### Storico del gate iniziale — 25 novembre 2026

Questa verifica precedeva l'isolamento del superadmin, successivamente implementato. È conservata
come motivazione delle scelte e dei fallback; non è un nuovo gate da ripetere integralmente prima
del passo 1. Il controllo iniziale riguardava:

1. censire schema, vincoli e associazioni correnti di User, Profile, Session, BrandAccess,
   BrandCredential, inviti, verifiche email e reset password;
2. trovare tutti i punti che riconoscono `users.superadmin`, autenticano lo User globale o creano
   Session di sistema, inclusi test, task, seed, console amministrative e import;
3. verificare che ogni Profile abbia uno User coerente durante la transizione e definire i casi
   senza Profile o con duplicati;
4. verificare sui dati locali e di produzione quanti User ordinari dipendono ancora dalla password
   globale e quanti BrandAccess devono ricevere una BrandCredential;
5. simulare il backfill e identificare collisioni email nello stesso Brand, accessi revocati,
   credenziali mancanti e Session non riconducibili a un Profile;
6. verificare Profile, email verificata, password, Session attive e percorso di recupero
   dell'attuale superadmin;
7. controllare reversibilità e ordine delle migrazioni, evitando vincoli `NOT NULL` prematuri;
8. eseguire la suite di riferimento prima delle modifiche e annotare eventuali errori preesistenti.
9. verificare tutti gli usi di `users.email_address` come identità globale e confermare che resti il
   ponte transitorio fino all'introduzione di ProfileEmail/ProfileIdentity.

Il gate produsse il report seguente. I nuovi interventi usano invece le verifiche di uscita del
piano operativo del 26 novembre.

#### Esito del gate — 25 novembre 2026

**Esito: GO con correzione preliminare.**

Verifiche concluse:

- `users.superadmin`, `users.password_digest`, `users.email_address`, `profiles.user_id` e
  `sessions.user_id` sono ancora obbligatori nello schema corrente;
- il privilegio superadmin viene letto direttamente da User in helper, policy, resolver, menu,
  controller e servizi: la compatibilità deve essere centralizzata, non sostituita in un solo passo;
- il reset password e la verifica email correnti appartengono ancora a User;
- il working tree contiene già una migrazione BrandCredential e modifiche locali a login, inviti e
  Session, ma non contiene ancora PlatformCredential o SystemRoleAssignment;
- in locale esiste un solo superadmin e il suo backfill è deterministico: Profile presente, account
  attivo, email verificata e password presente;
- in produzione esiste un solo superadmin (`User` 1), con Profile, account attivo, email verificata,
  password presente e tre Session attive; nessuno User di produzione è privo di Profile;
- i test mirati superadmin/Session/policy sono verdi salvo un test di reset di un utente ordinario;
- la suite indispensabile non costituisce una baseline verde perché il nuovo
  `SessionsController` locale accetta sul login globale soltanto il superadmin: numerosi test e
  flussi legacy degli utenti ordinari vengono quindi reindirizzati al login.

Correzione preliminare obbligatoria:

1. mantenere temporaneamente il login User ordinario come fallback legacy quando non è disponibile
   un'autenticazione Brand completa;
2. marcare le Session così aperte con un metodo di autenticazione distinguibile;
3. non concedere nuovi BrandAccess o ruoli attraverso il fallback;
4. ripristinare la suite di riferimento prima di introdurre PlatformCredential;
5. rimuovere il fallback soltanto dopo backfill e collaudo di BrandCredential.

Questa correzione non cambia il modello finale: evita soltanto di sovrapporre la migrazione del
superadmin a una baseline già incompatibile con i flussi esistenti.

**Correzione completata localmente il 25 novembre 2026:**

- il login fuori da un contesto Brand conserva il fallback `legacy_user_password`;
- sui domini Brand gli utenti ordinari devono usare BrandCredential;
- il superadmin può usare la credenziale globale di piattaforma anche da un host Brand;
- il fallback ordinario non crea BrandAccess né assegna ruoli;
- i test che simulano un accesso Brand ora creano esplicitamente BrandAccess e BrandCredential;
- test mirati finali: 30 test e 116 asserzioni, nessun errore;
- suite indispensabile conclusa senza failure o errori riportati;
- RuboCop sui dieci file coinvolti: nessuna violazione.

Il gate consentì il blocco additivo PlatformCredential/SystemRoleAssignment, mantenendo il fallback
di accesso. Il blocco fu poi implementato come descritto sotto: non è più il «prossimo passo».
La successiva eliminazione del ponte `users.email_address` rimane distinta dal ritiro dei selettori
di ruolo User.

#### Stato del primo blocco additivo — 25 novembre 2026

Implementato e distribuito:

- tabelle `platform_credentials` e `system_role_assignments`;
- riferimenti opzionali `sessions.profile_id` e `sessions.platform_credential_id`;
- backfill dell'unico superadmin e dei Profile delle Session esistenti;
- autenticazione primaria tramite PlatformCredential + SystemRoleAssignment;
- fallback tramite `users.superadmin` e password User, distinto come
  `legacy_platform_password`;
- accesso di piattaforma valido anche quando il login parte da un host Brand;
- lettura centrale `superadmin_user?` dal ruolo di sistema con fallback al flag legacy;
- separazione e validazione fra Session di piattaforma e Session Brand.

Verifiche locali:

- backfill: una PlatformCredential, un SystemRoleAssignment superadmin e tutte le Session collegate
  al Profile;
- 28 test mirati, 104 asserzioni, nessun errore;
- suite indispensabile conclusa senza failure o errori riportati;
- RuboCop sui dieci file del blocco: nessuna violazione.

Verificato in produzione:

- una PlatformCredential attiva;
- un SystemRoleAssignment `superadmin` attivo;
- due BrandCredential attive del superadmin;
- una BrandCredential GeneraImpresa di Elisa in `pending_verification`;
- nessuna Session priva di Profile;
- accesso del superadmin all'amministrazione FlowPulse.

Ancora da completare al controllo del 25 novembre:

- verifica email e login Brand di Elisa;
- revoca del fallback legacy;
- migrazione degli indirizzi verificati su ProfileIdentity/ProfileEmail;
- rimozione di `users.superadmin`, password User e tabella User.

## 12. Questioni non bloccanti

1. capability precise dell'imprenditore sulla radice e sul progetto;
2. ruoli delegabili e profondità massima;
3. quali eventi e note conservare nello storico dei trasferimenti di responsabilità;
4. tempi di rimozione dei riferimenti legacy allo User dopo il consolidamento delle Session;
5. quando consentire nuovi progetti autonomi sotto GeneraImpresa;
6. eventuale Node professionale distinto per Radioestesia e Benessere.

## Regola finale

Una persona non governa un progetto perché è «creator», possiede un dominio o ha il proprio Profile
scritto sul Node. Lo governa perché dispone di un accesso attivo al Brand e di un incarico esplicito,
contestuale, verificabile e revocabile sul Node interessato.
