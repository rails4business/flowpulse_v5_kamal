# Piano operativo FlowPulse

**Aggiornato al 14 ottobre 2026**

Questo è il documento principale per decidere **che cosa fare adesso**. Riunisce
le decisioni operative contenute negli appunti sull’autenticazione e
nell’architettura di contenuti, sessioni e servizi.

Gli approfondimenti tecnici restano disponibili in:

- [Autenticazione FlowPulse](update_authentication.md);
- [Architettura di contenuti, sessioni e servizi](ARCHITETTURA_CICLI_CONTENUTI_E_SERVIZI.md);
- [Architettura Brand, Node, Domain e Site](ARCHITETTURA_BRAND_NODE_DOMAIN_SITE.md);
- [Dashboard produttiva per Creator](2026-10-17-PIANO_DASHBOARD_PRODUTTIVA_CREATOR.md);
- [Audit AI e discovery pubblica](../architecture/flowpulse-ai-discovery-audit.md).

## Direzione generale

FlowPulse permette a una persona di costruire il proprio mondo attraverso
Brand, progetti, Skill, prodotti e attività reali. Il mondo mostrato oggi è
quello costruito da MarkPostura; altre persone potranno costruirne di nuovi e
collegarli tra loro.

Il lavoro procede su due binari distinti:

1. **fuori dalla piattaforma:** contenuti, corsi, percorsi, planning ed eventi
   da rendere realmente utilizzabili;
2. **dentro la piattaforma:** struttura tecnica comune che consente ai Brand
   di organizzare, pubblicare e collegare quelle risorse.

Il codice viene sviluppato partendo da un caso reale. Non si completa prima
l’intera piattaforma in astratto.

## Priorità corrente

```text
Planning settimanale
├─ routine personale e professionale
├─ tempo libero e margine
└─ obiettivo/problema della settimana
   ├─ sintesi MarkPostura
   ├─ sviluppo della piattaforma FlowPulse e delle Skill
   └─ contenuti del percorso PosturaCorretta
```

## 1. Planning settimanale

Il planning viene sistemato per primo perché stabilisce dove viene impiegato
il tempo. Non è un progetto aggiuntivo: è lo strumento con cui vengono
governati tutti i progetti senza sacrificare la vita quotidiana.

Il planning di MarkPostura va costruito a strati, in questo ordine.

### Le tre aree di Mark Postura

Ogni attività viene ricondotta a una di queste tre aree, senza creare un
calendario separato per ogni Brand:

1. **Salute** — educazione, cultura del corpo, PosturaCorretta e Percorso
   Integrato;
2. **Lavoro** — problemi, risorse, progetti, Rails4Business, GeneraImpresa,
   1Impegno e sviluppo di FlowPulse;
3. **Esplorazione** — stile di vita, natura, arte, musica, spiritualità e ciò
   che merita di essere conosciuto prima di diventare un progetto definito.

Le tre aree servono a leggere la vita e il lavoro di Mark, non obbligano a
portarle avanti tutte nello stesso giorno. Si sceglie un fuoco principale e
si lasciano visibili le altre due senza riempirle artificialmente.

### Avvio del planning

**Mercoledì 14 ottobre 2026 — Salute**

- area: **Salute**;
- tema: **educazione alla salute e al corpo**;
- Brand da osservare insieme: **PosturaCorretta.org** e
  **PercorsoIntegrato.it**;
- risultato della giornata: chiarire che cosa insegna PosturaCorretta e come
  Percorso Integrato accompagna la persona quando serve il lavoro dei
  professionisti;
- da non aggiungere per ora: orari, lezioni prenotabili, eventi o nuove
  funzioni tecniche non necessarie a questa distinzione.

Questo è il primo blocco reale del planning. Alla fine della giornata si
registra ciò che è stato chiarito e si decide il passo successivo, senza
compilare in anticipo il resto della settimana.

### 1. Routine fissa

- **mattina:** circa mezz’ora di attività personale;
- **pomeriggio:** gruppi PosturaCorretta, anche sui campi da rugby e da padel,
  quando vengono programmati;
- **sera:** spazio riservato ai pazienti;
- spostamenti, preparazione e recupero vanno considerati come tempo reale e
  non nascosti tra un appuntamento e l’altro.

