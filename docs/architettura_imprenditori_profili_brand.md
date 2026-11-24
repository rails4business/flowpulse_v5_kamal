# Imprenditori, profili e Brand

Stato analizzato il 23 novembre 2026, con caso guida Elisa Corubolo / Radioestesia e Benessere.

## Decisione sui ruoli

Non si usa un ruolo generico **Imprenditore** o `creator_of_worlds`. Si assegnano ruoli
espliciti e contestuali all'ecosistema:

- `creator_generaimpresa`;
- `insegnante_posturacorretta`;
- `professionista_percorso_integrato`;
- `professionista_rails4business`;
- `organizzatore_eventi_ilgiardinodelcorpo`.

Non conviene reintrodurre `creator_of_worlds` perché:

- nel codice attuale è un valore legacy convertito automaticamente in `ideatore`;
- confonde il ruolo che governa l'intero ecosistema con chi governa uno o più Brand;
- non distingue la persona professionista dal perimetro che può amministrare;
- è poco adatto a GeneraImpresa e alla futura delega di responsabilità.

Questi ruoli usano `RoleAssignment(role: :operator, role_operator: codice)` con
`context` uguale al Node dell'ecosistema e `parent` uguale al suo Ideatore. La capacità
deriva quindi dal codice e dal perimetro assegnato, non da un titolo generico.

## Concetti da tenere separati

### Profilo

`Profile` rappresenta la persona e appartiene a un `User`.

- può essere pubblico o privato;
- identifica username, nome e dati personali;
- può essere collegato a un Node professionale tramite `primary_node`;
- non concede da solo il governo di un Brand progetto.

### Brand professionale

È un `Node` con `node_type: professional`.

- rappresenta l'identità e l'attività pubblica della persona;
- può esistere senza dominio;
- può avere `Profile#primary_node` come profilo professionale principale;
- può essere collegato come `professional_owner_node` a più Brand progetto;
- non implica automaticamente il ruolo Imprenditore.

### Brand progetto

È un `Node` con `node_type: project` usato come perimetro operativo.

- può essere in costruzione e non avere ancora un dominio;
- in futuro può ricevere uno o più domini;
- contiene progetti, contenuti, processi, richieste e ruoli;
- deve avere un amministratore/proprietario esplicito, non dedotto dal dominio.

### Ruolo contestuale

È la capacità di governo e delega.

- viene assegnato a un `Profile` (per Elisa: `creator_generaimpresa`);
- deve avere come parent l'`ideatore` che lo abilita;
- deve essere collegato al Brand o ai Brand amministrati;
- può assegnare soltanto ruoli subordinati entro quei Brand;
- non deve poter assegnare `ideatore`, `superadmin` o ruoli fuori dal proprio perimetro.

## Gerarchia proposta

```text
Ideatore GeneraImpresa
└── creator_generaimpresa: Elisa Corubolo
    └── Brand progetto: Radioestesia e Benessere
        ├── Responsabile
        ├── Digital
        ├── Operatori configurati dal Brand
        └── Collaboratori futuri
```

Il Brand professionale può essere aggiunto, ma non è obbligatorio. I poteri concreti
devono sempre essere verificati sul contesto amministrato.

## Caso Elisa Corubolo

### Stato attuale

- la richiesta può essere collegata a `requester_profile` tramite invito accettato o
  `BrandRequestProfileLinker`;
- nella pagina richieste compare `👤 Profilo: Elisa Corubolo (@elisa_corubolo)`;
- per il superadmin questa indicazione apre la scheda amministrativa della persona;
- il ruolo previsto per Elisa è `creator_generaimpresa`;
- nessun utente usa ancora quel ruolo nel piano originario;
- `radioestesia` è attualmente un solo Node `professional`, privato e figlio di
  `brand-in-costruzione`;
- il catalogo GeneraImpresa descrive Radioestesia e Benessere come Brand personale;
- il pannello Radioestesia autorizza temporaneamente `elisa_corubolo` tramite YAML;
- la sezione “I tuoi Brand” di GeneraImpresa usa `Node#brand?`, quindi mostra soltanto
  Node con dominio e scarta quelli in costruzione senza dominio.

### Struttura desiderata

Elisa deve avere:

1. il proprio `Profile`;
2. un `RoleAssignment` operatore `creator_generaimpresa` nel contesto GeneraImpresa;
3. il Node progetto `radioestesiaebenessere`, amministrato da Elisa;
4. inizialmente nessun dominio sul Brand progetto;
5. in futuro il dominio collegato al Brand progetto senza cambiare profilo o ruolo;
6. la possibilità futura di assegnare ruoli subordinati soltanto nel proprio perimetro.

Il Node professionale è facoltativo. Se verrà creato, non dovrà essere usato
contemporaneamente come Brand progetto.

## Pannello GeneraImpresa

La sezione consigliata è **Creator GeneraImpresa**, non “Creator of World”.

Ogni scheda Imprenditore dovrebbe mostrare:

- profilo e stato pubblico/privato;
- Brand professionale, anche senza dominio;
- Brand progetto amministrati, anche senza dominio;
- domini presenti o stato “in costruzione”;
- ruoli ricevuti e ruoli delegabili;
- collegamento al pannello del Brand e alla gestione delle persone.

