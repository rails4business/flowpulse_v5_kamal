# Piano — Dashboard produttiva per Creator

**Data:** 17 ottobre 2026  
**Stato:** definizione in corso, non ancora implementato  
**Prototipo:** `docs/private_prototypes/viste_html/Dashboard · generaimpresa.html`

> **Revisione del 19 ottobre 2026:** l'ipotesi “DataExperience = prodotto” è
> in revisione. Lo schema corrente, che distingue prodotto, catena e ciclo di
> lavorazione, è in
> [`2026-10-19-SCHEMA_SKILL_PRODOTTI_PROCESSI_1IMPEGNO.md`](./2026-10-19-SCHEMA_SKILL_PRODOTTI_PROCESSI_1IMPEGNO.md).
> Le sezioni sottostanti restano come cronologia del ragionamento e non devono
> guidare nuove migrazioni finché il nuovo schema non viene approvato.
> Nella UI corrente, `NodeProcess` espone **Catena** e **Dima attiva**;
> l'esecuzione concreta viene chiamata **Ciclo di lavoro**. Persone e
> calendario appartengono a 1impegno, dove ogni persona ha una pagina propria.

## Obiettivo

Costruire una dashboard che unisca senza confonderli:

```text
Generaimpresa
Brand → rami, progetti e sottobrand

Rails4Business
NodeProcess → catene produttive → prodotti in lavorazione

1impegno
Commitment, Slot e Session → persone, disponibilità e calendario
```

La prima versione sarà riservata al superadmin, ma dati e autorizzazioni
dovranno già essere compatibili con una successiva apertura ai Creator.

## Decisioni confermate

Questa sezione è la fonte corrente delle decisioni. Sostituisce le ipotesi
precedenti su cicli, stazioni, dime e prodotti.

### 1. Brand, progetti e sottobrand

- ogni Brand è un `Node`;
- un Node con Domain è un Brand pubblico o un sottobrand;
- i Node figli formano i rami del Brand;
- un Node figlio senza Domain può essere un progetto, sottoprogetto o canale;
- un Node figlio con Domain è anche un sottobrand;
- la gerarchia produttiva non deve creare un secondo albero parallelo ai Node.

### 2. La catena produttiva

- `NodeProcess` rappresenta una catena di montaggio, ricetta o algoritmo
  ripetibile;
- appartiene al Node sul quale viene svolto il lavoro;
- può produrre nel tempo molti prodotti;
- può avere un responsabile generale;
- ritmo, quantità e costi sono informazioni del processo o valori calcolati,
  non nuovi Node.

Esempio:

```text
NodeProcess: video YouTube settimanale
├── DataExperience: Video A
├── DataExperience: Video B
└── DataExperience: Video C
```

### 3. Una DataExperience è un prodotto

- una `DataExperience` rappresenta un singolo prodotto lungo tutta la sua vita;
- prodotti distinti richiedono DataExperience distinte;
- più prodotti possono essere aperti, programmati e lavorati contemporaneamente;
- aggiornare un prodotto non crea una nuova Experience: aggiunge nuovi
  passaggi alla stessa Experience;
- se da un video nasce un carosello, video e carosello sono due prodotti e
  quindi due Experience, eventualmente collegate;
- una nuova Experience può partire vuota oppure essere ottenuta duplicando
  qualsiasi Experience precedente;
- la duplicazione mantiene i tipi originari: Commitment resta Commitment,
  Slot resta Slot e Session resta Session;
- i nuovi record vengono creati a nome della persona che duplica;
- la duplicazione copia la struttura scelta, ma svuota date, orari, stati di
  completamento, tempi effettivi, costi, calendari e note personali;
- duplicare una vecchia Experience è una possibilità, non un obbligo.

Stati iniziali proposti:

```text
draft → planned → in_progress → completed
                              ↘ cancelled
                              ↘ archived
```

Gli aggiornamenti successivi possono riaprire il lavoro aggiungendo nuovi
passaggi, mantenendo nello stesso prodotto tutta la cronologia.

Per un prodotto editoriale, il DataCommitment `publish` completato porta la
DataExperience a `completed` e pubblica lo SkillProduct nella stessa
operazione. Un successivo Commitment `update` o `fix` riapre la medesima
Experience; quando viene completato, la Experience torna `completed` senza
creare un nuovo prodotto e senza nascondere nel frattempo quello pubblicato.

