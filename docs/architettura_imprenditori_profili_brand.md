# Identità, autenticazione, BrandAccess, ruoli e Node

Documento architetturale unico di riferimento. Autenticazione, autorizzazione, ruoli e navigazione
devono evolvere con un solo piano di migrazione.

- Prima analisi: 23 novembre 2026.
- Revisione completa: 24 novembre 2026.
- Caso guida: Elisa Corubolo / Radioestesia e Benessere.
- Incorpora e sostituisce `docs/creator_node_profile_ruoli.md`.

## Decisione sintetica

Il modello distingue sette elementi:

1. `Profile` è l'identità globale e identifica la persona.
2. `User` è un contenitore tecnico transitorio; per ora conserva login e privilegio del superadmin.
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

---

## 1. Entità e responsabilità

### User — transitorio

`User` resta temporaneamente per compatibilità con associazioni e codice legacy.

- conserva per ora `superadmin` e la relativa password di piattaforma;
- la password diventa opzionale e non viene generata per gli utenti ordinari;
- non è la fonte dei ruoli di Brand;
- non deve contenere duplicati come `role`, `active_role`, `creator` o `digital`;
- può mantenere temporaneamente `current_role_assignment_id` come selezione del contesto attivo,
  non come sorgente del permesso.

Il superadmin può configurare qualsiasi risorsa senza dipendere da un `BrandAccess`, ma le
assegnazioni create per altre persone devono rispettare il nuovo modello.

Quando `superadmin` sarà migrato a una credenziale e a un ruolo di sistema, le dipendenze residue
potranno essere spostate su Profile e User potrà essere eliminato.

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
FlowPulse del superadmin resta temporaneamente una Session di piattaforma basata su User.

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

`PlatformCredential` e `SystemRoleAssignment` costituiscono il primo passaggio della nuova
migrazione. Servono a isolare subito password e privilegio del superadmin senza trasferire
credenziali Brand sul Profile. La migrazione è inizialmente additiva: il vecchio accesso User resta
come fallback finché il nuovo login di piattaforma non è stato verificato in locale e produzione.

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
- l'assegnante non può delegare privilegi superiori ai propri;
- la revoca dell'accesso prevale sullo stato del ruolo.

Durante la migrazione `context` può restare polimorfico, ma il contesto operativo deve essere un
Node verificabile.

---

## 2. Tassonomia definitiva

### Ruolo di sistema

| Codice | Collocazione | Significato |
|---|---|---|
| `superadmin` | temporaneamente `users.superadmin` | governo globale della piattaforma |

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

I codici e le loro regole devono avere una sola fonte applicativa, per esempio
`RoleDefinitions::Registry`. Non devono più essere definiti in modo concorrente fra enum,
`nodes.yml`, `domains.yml`, helper e controller.

Per ogni `role_code` il registro descrive almeno:

- etichetta e Brand compatibili;
- tipi di Node sui quali è assegnabile;
- azioni/capability consentite;
- possibilità e limiti di delega;
- ereditarietà eventuale nel sottoalbero;
- requisiti specifici e stato legacy del codice.

Il registro definisce le regole; `RoleAssignment` conserva l'assegnazione concreta. Eventuali dati
variabili per una singola assegnazione restano nel database e non nel registro.

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

Si aggiunge al Node `responsible_profile_id`, non il generico `profile_id`. Il campo indica il
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
2. possiede RoleAssignment attivo sul Node o su un antenato ereditabile;
3. il ruolo include l'azione richiesta;
4. non esistono revoche o limiti più restrittivi.

Il controllo riceve almeno azione, profilo e Node. Non basta mai
`user.has_role?(codice)` senza contesto.

---

## 4. Flusso GeneraImpresa

### Ingresso

1. La persona accetta un invito e ottiene Profile e, durante la transizione, uno User tecnico senza
   password globale.
2. Presenta o accetta una richiesta per GeneraImpresa.
3. Il superadmin o il `gestore_generaimpresa` verifica identità, richiesta e perimetro sulla radice
   GeneraImpresa.
4. L'accettazione crea o attiva il BrandAccess GeneraImpresa.
5. Soltanto dopo può essere creato un RoleAssignment.

La richiesta accettata non assegna automaticamente un incarico amministrativo: accesso e ruolo
restano due decisioni esplicite e tracciate.