Questa è la base ricorrente. Gli orari e i giorni precisi verranno definiti
nel calendario reale, senza inventarli nel piano progettuale.

### 2. Tempo libero e margine

Il tempo libero va inserito prima dei nuovi progetti. Comprende riposo,
relazioni, musica, esplorazione e spazi non programmati. Va lasciato anche un
margine tra le attività, così un ritardo o un imprevisto non fa saltare tutta
la settimana.

Uno spazio breve e ricorrente va riservato al planning: serve a osservare la
settimana, non a trasformare anche il tempo libero in lavoro.

### 3. Un obiettivo o problema principale

Nello spazio rimasto si sceglie **un solo obiettivo/problema principale**. Il
metodo appartiene a Rails4Business: il problema può riguardare la piattaforma,
un contenuto, un percorso oppure un’attività reale, ma deve essere abbastanza
piccolo da poter avanzare e arrivare a una verifica.

Rails4Business non è quindi soltanto una delle attività da infilare nel
planning: è il punto da cui parte la scelta. Prima si scrive il problema o
l’obiettivo, poi si decide in quale progetto intervenire.

### Coda attuale dei lavori

Le linee di lavoro non devono procedere tutte insieme. Restano visibili in
questa coda e, ogni settimana, se ne porta avanti principalmente una:

1. **Rails4Business:** scegliere e definire l’obiettivo o il problema da
   risolvere;
2. **FlowPulse:** proseguire con la piattaforma, implementando una Skill o un
   collegamento reale alla volta;
3. **MarkPostura:** creare il contenuto che spiega filosofia e pratica nei
   diversi ambiti;
4. **PosturaCorretta:** riempire progressivamente il percorso con contenuti
   realmente utilizzabili;
5. **educazione e percorso:** collegare in seguito lezioni, insegnanti,
   utenti e Percorso Integrato;
6. **attività reali:** organizzare gruppi, giornate ed eventi soltanto quando
   il pezzo necessario del percorso è pronto.

Se il problema scelto richiede FlowPulse, quella settimana il risultato può
essere tecnico. Se riguarda un capitolo PosturaCorretta, la piattaforma viene
toccata soltanto per quanto serve a pubblicare e usare quel capitolo. In
questo modo il planning non diventa un elenco infinito di cose iniziate.

Ogni settimana:

1. riportare per prime routine, pazienti, gruppi e appuntamenti già fissati;
2. proteggere tempo libero, recupero e margini;
3. scegliere un solo obiettivo/problema principale;
4. indicare il Node interessato;
5. definire un risultato verificabile per quella settimana;
6. creare soltanto i DataCommitment necessari;
7. concludere, correggere oppure rimandare consapevolmente;
8. scegliere soltanto dopo il problema successivo.

Il Week Plan deve mostrare gli impegni reali senza confondere il materiale da
produrre con il tempo destinato a produrlo. Deve inoltre rendere evidente
quando la settimana è già piena: in quel caso non si aggiunge un nuovo
progetto.

### Scheda minima della settimana

```text
Settimana:

Routine già fissata
- attività personale del mattino:
- gruppi PosturaCorretta del pomeriggio:
- pazienti della sera:
- altri appuntamenti e spostamenti:

Spazio protetto
- tempo libero:
- recupero e margine:
- momento in cui rivedere il planning:

Fuoco della settimana
- obiettivo o problema:
- Node / Brand interessato:
- risultato piccolo e verificabile:
- blocchi di lavoro realmente disponibili:
- cosa non verrà affrontato questa settimana:

Chiusura
- concluso:
- da correggere:
- da rimandare:
- prossimo passo possibile:
```

La scheda non assegna automaticamente un progetto a ogni giorno. Prima si
osserva quanto tempo rimane davvero; soltanto dopo si collocano uno o più
blocchi dedicati al fuoco della settimana.

### Ritmo settimanale da provare

Senza stabilire ancora giorni e orari definitivi, la settimana può essere
composta da questi blocchi:

- un momento breve per preparare o correggere il planning;
- attività personale di circa mezz’ora al mattino;
- uno o più blocchi concentrati sul problema principale;
- pomeriggi destinati ai gruppi PosturaCorretta quando sono programmati;
- sere riservate ai pazienti;
- almeno uno spazio libero vero, non usato per recuperare automaticamente il
  lavoro rimasto indietro;
