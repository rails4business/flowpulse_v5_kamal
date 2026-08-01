# Impegno, eventi e integrazione con i brand

## Obiettivo

Costruire progressivamente in Flowpulse le funzioni di agenda, eventi, prenotazioni, contatti e luoghi, mantenendo una separazione chiara tra:

- **Impegno**, che possiede dati e logica operativa;
- **PosturaCorretta**, che presenta al pubblico i propri contenuti e usa le funzioni di Impegno;
- gli altri brand, che in futuro potranno usare lo stesso sistema;
- una possibile applicazione Impegno autonoma, estraibile dal monolite quando sarà utile.

Il prototipo [1Impegno](../public/viste_html/18-00-14-7-2026-1impegno.html) resta il riferimento per la UX. Non deve diventare direttamente l'applicazione definitiva: le sue sezioni vanno implementate una alla volta con modelli, controller, viste e test Rails.

## Principi già decisi

1. `DataCommitment` è il singolo elemento che occupa un calendario.
2. Un evento non è un commitment: è un contenitore dal quale possono derivare uno o più commitment.
3. Evento e slot sono modelli distinti.
4. Gli stati e le modalità si rappresentano con valori enumerati, non con una serie di booleani.
5. Contatti e luoghi appartengono a Impegno e sono riutilizzabili da più brand.
6. Il proprietario determina responsabilità e permessi; il contatto e il luogo determinano le informazioni mostrate.
7. Il dominio e il brand costituiscono il contesto: PosturaCorretta deve vedere per impostazione predefinita soltanto i propri dati.
8. La logica di calendario, prenotazione e iscrizione non deve essere duplicata nei controller PosturaCorretta.
9. L'architettura deve funzionare oggi nel monolite e permettere domani di separare Impegno e PosturaCorretta.

## Stato attuale

Il modello canonico è `Brands::Impegno::Commitment`, salvato nella tabella `data_commitments`. L'alias `DataCommitment` mantiene la compatibilità con il codice esistente.

Sono già disponibili, tra gli altri:

- proprietario (`profile_id`);
- autore della registrazione (`created_by_profile_id`);
- assegnatario e responsabile;
- dominio;
- calendario di appartenenza (`calendar_key`, `calendar_label`);
- inizio e fine previsti;
- inizio e fine effettivi;
- stato, tipo, valorizzazione oraria o fissa;
- luogo testuale e URL online;
- soggetto polimorfico;
- metadati JSONB;
- contesto GeneraImpresa JSONB;
- controllo delle sovrapposizioni sullo stesso calendario;
- timer per iniziare e concludere un'attività.

Le pagine esistenti sono:

- `/impegni`, agenda generale privata dell'utente;
- `/posturacorretta/impegno`, agenda filtrata sul dominio PosturaCorretta;
- pagine progetto che registrano attività GeneraImpresa come commitment.

## Modello concettuale

```text
Profile
├── possiede Contact e Place predefiniti
├── possiede uno o più calendari
└── crea o riceve DataCommitment

Event
├── owner_profile
├── organizer_contact
├── default_place
├── domain / brand
├── regole di partecipazione
└── EventSlot (uno o più)
    └── DataCommitment (adesione o lavoro nel calendario)
```

## Event

L'evento descrive l'iniziativa, non la singola presenza in calendario.

Campi iniziali proposti:

```text
id UUID pubblico
title
slug
description
owner_profile_id
organizer_contact_id
place_id
domain_id
status
participation_mode
registration_mode
pricing_mode
price_cents
registration_deadline
minimum_participants
maximum_participants
published_at
metadata JSONB
```

Valori iniziali:

```text
status: draft, published, cancelled, completed
participation_mode: group, individual
registration_mode: none, required
pricing_mode: free, paid
```

`minimum_participants` deve essere facoltativo. Un evento può quindi essere pubblicato senza una soglia minima.

## EventSlot

Lo slot rappresenta una concreta disponibilità temporale dell'evento.

Campi iniziali proposti:

```text
id UUID pubblico
event_id
starts_at
ends_at
capacity
status
place_id facoltativo
online_url facoltativo
metadata JSONB
```

Valori iniziali dello stato:

```text
available, full, cancelled, completed
```

Un evento di gruppo può avere un solo slot con capienza maggiore di uno. Un evento con appuntamenti individuali può avere molti slot con capienza pari a uno.

## DataCommitment e prenotazioni

`DataCommitment` resta il record presente nel calendario personale. Per collegarlo agli eventi sono previsti:

```text
event_id facoltativo
event_slot_id facoltativo
commitment_role
booking_status
```

Valori iniziali:

```text
commitment_role: participant, organizer, worker, supervisor
booking_status: pending, confirmed, cancelled
```

Prima dell'implementazione va verificato se mantenere i due riferimenti espliciti oppure usare il `subject` polimorfico già presente per uno dei collegamenti. La scelta deve rendere semplici le query su iscritti, capienza e calendario, senza duplicare la fonte di verità.