### Affidamento di un progetto

1. Il superadmin crea il Node progetto sotto GeneraImpresa.
2. Verifica il BrandAccess attivo della persona.
3. Assegna `imprenditore_generaimpresa` sulla radice, se serve a identificarne la funzione.
4. Assegna lo stesso ruolo sul Node progetto affidato.
5. Imposta `responsible_profile_id` del progetto sul Profile affidatario.
6. Il profilo può amministrare il progetto e, secondo policy, i figli.
7. Un dominio può essere collegato in seguito senza cambiare accesso o ruoli.

Nella prima fase l'imprenditore non crea progetti direttamente sotto la radice GeneraImpresa: può
creare discendenti di progetti già affidati. Una futura estensione richiederà una capability
esplicita, non `creator_flowpulse`.

### Delega futura

L'imprenditore potrà assegnare altri ruoli soltanto:

- a profili con BrandAccess attivo sul medesimo Brand;
- sul proprio Node o sottoalbero;
- entro una matrice di ruoli delegabili;
- senza concedere privilegi globali;
- tramite un servizio unico con audit.

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

Un servizio, per esempio `BrandRoleAssignmentService`, è l'unico punto ordinario di scrittura. Deve
verificare assegnante, destinatario, BrandAccess attivo, compatibilità Profile/Brand/Node, ruolo
ammesso, perimetro, assenza di escalation, idempotenza e audit.

Le letture passano da una policy unica, per esempio:

```ruby
profile.allowed_on?(action, node)
```

La policy risolve accesso, assegnazioni dirette, ereditarietà dagli antenati e stati.

### Compatibilità del superadmin

Durante tutte le fasi il superadmin conserva l'accesso completo alle funzioni esistenti. La policy
restituisce quindi accesso consentito per `user.superadmin?` prima di valutare BrandAccess e ruoli.

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
- la scheda superadmin assegna ancora `creator_generaimpresa` sotto l'Ideatore GeneraImpresa.

Da sostituire almeno: `creator_user?`, `digital_user?`, `responsabile_user?`, `teacher_user?`,
`tutor_user?`, `professional_user?`, `operator_access?` senza contesto, dashboard basate su
`active_role` e autorizzazioni Node basate sul ruolo strutturale.

---

## 9. Piano di migrazione

La migrazione è incrementale: nuovo modello accanto al legacy, spostamento di dati e letture,
eliminazione finale delle colonne obsolete.

### Sequenza operativa unificata

Le parti già implementate restano in funzione. Il lavoro nuovo segue questi blocchi, senza iniziare
la rimozione di User o dei ruoli legacy prima che il blocco precedente sia verificato.

1. **Fondazioni di accesso e ruoli — eseguito:** BrandAccess, registro ruoli, RoleAssignment
   contestuali, manager/policy, responsabile Node e pannelli iniziali.
2. **Isolamento superadmin — implementato e verificato in produzione:**
   PlatformCredential, SystemRoleAssignment e Session di piattaforma; backfill dell'attuale
   superadmin e doppio accesso temporaneo anti-lockout.
3. **Autenticazione Brand — implementata e sottoposta a backfill in produzione:**
   BrandCredential, login e inviti per Brand, Session collegata
   a Profile/accesso/credenziale, User ordinario senza password globale.
4. **Verifica end-to-end — parziale:** superadmin e backfill verificati; resta da completare la
   verifica email e il login Brand di Elisa.
5. **Identità verificata del Profile — prossimo blocco:** introdurre ProfileEmail/ProfileIdentity, collegare gli
   indirizzi verificati e sostituire la ricerca globale basata su `users.email_address`.
6. **Recupero credenziali:** reset e verifica email separati per BrandCredential; percorso distinto
   per il superadmin.
7. **Migrazione autorizzazioni legacy:** letture e aside solo da dominio, BrandAccess,
   RoleAssignment corrente e capability; rimozione progressiva di `active_role`.
8. **Consolidamento dei dati:** vincoli DB definitivi, classificazione dei record legacy e
   cancellazione di alias/helper/configurazioni obsolete.
9. **Eliminazione User:** rimuovere il fallback superadmin e le dipendenze residue soltanto dopo
   tutti i backfill e i collaudi precedenti.

### Fase 0 — Inventario di produzione