- un breve controllo finale per chiudere, correggere o rimandare il problema.

Il planning definitivo dovrà essere steso partendo dagli appuntamenti reali
e dagli orari disponibili. Questa struttura indica le priorità, ma non
inventa un calendario prima di conoscere quei vincoli.

## 2. MarkPostura: rendere leggibile la visione

La pagina MarkPostura deve presentare l’indole di Mark e far capire come una
stessa filosofia diventa pratica in ambiti diversi. La sintesi e il planning
usano le stesse tre aree, così la presentazione pubblica e l'organizzazione
personale non raccontano due sistemi diversi.

### Salute: educazione e percorso

- PosturaCorretta;
- Percorso Integrato;
- educazione alla salute e cultura del corpo;
- lezioni, insegnanti e utenti;
- un percorso della salute costruito con il benessere integrato e con più
  professionisti quando serve.

### Lavoro: problemi e risorse

- Rails4Business: partire da un obiettivo o da un problema, cercare le risorse
  e costruire una soluzione verificabile;
- GeneraImpresa: dall’idea al Brand e ai progetti;
- 1Impegno: tempo, attività, richieste e decisioni reali.

### Esplorazione della mente e dell’ambiente

- Il Giardino del Corpo;
- stile di vita, natura, arte, musica, esperienza e ricerca;
- ciò che non è ancora pienamente riconosciuto o standardizzato;
- ciò che può fare paura perché si trova oltre il cancello e dietro la siepe;
- il corpo e l’essere umano osservati come un giardino da conoscere e curare.

In questa area rientra anche **Canta che ti passa**: canto, fisarmonica e le
altre attività artistiche sono esperienze di esplorazione e armonia, non una
quarta categoria da mantenere separata.

FlowPulse viene presentato alla fine come l’ecosistema che permette di
costruire e collegare questi mondi. Per ora servono un’introduzione chiara, le
tre aree e uno schema comprensibile; non è necessario rifare ogni
dettaglio della pagina.

## 3. PosturaCorretta come progetto pilota

PosturaCorretta è il primo caso con cui verificare l’intera catena:

```text
Contenuti
→ Corso
→ Percorso
→ Planning delle lezioni
→ Eventi
```

Il primo risultato non è avere tutto il catalogo pronto. È rendere completo
un piccolo percorso reale:

- capitoli ordinati;
- approvazione editoriale;
- pubblicazione;
- accesso allo show;
- avanzamento dell’utente;
- appartenenza al corso;
- appartenenza al percorso.

Le lezioni prenotabili e gli eventi vengono dopo che contenuto, corso e
percorso sono stabili.

## 4. Skill Contenuti

La prossima priorità tecnica è completare la Skill Contenuti, perché potrà
essere utilizzata da quasi tutti i Brand.

```text
Node
└── ReusableSkillNode: Contenuti
    └── SkillProduct
        ├── file Markdown o dati editoriali
        ├── autore e Node produttore
        ├── stato e visibilità
        ├── URL pubblico e canonical
        └── DataCommitment editoriale
```

Il primo test va fatto con un solo capitolo:

`inizia-benefici-postura-corretta`

Il capitolo continua a funzionare con il suo `content_key` durante la
transizione. Quando diventa uno SkillProduct, il DataCommitment editoriale si
collega direttamente al prodotto.

### Stato attuale dell’approvazione

- il pulsante `＋ DataCommitment` apre un form editoriale breve;
- la decisione viene registrata come completata;
- un DataCommitment pianificato con `publish_on_completion` applica la
  pubblicazione, l'aggiornamento, il ritiro o l'archiviazione quando viene
  concluso;
- se esistono più DataCommitment per lo stesso contenuto, determina lo stato
  corrente l'ultima decisione editoriale conclusa; le precedenti rimangono
  nello storico;
- pubblicazione, visibilità e accesso restano campi distinti;
- l’approvazione non occupa una fascia del calendario;
- `content_key` e pagina d’origine restano disponibili finché il contenuto non
  è stato trasformato in SkillProduct.

## 5. Corso e percorso

Il contenuto descrive ciò che viene letto, imparato o praticato. Il corso
ordina più contenuti. Il percorso collega corsi, attività e progressione della
persona.