### 4. I passaggi della ricetta

Non viene introdotto per ora né `DataStep` né `NodeProcessStation`.

I passaggi sono direttamente:

- `DataCommitment`;
- `DataSlot`;
- `DataSession`.

Tutti possiedono `position` e, quando sono passaggi principali della stessa
DataExperience, condividono un unico ordine logico:

```text
position 10 → Step 1 · DataCommitment
position 20 → Step 2 · DataSlot
position 30 → Step 3 · DataSession
position 40 → Step 4 · DataCommitment
```

La UI genera `Step 1`, `Step 2`, ecc. dopo avere unito e ordinato gli elementi.
Le posizioni tecniche avanzano inizialmente di dieci per consentire inserimenti
intermedi.

Un servizio applicativo dovrà:

- caricare insieme i tre tipi;
- distinguere elementi principali da elementi annidati;
- impedire o correggere collisioni di posizione;
- riordinare tutta la ricetta dopo spostamenti e inserimenti.

Un Commitment dentro uno Slot e uno Slot dentro una Session non diventano
automaticamente altri step principali: sono dettagli operativi dello step.

### 5. Quando usare Commitment, Slot e Session

Usare il livello più piccolo sufficiente:

```text
persona definita + attività singola → DataCommitment
persona/posto ancora da assegnare   → DataSlot
più attività o persone coordinate   → DataSession
```

- il `DataCommitment` registra un impegno assunto da una persona;
- il `DataSlot` rappresenta un posto, una disponibilità o un'attività ancora
  da assegnare;
- la `DataSession` coordina più persone, attività o slot vicini nel tempo;
- un Commitment può essere collegato successivamente a uno Slot;
- una Session può contenere Slot e Commitment, senza rendere obbligatoria
  l'intera gerarchia per le attività semplici.

### 6. Sessioni condivise tra più prodotti

Una stessa sessione può coordinare il lavoro relativo a più prodotti.

Esempio:

```text
DataSession: registrazione del 20 ottobre
├── DataSlot “Registrazione Video A” → Experience Video A
├── DataSlot “Registrazione Video B” → Experience Video B
└── DataSlot “Registrazione Video C” → Experience Video C
```

Ogni Slot resta nella ricetta del proprio prodotto. La Session serve a
raggrupparli nel calendario.

Quando una Session costituisce invece un intero passaggio di una sola
Experience, può comparire direttamente nella sua ricetta con una posizione.

Dal 19 ottobre 2026 `data_sessions.data_experience_id` è facoltativo: una
Session diretta può appartenere a una Experience, mentre una Session condivisa
raggruppa gli Slot delle rispettive Experience senza collegarsi al
`NodeProcess`.

### 7. SkillProduct

Non viene creato un secondo modello di risultato o `ProductionOutput`.

- `SkillProduct` è la rappresentazione del prodotto generato da una Skill
  attivata sul Node;
- la DataExperience è il prodotto operativo e ne conserva la lavorazione;
- lo SkillProduct ne conserva corpo, dati, sorgente, visibilità e
  pubblicazione;
- la relazione normale è uno a uno e può essere facoltativa finché il prodotto
  è ancora in lavorazione;
- Session, Slot e Commitment possono continuare a riferirsi allo SkillProduct
  sul quale stanno operando;
- una modifica dello stesso prodotto aggiunge passaggi alla stessa Experience
  e aggiorna lo stesso SkillProduct.

Le DataExperience non vengono collegate direttamente tra loro. Prodotti
distinti restano lavorazioni indipendenti e vengono messi in relazione tramite
gli `SkillProductLink` (`derived_from`, `uses`, `contains`, `presents`,
`related`). La dashboard può risalire da ogni SkillProduct alla relativa
Experience. Quando serve costruire una relazione prima della pubblicazione,
lo SkillProduct viene creato subito in stato `draft`.

Lo stato produttivo della DataExperience e lo stato editoriale dello
SkillProduct hanno significati distinti, ma le loro transizioni sono
coordinate dallo stesso DataCommitment editoriale:

```text
publish → completa il passaggio e pubblica lo SkillProduct
update  → riapre la lavorazione senza nascondere il prodotto pubblicato
fix     → registra e applica una correzione allo stesso prodotto
```

Gli aggiornamenti restano sempre nella DataExperience originaria e non
incrementano il numero dei prodotti.