```ruby
RoleAssignment.group(:role, :role_operator).count
User.group(:active_role, :role).count
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

**Fase 0 conclusa:** non risultano blocchi per lo schema additivo della Fase 1.

### Fase 1 — Schema compatibile

- aggiungere `brand_access_id` inizialmente nullable;
- normalizzare Node contestuale, stato e audit;
- aggiungere `nodes.responsible_profile_id`, nullable, indicizzato e con FK a `profiles`;
- introdurre `imprenditore_generaimpresa`;
- creare indici e vincoli compatibili col legacy;
- implementare servizio e policy;
- impedire nuove assegnazioni legacy dalla UI.

### Fase 2 — BrandAccess e richieste

- una richiesta approvata produce BrandAccess, non direttamente un ruolo;
- separare «Concedi accesso» da «Assegna incarico»;
- vietare nuovi ruoli senza accesso attivo;
- rendere parametrica la scheda oggi cablata su GeneraImpresa.

### Fase 3 — Backfill

- collegare o creare BrandAccess mancanti dopo verifica;
- rinominare `creator_generaimpresa`;
- tradurre codici specifici dei Brand;
- ricondurre `ideatore`, `admin`, `responsabile` a incarichi contestuali;
- produrre un report manuale per i casi dubbi.

### Fase 4 — Autorizzazioni e UI

- migrare controller, helper e policy ad azione + Node;
- aggiornare dashboard e selettore del contesto;
- aggiornare Imprenditori e «I tuoi Brand»;
- permettere al superadmin di affidare un Node;
- implementare il trasferimento atomico del responsabile e degli incarichi collegati;
- introdurre la delega solo dopo i test della matrice.

### Fase 5 — Vincoli e rimozione legacy

- rendere BrandAccess obbligatorio per i ruoli contestuali;
- rimuovere `users.role`, `users.active_role`, enum e alias obsoleti;
- rimuovere eventuali dati sperimentali `creator_flowpulse`;
- rimuovere la duplicazione Domain → Node;
- valutare `nodes.role_assignment_id` solo quando nessuna gerarchia ne dipende;
- mantenere redirect legacy soltanto temporaneamente.

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

- `users.superadmin` per il solo privilegio globale di sistema;
- tutti gli altri User sono contenitori tecnici senza password e senza ruolo operativo globale;
- accesso ai Brand espresso da `BrandAccess`;
- poteri operativi espressi da `RoleAssignment` contestuali.

`users.active_role` non deve più determinare autorizzazioni o contenuto dell'aside. Durante la
migrazione può restare valorizzato a `superadmin` per il superadmin e a `traveler` per tutti gli
altri, esclusivamente per compatibilità con codice legacy. Alla fine va rimosso insieme allo
switcher dei vecchi ruoli.

### Registrazione, invito e approvazione

La registrazione pubblica libera è già disabilitata: `UsersController#new` e `#create` richiedono un
`BrandInvitation` personale ancora valido e l'email inserita deve coincidere con quella invitata.

Il comportamento legacy considera l'invito come autorizzazione definitiva:

1. l'invito viene emesso per un indirizzo email e un Brand;
2. la persona usa il link e crea User e Profile;
3. `UsersController#create` imposta immediatamente `registration_status = active`;
4. crea o riattiva il BrandAccess;
5. accetta l'invito e apre la sessione.

La migrazione in corso sostituisce la password User ordinaria con BrandCredential e deve mantenere
separati approvazione, BrandAccess e autenticazione. Per i dati storici possono comunque esistere
User attivi che il superadmin non ricorda di aver approvato
direttamente: possono provenire da inviti già emessi o da dati legacy/importati. Non significa che
la registrazione fosse necessariamente aperta, ma l'indice globale deve rendere verificabile
l'origine di ogni account.

Gli indirizzi Gmail che differiscono soltanto per i punti nella parte locale possono raggiungere la
stessa casella, pur risultando User distinti per il vincolo univoco applicativo. La normalizzazione
attuale esegue soltanto `strip` e `downcase`. Non va applicata una riscrittura globale degli indirizzi,
perché le regole non sono uguali per tutti i provider: l'indice FlowPulse deve invece segnalare i
**possibili alias duplicati** e demandare al superadmin una verifica e un'eventuale unione,
sospensione o cancellazione controllata.