```text
SkillProduct = ciò che esiste ed è riutilizzabile
DataCommitment = ciò che una persona decide, approva o svolge
```

Il diario di Percorso Integrato registra esecuzioni, osservazioni e feedback;
non coincide con il calendario. Quando una voce del programma viene collocata
nel tempo, si collega a un DataCommitment di 1Impegno.

## 6. 1Impegno, sessioni e slot

1Impegno è uno strumento trasversale, non una Skill.

Rails4Business gestisce le Skill. Una Skill attivata su un Node produce uno o
più SkillProduct. 1Impegno permette di programmare, svolgere e registrare il
lavoro relativo a quei prodotti.

```text
Node
└── ReusableSkillNode
    └── SkillProduct
        ├── DataSession
        │   ├── DataSlot
        │   └── DataCommitment
        └── DataCommitment diretto
```

- `DataSession`: quando avviene una lezione, attività o evento;
- `DataSlot`: fascia, disponibilità, posto o scelta prenotabile;
- `DataCommitment`: decisione, partecipazione o tempo assunto da una persona.

Questi record possono esistere anche senza SkillProduct per attività
personali, richieste, impegni generici e dati storici.

## 7. Lezioni ed eventi

Quando contenuti, corso e percorso funzionano:

1. creare la DataSession della lezione o dell’evento;
2. aggiungere DataSlot soltanto quando servono disponibilità o posti;
3. collegare i DataCommitment di insegnanti, operatori e partecipanti;
4. mostrare le attività nel planning e nella dashboard corretta;
5. aggiungere in seguito servizi e condizioni economiche.

Non si anticipano ora pagamenti, abbonamenti completi o automazioni delle
prenotazioni.

## 8. Autenticazione comune

L’identità è globale; l’accesso appartiene al Brand.

```text
User
└── Profile
    └── BrandAccess
        └── Session
```

- Domain e lingua non creano una seconda autorizzazione;
- la password appartiene allo User;
- una persona entra nel Brand tramite invito e BrandAccess;
- 1Impegno e le Skill lavorano nel contesto del Brand chiamante;
- aprire l’agenda da PosturaCorretta non richiede un secondo accesso a
  1impegno.it;
- Resend resta rinviato finché gli inviti vengono consegnati manualmente.

## 9. Base tecnica della piattaforma

Dopo il primo ciclo completo di PosturaCorretta:

1. verificare il flusso reale di invito, accesso, logout e revoca;
2. completare la Skill Contenuti e la sua proiezione pubblica;
3. uniformare per i Domain nav, CSS, favicon, canonical, sitemap, robots,
   JSON-LD, PageSpeed e accesso pubblico alle informazioni;
4. esporre nelle API soltanto Node e SkillProduct pubblicati e pubblici;
5. aggiungere progressivamente corsi, percorsi, luoghi, servizi ed eventi;
6. valutare MCP soltanto quando API e permessi sono stabili.

Le informazioni pubblicamente visibili senza iscrizione possono essere
ricercate da motori e AI. Calendari personali, richieste, programmi sanitari,
diari e dati privati non entrano nella discovery pubblica.

## 10. Estensione agli altri Brand

Dopo la validazione su PosturaCorretta, lo stesso contratto viene esteso in
questo ordine:

1. Percorso Integrato;
2. Rails4Business;
3. GeneraImpresa;
4. 1Impegno;
5. Il Giardino del Corpo;
6. gli altri Brand e progetti.

## Prossima azione

La prossima unità di lavoro è:

> trasformare `inizia-benefici-postura-corretta` nel primo prodotto reale
> della Skill Contenuti, mantenendo il file Markdown come fonte e collegando
> allo SkillProduct la decisione editoriale già registrabile tramite
> DataCommitment.

Il passaggio è concluso soltanto quando il capitolo può essere identificato,
approvato, pubblicato, aperto pubblicamente e recuperato dalla proiezione del
proprio Domain.

## Cose rinviate

- automazione completa delle prenotazioni;
- pagamenti e abbonamenti;
- verifica email automatica con Resend;
- migrazione contemporanea di tutti i contenuti;
- completamento di tutte le Skill prima del primo caso reale;
- MCP prima della stabilizzazione delle API;
- funzioni avanzate per tutti i ruoli amministrativi.