Da verificare nell'implementazione: collocare la chiave facoltativa e univoca
sul lato `SkillProduct`, così una DataExperience può esistere anche prima
dell'attivazione o generazione della Skill.

### 8. Tempi, responsabilità e costi

- il `DataCommitment` è la fonte della persona che prende l'impegno;
- `responsible_profile` risponde del risultato;
- `assignee_profile` svolge materialmente il lavoro;
- tempi programmati ed effettivi restano nei Commitment, Slot e Session;
- il costo di un prodotto deriva dai Commitment della sua Experience;
- il costo medio del processo deriva dai prodotti conclusi e dai relativi
  costi reali;
- non devono essere inseriti contatori o costi manuali quando possono essere
  calcolati dai record reali.

Le aggregazioni di tempi e costi sono rinviate oltre l'MVP. I valori già
presenti nei Commitment vengono conservati, ma non si introducono ancora
ripartizioni delle Session condivise, costi medi o costo per prodotto.

Il creatore viene uniformato sul `Profile`: `created_by_profile_id` viene
aggiunto a NodeProcess, DataExperience, DataSession e DataSlot. I vecchi
`created_by_user_id` restano temporaneamente durante il backfill. Creatore,
responsabile e assegnatario rimangono concetti distinti.

### 9. Contesto Node senza fonte duplicata

La DataExperience non riceve un proprio `node_id`. Il Node si ricava:

- dal `NodeProcess`, quando il prodotto appartiene a una catena;
- dallo `SkillProduct → ReusableSkillNode`, quando nasce da una Skill.

Se entrambi sono presenti devono indicare lo stesso Node. Nel nuovo flusso una
Experience deve avere almeno Process o SkillProduct; eventuali record legacy
senza entrambi vengono segnalati dall'audit e regolarizzati progressivamente.

### 10. Problema → Soluzione

`ProblemSolvingCycle` resta distinto dalle Skill e non è obbligatorio in ogni
catena produttiva. Può essere collegato a un Node, a un processo o a un
prodotto quando occorre affrontare un problema:

```text
Problema
→ Isolamento
→ Soluzioni possibili
→ Soluzione minima
→ Test personale
→ Test con poche persone
→ Feedback
→ Verifica
→ Diffusione
→ Chiusura o automazione
```

Se la soluzione migliora stabilmente il modo di produrre, viene recepita nel
`NodeProcess` o usata nella successiva duplicazione della DataExperience.

## Corrispondenza con i modelli

| Concetto | Modello | Decisione |
| --- | --- | --- |
| Brand, progetto, sottobrand | `Node` | riutilizzare |
| Catena produttiva | `NodeProcess` | riutilizzare e completare |
| Prodotto e sua lavorazione | `DataExperience` | riutilizzare e completare |
| Prodotto della Skill | `SkillProduct` | collegamento uno a uno facoltativo |
| Impegno personale | `DataCommitment` | riutilizzare |
| Posto o attività da assegnare | `DataSlot` | riutilizzare |
| Attività coordinata | `DataSession` | riutilizzare e consentire condivisione |
| Problema da risolvere | `ProblemSolvingCycle` | facoltativo e separato |
| Relazione tra prodotti | `SkillProductLink` | riutilizzare; nessun link diretto tra Experience |

## Autorizzazioni previste

- il superadmin può gestire l'intera struttura;
- proprietario e amministratore del Node governano Process e prodotti;
- il responsabile del Process governa la catena;
- il responsabile della DataExperience governa il singolo prodotto;
- l'assegnatario gestisce soltanto il proprio Commitment;
- la prima UI resta superadmin, ma le regole devono vivere fuori dai
  controller per poter essere riutilizzate dai Creator.

## UX della dashboard

### Generaimpresa

1. scegliere il Creator;
2. vedere Brand personali e Brand progetto;
3. aprire il ramo di un Brand;
4. scegliere il Node sul quale lavorare.

### Rails4Business

1. vedere i NodeProcess del Node;
2. aprire una catena;
3. vedere i prodotti in bozza, programmati, in lavorazione e conclusi;
4. aprire una DataExperience;
5. vedere la ricetta ordinata e l'intera cronologia del prodotto;
6. duplicare un prodotto precedente per crearne uno nuovo, quando utile.

### 1impegno

1. vedere chi ha assunto i Commitment;
2. assegnare gli Slot ancora liberi;
3. organizzare Session singole o condivise;
4. collocare il lavoro nel calendario;
5. rilevare prodotti senza responsabile, tempo o risorse.