L'email può inoltre risultare non verificata (`email_verified_at = nil`) nel flusso a invito, perché
il possesso del link personale è attualmente considerato sufficiente. Il flusso separato di verifica
email, invece, attiva lo User tramite `activate_verified_email!`. Questa differenza va resa esplicita
nella UI e successivamente uniformata.

### Flusso obiettivo

Tenere distinti quattro eventi:

1. **richiesta**: una persona domanda accesso a un Brand;
2. **approvazione**: chi governa quel perimetro approva la richiesta;
3. **invito/identificazione**: la persona crea o collega il Profile e sceglie la credenziale Brand;
4. **accesso**: viene creato o attivato il BrandAccess approvato;
5. **sessione**: la BrandCredential autentica il Profile esclusivamente nel Brand richiesto.

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

1. se `User#superadmin?`, mostra il gruppo **Sistema FlowPulse** con User/Profile, Brand, ruoli e
   strumenti globali;
2. se il dominio corrente è GeneraImpresa, mostra richieste, progetti e persone consentiti dal
   contesto GeneraImpresa;
3. per gli altri Brand, mostra soltanto funzioni autorizzate dal BrandAccess e dai RoleAssignment
   validi nel Brand corrente;
4. il semplice BrandAccess consente l'ingresso, ma non fa comparire strumenti gestionali;
5. il selettore futuro cambia **contesto/Brand o incarico**, non un ruolo globale sullo User.

Il codice attuale usa ancora `FlowRoles.active_role_for`, `active_dashboard_role`, lo switcher di
`users.active_role` e blocchi legacy per `ideatore/creator/digital`. Va migrato per gruppi, iniziando
dalla dashboard globale FlowPulse e dalla proiezione GeneraImpresa.

#### Matrice iniziale delle voci dell'aside

| Contesto attivo | Voci principali |
|---|---|
| superadmin su FlowPulse | Dashboard di sistema; User e Profile; Brand e domini; richieste globali; ruoli e accessi; Node; strumenti tecnici |
| superadmin su GeneraImpresa | Home GeneraImpresa; richieste; persone con BrandAccess; gestori; imprenditori; progetti; collegamento all'amministrazione globale |
| `gestore_generaimpresa` | Riepilogo; richieste GeneraImpresa; persone; BrandAccess; imprenditori; progetti |
| `imprenditore_generaimpresa` | I miei progetti; persone del progetto; richieste del perimetro quando abilitate; impostazioni consentite |
| semplice BrandAccess GeneraImpresa | Home; profilo; contenuti o servizi accessibili, senza voci amministrative |
| ruolo professionale di un altro Brand | voci definite dalle capability del ruolo e limitate al Brand/Node attivo |

La matrice descrive famiglie di voci, non URL cablati nel ruolo. Il registro dei ruoli espone le
capability; un menu registry traduce capability e contesto in sezioni dell'aside. Ogni controller
continua comunque ad applicare la policy: nascondere una voce non è una misura di sicurezza.

#### Dove conservare il ruolo corrente nel Brand

Non esiste un Brand globale da selezionare: in produzione il dominio determina il Brand corrente e
il sistema trova il `BrandAccess` attivo del Profile compatibile con quel Brand. Non servono quindi
`users.active_brand_access_id` o `profiles.active_brand_access_id`.

Un Profile può però avere più `RoleAssignment` nello stesso Brand. In quel caso serve una preferenza
persistente per decidere con quale funzione sta operando e quale aside mostrare. La collocazione
coerente è il `BrandAccess`, perché rappresenta già la relazione Profile + Brand:

- aggiungere `brand_accesses.current_role_assignment_id`, nullable;
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

### Sequenza di implementazione della dashboard

1. creare sotto FlowPulse l'indice globale Profile, mostrando lo User tecnico durante la transizione,
   con filtri per stato, verifica e origine;
2. collegare indice, scheda globale Profile, BrandAccess e Node tramite breadcrumb coerenti;
3. mostrare richieste e inviti di origine nella scheda della persona;
4. aggiungere sospensione/riattivazione e soltanto dopo la cancellazione completa protetta;
5. restringere GeneraImpresa alla propria proiezione di richieste e BrandAccess;
6. sostituire nell'aside le decisioni basate su `active_role` con contesto e policy;
7. normalizzare gli User non superadmin a `traveler` e infine rimuovere il legacy.