Quando una persona si iscrive:

1. seleziona uno slot;
2. viene verificata la disponibilità;
3. viene creato un commitment nel suo calendario;
4. il commitment mantiene ruolo e stato della prenotazione;
5. i posti disponibili vengono calcolati dalle prenotazioni confermate, non salvati come contatore indipendente.

## Contact

Un contatto identifica una persona oppure un'organizzazione. Deve poter essere usato in più contesti senza duplicazioni.

Esempi di ruoli contestuali:

- professionista;
- insegnante;
- partecipante;
- organizzatore;
- collaboratore;
- partner;
- fornitore;
- cliente.

Il collegamento al contesto non va codificato in una stringa rigida come `posturacorretta_percorso_professionista`. Va rappresentato separando:

```text
contact_id
domain_id
brand_key
area_key
category_key
```

Esempio:

```text
Brand: PosturaCorretta
Area: Percorso
Categoria: Professionista
```

## Place

Un luogo può rappresentare:

- una sede fisica;
- uno studio;
- un punto di ritrovo;
- uno spazio appartenente a un'organizzazione;
- una sede online.

Un profilo può avere un contatto pubblico e un luogo predefiniti. Alla creazione dell'evento questi vengono proposti automaticamente, ma restano modificabili.

Per gli eventi pubblicati è opportuno conservare uno snapshot delle informazioni pubbliche essenziali, per evitare che la modifica successiva di un contatto o indirizzo alteri accidentalmente un evento già comunicato.

## Proprietario, organizzatore e luogo

I ruoli non vanno confusi:

- `owner_profile_id`: permessi, proprietà e responsabilità del record;
- `organizer_contact_id`: referente mostrato al pubblico;
- `place_id`: luogo utilizzato dall'evento;
- `created_by_profile_id`: persona che ha materialmente creato il record, utile anche per deleghe future.

Come impostazione iniziale, contatto e luogo vengono presi dal proprietario dell'evento.

## Confini applicativi

### Impegno

Impegno possiede:

- agenda e timer;
- commitment;
- eventi e slot;
- iscrizioni e prenotazioni;
- contatti;
- luoghi;
- routine, percorsi e corsi che generano commitment;
- regole di disponibilità e sovrapposizione.

### PosturaCorretta

PosturaCorretta:

- mostra gli eventi pubblicati del proprio dominio;
- applica identità visiva, contenuti e categorie PosturaCorretta;
- permette di iniziare una richiesta di iscrizione;
- mostra luogo e contatto pubblico dell'organizzatore;
- usa Impegno per calendario, disponibilità e registrazione.

La pagina `/posturacorretta/eventi` è quindi un client pubblico dei dati gestiti da Impegno.

## Organizzazione nel monolite

Struttura proposta:

```text
app/controllers/brands/impegno/
├── commitments_controller.rb
├── events_controller.rb
├── event_slots_controller.rb
├── contacts_controller.rb
└── places_controller.rb

app/controllers/brands/posturacorretta/
└── events_controller.rb

app/views/brands/impegno/
├── commitments/
├── events/
├── contacts/
└── places/

app/views/brands/posturacorretta/
└── events/
```

I modelli possono restare condivisi, con namespace coerenti e tabelle neutrali. I controller PosturaCorretta devono interrogare servizi o query Impegno e limitarsi alla presentazione del proprio dominio.

## Possibile separazione futura

```text
PosturaCorretta
      │
      │ API autenticata
      ▼
Impegno
```

Per non ostacolare l'estrazione futura:

- usare UUID pubblici per eventi e slot;
- non esporre gli ID numerici nelle integrazioni;
- isolare query e operazioni in servizi con responsabilità chiare;
- evitare riferimenti a classi PosturaCorretta nei modelli Impegno;
- mantenere dominio e brand espliciti;
- distinguere dati pubblici e dati privati;
- progettare autorizzazioni sul proprietario e non sul controller chiamante.

Non è necessario creare subito due applicazioni o un'API HTTP interna: finché tutto vive nel monolite, una chiamata Ruby diretta è più semplice. Il confine logico deve però essere rispettato.

## Piano di implementazione

### Fase 1 — Consolidare l'agenda esistente

**Stato: completata il 1 agosto 2026.**

- verificare i flussi reali di creazione, modifica, avvio, conclusione ed eliminazione;
- rendere sempre visibili data, ora di inizio e ora di fine;
- confermare il comportamento delle sovrapposizioni e delle deleghe;
- mantenere separati calendario generale e calendario filtrato per brand;
- aggiungere test sui principali casi utente.

**Risultato:** `DataCommitment` diventa una base stabile sulla quale collegare gli eventi.

