# Profili, BrandAccess, ruoli e Node

Documento architetturale unico di riferimento.

- Prima analisi: 23 novembre 2026.
- Revisione completa: 24 novembre 2026.
- Caso guida: Elisa Corubolo / Radioestesia e Benessere.
- Incorpora e sostituisce `docs/creator_node_profile_ruoli.md`.

## Decisione sintetica

Il modello distingue quattro elementi:

1. `User` autentica la persona e conserva soltanto i privilegi di sistema, come `superadmin`.
2. `Profile` identifica la persona che riceve accessi e incarichi.
3. `BrandAccess` autorizza quel profilo a entrare nel perimetro di un Brand.
4. `RoleAssignment` stabilisce cosa può fare quel profilo, su quale Node e attraverso quale
   `BrandAccess`.

Regola fondamentale:

> Nessun `RoleAssignment` operativo può esistere senza un `BrandAccess` attivo e compatibile.

`BrandAccess` risponde a «può entrare nel Brand?»; `RoleAssignment` risponde a «che cosa può fare
e su quale Node?». Nessuno dei due sostituisce l'altro.

Il ruolo generico `creator_flowpulse` non viene introdotto. `creator_generaimpresa` viene rinominato
`imprenditore_generaimpresa`. I ruoli strutturali legacy `ideatore`, `admin` e `responsabile`
devono essere migrati e rimossi; `superadmin` resta un privilegio di sistema.

---

## 1. Entità e responsabilità

### User

`User` gestisce autenticazione e privilegi globali.

- conserva `superadmin`;
- non è la fonte dei ruoli di Brand;
- non deve contenere duplicati come `role`, `active_role`, `creator` o `digital`;
- può mantenere temporaneamente `current_role_assignment_id` come selezione del contesto attivo,
  non come sorgente del permesso.

Il superadmin può configurare qualsiasi risorsa senza dipendere da un `BrandAccess`, ma le
assegnazioni create per altre persone devono rispettare il nuovo modello.

### Profile

`Profile` rappresenta la persona nel dominio applicativo.

- appartiene a un `User`;
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
| `superadmin` | `users.superadmin` | governo globale della piattaforma |

Non è un `RoleAssignment`, non è delegabile da un Brand e non richiede BrandAccess.

### Ruoli contestuali di ecosistema

| Codice | Brand principale | Significato |
|---|---|---|
| `imprenditore_generaimpresa` | GeneraImpresa | sviluppa e amministra progetti affidati |
| `insegnante_posturacorretta` | PosturaCorretta | insegna e gestisce attività abilitate |
| `professionista_percorso_integrato` | Percorso Integrato | opera professionalmente nel perimetro |
| `professionista_rails4business` | Rails4Business | svolge attività digitali abilitate |
| `organizzatore_eventi_ilgiardinodelcorpo` | Il Giardino del Corpo | organizza eventi nel perimetro |

`creator_generaimpresa` è un nome legacy da migrare a `imprenditore_generaimpresa` in dati,
configurazione, interfaccia e controlli.

Non si introduce `creator_flowpulse`: sarebbe un permesso globale ambiguo e duplicherebbe
BrandAccess + ruolo contestuale sul Node.

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

1. La persona si registra e ottiene User e Profile.
2. Presenta o accetta una richiesta per GeneraImpresa.
3. Il superadmin verifica identità, richiesta e perimetro.
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
- può approvare richieste e concedere/revocare BrandAccess nel proprio perimetro;
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

### Sequenza operativa concordata

1. analizzare schema, modelli, configurazioni, chiamanti e dati locali/produzione;
2. scrivere test di caratterizzazione sui comportamenti legacy indispensabili;
3. introdurre il registro unico dei nuovi ruoli e gli alias temporanei;
4. aggiungere lo schema compatibile (`responsible_profile_id`, `brand_access_id`, stato e audit);
5. introdurre manager unico e policy, mantenendo il bypass del superadmin;
6. aggiornare la scheda superadmin per accesso, incarico, affidamento e trasferimento;
7. migrare per primo il caso Elisa / Radioestesia e Benessere;
8. migrare progressivamente letture, scritture e dati degli altri Brand;
9. rendere obbligatori i nuovi vincoli;
10. eliminare ruoli, colonne, helper e configurazioni legacy soltanto a migrazione conclusa.

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

## 10. Stato delle attività

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
| Scope richieste dell'imprenditore | implementato sul progetto affidato e relativi discendenti |
| Concessioni BrandAccess per progetto | implementate con `BrandAccessGrant` |
| Sezione “Persone del progetto” | implementata con revoca scoped |

## 11. Questioni non bloccanti

1. capability precise dell'imprenditore sulla radice e sul progetto;
2. ruoli delegabili e profondità massima;
3. quali eventi e note conservare nello storico dei trasferimenti di responsabilità;
4. mantenimento di `current_role_assignment_id` o contesto in sessione;
5. quando consentire nuovi progetti autonomi sotto GeneraImpresa;
6. eventuale Node professionale distinto per Radioestesia e Benessere.

## Regola finale

Una persona non governa un progetto perché è «creator», possiede un dominio o ha il proprio Profile
scritto sul Node. Lo governa perché dispone di un accesso attivo al Brand e di un incarico esplicito,
contestuale, verificabile e revocabile sul Node interessato.