## 11. Stato delle attività

| Attività | Stato |
|---|---|
| Scheda profilo superadmin | implementata |
| Link profilo dalle richieste GeneraImpresa | implementato |
| Assegnazione legacy `creator_generaimpresa` | implementata, da migrare |
| Inventario dati di produzione | completato il 24/11/2026 |
| Schema additivo RoleAssignment + BrandAccess | implementato; vincolo DB ancora nullable |
| Registro unico dei nuovi ruoli | implementato nella base applicativa |
| Manager unico di assegnazione/revoca | implementato per il flusso superadmin |
| Rinomina `imprenditore_generaimpresa` | implementata con alias legacy e backfill |
| Eliminazione `creator_flowpulse` dal disegno | decisa |
| Migrazione `ideatore/admin/responsabile` | da progettare sui dati reali |
| Policy unica azione + Node | implementata nella base applicativa |
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
| Login e inviti per Brand | implementati; Elisa resta in `pending_verification` |
| Password User ordinaria rimossa | da completare |
| `sessions.profile_id` | implementato; backfill completo, nessuna Session senza Profile |
| Reset password Brand | da implementare dopo il consolidamento del login |

#### Pulizia dati di produzione — 25 novembre 2026

Prima del rollout sono stati rimossi in una transazione gli User/Profile di prova 2, 3, 4 e 6,
insieme a quattro Session e ai BrandAccess 2, 3 e 6. Richieste e inviti con valore storico sono
rimasti conservati, scollegando i riferimenti alle persone eliminate.

In produzione restano:

- User/Profile 1, superadmin verificato;
- User/Profile 5, Elisa Corubolo, email ancora da verificare;
- BrandAccess 1 e 4 del superadmin;
- BrandAccess 5 GeneraImpresa di Elisa.

Il backfill BrandCredential assegna `pending_verification`, non `active`, agli accessi appartenenti
a un indirizzo non ancora verificato. Elisa non potrà quindi autenticarsi con la nuova credenziale
finché la verifica non sarà completata.

### Gate di verifica prima dell'esecuzione

Il piano non autorizza ancora l'esecuzione automatica delle modifiche elencate sotto. Prima occorre
produrre una verifica del repository e dei dati, senza aggiungere nuove migrazioni o cambiare il
comportamento applicativo:

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

Il gate produce un breve report con esito **GO**, **GO con correzioni** oppure **STOP**. Soltanto
`GO` o `GO con correzioni` consentono di iniziare il blocco esecutivo; le correzioni richieste
devono essere inserite nel piano prima di modificare il codice.

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

Il gate locale e la verifica aggregata di produzione sono quindi conclusi. È possibile iniziare il
primo blocco additivo PlatformCredential/SystemRoleAssignment mantenendo il fallback anti-lockout.

### Prossimo blocco esecutivo dopo il gate

Superato il gate, il primo blocco isola il superadmin e va completato in modo additivo:

1. introdurre `PlatformCredential` collegata al Profile, con email, password cifrata, stato,
   verifica e audit dell'ultimo accesso;
2. introdurre `SystemRoleAssignment` collegato al Profile con il solo codice iniziale
   `superadmin`, stato e audit;
3. aggiungere alla Session i riferimenti opzionali a Profile e PlatformCredential;
4. eseguire il backfill dell'attuale `users.superadmin`, riutilizzando inizialmente l'hash della
   password senza richiedere un cambio immediato;
5. autenticare il superadmin tramite PlatformCredential e verificare il privilegio tramite
   SystemRoleAssignment;
6. mantenere temporaneamente `users.superadmin`, `users.password_digest` e il vecchio login come
   fallback anti-lockout, registrando quale percorso ha aperto la Session;
7. testare login, logout, scadenza, revoca, recupero, policy e accesso a tutti i domini;
8. distribuire e verificare il nuovo percorso in produzione prima di disattivare il fallback;
9. eseguire test mirati, `test:indispensabili`, RuboCop e controllo delle migrazioni.

Il blocco successivo riprende BrandCredential e rende opzionale la password degli User ordinari.
Non rende ancora nullable `users.email_address`: email e vincolo univoco restano temporaneamente il
ponte per ricondurre inviti e dati legacy allo stesso Profile.

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

Non ancora eseguito:

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