Verifica conclusa senza migrazioni o modifiche distruttive. Sono coperti da test: alias e namespace, registrazione ordinaria e GeneraImpresa, inizio e conclusione del timer, modifica ed eliminazione, durata e valorizzazione, chiusura manuale degli step, filtro privato PosturaCorretta, orari, sovrapposizioni e calendari delegati. Il controllo dei timer è stato corretto affinché operi sul singolo `calendar_key`: due timer non possono convivere sullo stesso calendario, mentre calendari supervisionati distinti possono essere attivi contemporaneamente.

### Fase 2 — Event minimo

- migration e modello `Event`;
- UUID pubblico e slug;
- proprietario, dominio, contatto e luogo;
- stati bozza, pubblicato, annullato e concluso;
- modalità gruppo o individuale;
- iscrizione libera oppure richiesta;
- gratuito oppure a pagamento;
- CRUD riservato inizialmente al superadmin;
- test di modello, autorizzazione e dominio.

**Risultato:** un evento può essere creato e pubblicato, ma non è ancora prenotabile.

### Fase 3 — EventSlot

- migration e modello `EventSlot`;
- data, ora iniziale e finale;
- capienza e stato;
- luogo o URL specifici opzionali;
- gestione di uno o più slot dalla pagina evento;
- test su intervalli, capienza e cancellazione.

**Risultato:** ogni evento dispone delle proprie date concrete.

### Fase 4 — Collegamento ai commitment

- collegare `DataCommitment` a evento e slot;
- aggiungere ruolo e stato di prenotazione;
- creare un commitment quando una persona aderisce;
- impedire prenotazioni oltre la capienza;
- applicare le regole di sovrapposizione al calendario corretto;
- gestire cancellazione e liberazione del posto.

**Risultato:** iscrizioni e appuntamenti compaiono nell'agenda personale.

### Fase 5 — Pagina pubblica PosturaCorretta

- alimentare `/posturacorretta/eventi` dai record pubblicati;
- filtrare per dominio PosturaCorretta;
- mostrare organizzatore, luogo, date, disponibilità e prezzo;
- collegare l'azione di adesione a Impegno;
- mantenere branding e SEO di PosturaCorretta.

**Risultato:** PosturaCorretta utilizza il motore eventi di Impegno senza duplicarlo.

### Fase 6 — Contatti e luoghi

- introdurre `Contact` e `Place`;
- aggiungere contatto e luogo predefiniti del profilo;
- implementare i collegamenti a brand, area e categoria;
- migrare gradualmente i campi testuali dei commitment;
- aggiungere filtri contestuali, per esempio PosturaCorretta → Percorso → Professionisti;
- mantenere la possibilità di visualizzare tutti i dati personali in Impegno.

**Risultato:** contatti e luoghi diventano riutilizzabili da eventi, percorsi e altri brand.

### Fase 7 — Programmi

- routine che generano commitment ricorrenti;
- percorsi che generano tappe e appuntamenti;
- corsi che generano lezioni e incontri;
- associazione a eventi, servizi e professionisti;
- gestione delle modifiche senza perdere lo storico.

**Risultato:** la sezione Programmi del prototipo viene collegata al database.

### Fase 8 — Pagamenti e automazioni

- scadenza iscrizioni;
- eventuale soglia minima;
- raccolta pagamenti;
- annullamento e comunicazioni;
- pagamenti ricorrenti;
- notifiche e promemoria.

Questa fase va affrontata soltanto dopo che eventi, slot e prenotazioni sono stabili.

## Primo passo da affrontare

La Fase 1 è completata. Il prossimo intervento consigliato è **Fase 2 — Event minimo**.

La verifica di `DataCommitment` ha incluso:

1. inventario dei campi e dei flussi già presenti;
2. test di creazione con inizio e fine;
3. test del timer e calcolo della durata finale;
4. test delle sovrapposizioni per calendario proprio, delegato e supervisionato;
5. test del filtro generale/PosturaCorretta;
6. correzione delle sole lacune necessarie.

La Fase 2 può ora iniziare con migration e modello `Event` senza portarsi dietro ambiguità sul calendario.

## Decisioni da rimandare

Non servono ancora per iniziare:

- provider di pagamento;
- biglietti e fiscalità;
- lista d'attesa;
- notifiche email o WhatsApp automatiche;
- eventi con sessioni complesse;
- API pubblica;
- estrazione in due repository;
- sincronizzazione con calendari esterni;
- contatori materializzati dei posti disponibili.

Vanno introdotti soltanto quando un caso reale li richiede.

## Criteri di completamento

Ogni fase è conclusa quando:

- dispone di test di modello e richiesta adeguati;
- rispetta dominio, proprietario e autorizzazioni;
- non duplica la logica in PosturaCorretta;
- funziona sia nel calendario generale sia nel contesto del brand;
- mantiene compatibili i dati esistenti;
- aggiorna questo documento con le decisioni effettivamente implementate.