La dashboard deve rispondere a quattro domande:

```text
Su quale progetto stiamo lavorando?
Quale prodotto stiamo realizzando?
A quale passaggio siamo arrivati?
Chi deve fare che cosa e quando?
```

## Piano di implementazione aggiornato

### Fase 1 — Consolidamento del dominio produttivo

- [x] aggiungere stato e date essenziali a `DataExperience`;
- [x] definire la relazione facoltativa uno a uno con `SkillProduct`;
- [x] definire il responsabile del `NodeProcess` e della DataExperience;
- [x] uniformare gradualmente il creatore su `Profile`;
- [x] adeguare `DataSession` per le sessioni condivise tra Experience;
- [x] aggiungere uno stato comune a DataSlot e DataSession;
- [x] creare il servizio che unisce e ordina Commitment, Slot e Session di una
      Experience;
- [ ] aggiungere validazioni e test per posizioni e collegamenti coerenti;
- [x] definire e testare la duplicazione controllata di una DataExperience;
- [ ] centralizzare le transizioni Experience/SkillProduct provocate dai
      Commitment `publish`, `update` e `fix`.

### Fase 2 — Primo caso produttivo reale

Usare un solo caso pilota:

```text
Creator: Mark Postura
Brand: PosturaCorretta
Node: canale o progetto contenuti
NodeProcess: produzione video YouTube
DataExperience: un singolo video
SkillProduct: contenuto o collegamento del video
```

- [ ] creare più prodotti programmati contemporaneamente;
- [ ] creare passaggi Commitment, Slot e Session ordinati;
- [ ] provare una Session che raccoglie gli Slot di registrazione di più video;
- [ ] concludere e pubblicare un prodotto;
- [ ] aggiungere un aggiornamento allo stesso prodotto;
- [ ] duplicare facoltativamente un prodotto precedente.

### Fase 3 — Dashboard superadmin in sola lettura

- [ ] creare rotta e controller `/admin/production`;
- [ ] portare il prototipo in ERB e CSS dell'app;
- [ ] usare presenter/query object invece di query nelle view;
- [ ] selezionare Creator, Brand, Node e NodeProcess;
- [ ] mostrare prodotti e passaggi reali senza inventare numeri;
- [ ] collegare ogni elemento alla relativa pagina amministrativa.

### Fase 4 — Operatività

- [ ] creare, spostare e riordinare i passaggi;
- [ ] trasformare un'attività prevista in Commitment, Slot o Session;
- [ ] assegnare persone e tempi;
- [ ] organizzare Session condivise;
- [ ] mostrare costi e quantità soltanto quando derivabili dai dati reali.

### Fase 5 — Apertura ai Creator

- [ ] estrarre autorizzazioni e query dal namespace superadmin;
- [ ] riutilizzare la vista nell'area Creator;
- [ ] consentire l'accesso soltanto ai Node amministrabili;
- [ ] proteggere calendari e informazioni personali estranee;
- [ ] mantenere al superadmin la vista trasversale della piattaforma.

## Cose da non fare nell'MVP

- non creare un secondo albero parallelo ai Node;
- non aggiungere `DataStep`, `NodeProcessStation` o `ProductionOutput` finché i
  tre tipi di passaggio e SkillProduct sono sufficienti;
- non obbligare ogni attività ad avere contemporaneamente Commitment, Slot e
  Session;
- non confondere una Session condivisa con la catena produttiva;
- non duplicare automaticamente ogni vecchia Experience;
- non contare gli aggiornamenti come nuovi prodotti;
- non mostrare costi stimati senza una fonte reale;
- non aprire ai Creator prima dei controlli di autorizzazione.

## Criteri di completamento dell'MVP

L'MVP è pronto quando il superadmin può:

1. scegliere un Brand e un Node;
2. aprire un NodeProcess;
3. vedere più prodotti aperti contemporaneamente;
4. aprire una DataExperience e leggerne i passaggi in ordine;
5. distinguere Commitment, Slot e Session;
6. raccogliere in una Session gli Slot appartenenti a prodotti differenti;
7. vedere responsabili, tempi e costi realmente disponibili;
8. collegare il prodotto al relativo SkillProduct;
9. aggiornare il prodotto aggiungendo passaggi alla stessa Experience;
10. duplicare un prodotto precedente soltanto quando è utile.