La query non deve partire da `Node#brand?`, perché oggi `brand?` significa “possiede un
dominio attivo”. Deve partire dalle assegnazioni di ruolo e dai Node amministrabili,
includendo esplicitamente i Node senza dominio.

## Collegamento dalla richiesta al profilo

Nella pagina:

`/generaimpresa/admin/requests?state=closed`

il testo `👤 Profilo: (@elisa_corubolo)` deve diventare un link a una scheda superadmin.
La scheda deve essere una vista amministrativa distinta da `/profile`, che mostra soltanto
il profilo dell'utente corrente.

Azioni previste nella scheda amministrativa:

- vedere User, Profile e verifica email;
- vedere richieste e accessi ai Brand;
- collegare o correggere il Node professionale principale;
- assegnare/revocare il ruolo `creator_generaimpresa`;
- collegare i Brand progetto amministrati;
- non modificare automaticamente proprietà o gerarchie dei Node.

L'assegnazione deve essere esplicita e confermata: il semplice collegamento per email di
una richiesta non è sufficiente per concedere poteri amministrativi.

## Delega dei ruoli

L'attuale `CreatorWorld::RoleAssignmentsController` non soddisfa ancora il requisito:

- è accessibile soltanto a `ideatore` o superadmin;
- richiede che il canale attivo sia `ideatore`;
- crea tutti i ruoli children direttamente sotto l'Ideatore;
- il ruolo `creator`/Imprenditore viene mandato alla dashboard viaggiatore;
- non limita la delega a uno specifico Brand amministrato dall'Imprenditore.

Serve un servizio unico, per esempio `BrandRoleAssignmentService`, che verifichi:

1. chi assegna è superadmin, Ideatore oppure Imprenditore amministratore del Brand;
2. il ruolo è previsto da `brand.operator_roles` o dalla matrice di delega;
3. `context` coincide con il Brand;
4. il profilo destinatario esiste ed è visibile nel perimetro;
5. non si possono elevare privilegi oltre quelli dell'assegnante;
6. assegnazione e revoca sono registrate in un audit.

## Interventi proposti

### Fase 1 — Scheda profilo superadmin (implementata)

- aggiungere route e controller per la scheda amministrativa del profilo;
- rendere cliccabile il profilo dalla tabella delle richieste;
- mostrare ruoli, Node professionale, BrandAccess e Brand amministrati;
- aggiungere test di autorizzazione superadmin.

### Fase 2 — Assegnazione Creator GeneraImpresa (implementata per il superadmin)

- usare `operator` con `role_operator: creator_generaimpresa`;
- aggiungere l'azione superadmin per assegnare il ruolo sotto l'Ideatore di GeneraImpresa;
- non usare `creator_of_worlds`, che resta alias legacy di `ideatore`;
- assegnare Elisa soltanto dopo aver verificato il suo Profile reale.

### Fase 3 — Node Radioestesia

- decidere se mantenere il Node professionale esistente, che resta facoltativo;
- creare o consolidare il Node progetto Radioestesia e Benessere;
- collegare il progetto a Elisa tramite amministrazione/ownership esplicita;
- mantenere il progetto in costruzione e senza dominio;
- sostituire gradualmente l'eccezione YAML `panel_usernames` con autorizzazioni database.

### Fase 4 — GeneraImpresa / Imprenditori

- creare l'indice degli Imprenditori;
- includere Brand professionali e Brand progetto senza dominio;
- modificare “I tuoi Brand” affinché usi `administered_by?` sui Node candidati, non solo
  sui Node con dominio;
- distinguere visivamente Persona, Brand professionale, Brand progetto e Dominio.

### Fase 5 — Delega contestuale

- permettere all'Imprenditore di aprire il pannello persone del proprio Brand;
- assegnare ruoli contestuali consentiti;
- impedire assegnazioni fuori perimetro;
- aggiungere audit e test completi.

### Fase 6 — Rinominare il codice legacy

Solo dopo aver stabilizzato permessi e dati:

- valutare la migrazione enum `creator` → `entrepreneur`;
- mantenere redirect dalle route `/creator_world`;
- rinominare namespace e testi tecnici;
- rimuovere progressivamente l'alias `creator_of_worlds` dopo aver aggiornato fixture,
  test e import storici.

## Regole generali per tutti i Brand

Questa architettura deve valere per ogni persona e ogni Brand:

- un profilo può esistere senza Node;
- un Brand professionale può esistere senza dominio;
- un Brand progetto può esistere senza dominio;
- il dominio è una pubblicazione/porta d'ingresso, non la prova di proprietà;
- essere professionista non significa automaticamente essere Imprenditore;
- essere Imprenditore non rende automaticamente pubblico il profilo;
- proprietà, amministrazione e visibilità sono dimensioni separate;
- la delega è sempre contestuale a un Brand e non globale.

## Decisioni ancora da confermare

1. Se mantenere e collegare anche un Node professionale per Elisa.
2. Slug definitivo del Brand progetto: proposta `radioestesiaebenessere`.
3. Quali ruoli un `creator_generaimpresa` potrà delegare autonomamente.
4. Se un Brand progetto possa avere più creator con pari responsabilità.
