# Architettura comune — contenuti, sessioni e servizi

> **Fonte di verità corrente.** Sostituisce per le decisioni future i modelli
> `DataEvent`, `EventFormat`, `Occurrence` e `Slot` precedenti. Non vengono
> create nuove tabelle finché YAML e viste non sono stati usati davvero.

Questo è il **documento tecnico principale che tiene le fila dello sviluppo**.
Le nuove decisioni operative vengono prima riportate qui e poi implementate un
passaggio alla volta.

I principi organizzativi, i tre canali e la divisione della settimana sono in
[PRINCIPI_FLOWPULSE_E_ORGANIZZAZIONE_SETTIMANALE.md](PRINCIPI_FLOWPULSE_E_ORGANIZZAZIONE_SETTIMANALE.md).

## Scopo

Tutti i brand possono usare la stessa struttura, mantenendo nav, CSS e parole
pubbliche proprie. Per ora si sviluppano solo due funzioni: contenuti gestiti
dai Creator e Session/Slot gestiti dagli Operator. Cycle e Service restano in
standby.

Il contenitore comune è `Node`: può essere dichiarato professional anche prima
dell'iscrizione e viene collegato successivamente al profilo tramite
`primary_node_id`; è Brand quando possiede Domain ed è comunque utilizzabile
come progetto. La gerarchia organizzativa usa `parent_node_id`;
la futura responsabilità professionale usa `professional_owner_node_id`, che
può puntare soltanto a un Node professional. Non si aggiungono ora relazioni
anticipate verso Content, Session o Slot.

## I due alberi

```text
EDITORIALE                         OPERATIVO
Percorso                           DataSession
└── Section                        └── DataSlot
    └── Corso                          └── DataCommitment
        └── Contenuto
```

L'editoriale risponde a **che cosa si legge, apprende o pratica**. La Session
risponde a **che cosa si svolge e come si colloca una persona**.

Il Week Plan viene prima dei due alberi: assegna spazi reali della settimana e
permette di verificare il ritmo di lavoro. Non è ancora una DataSession e non è
un contenuto, ma prepara il luogo in cui entrambi potranno essere programmati.

## 0. Week Plan YAML — prototipo in uso

MarkPostura carica un file per settimana da:

```text
config/data/markpostura/settimane/YYYY-Www.yml
```

Ogni voce richiede giorno, ora iniziale, ora finale e uno dei cinque `space`
ammessi dal catalogo MarkPostura. `title` e `location` specificano cosa si fa e
dove; se manca il titolo viene mostrato il nome dello spazio. Questa struttura
resta distinta dal futuro database di 1Impegno.

La vista è un calendario settimanale dalle 08:00 alle 22:00, ispirato al
prototipo `docs/private_prototypes/viste_html/6_weekplan.html`. Non presenta una
lista separata: colloca ogni voce YAML nel giorno e nell'orario corretti. Il
blocco apre un dettaglio in modale senza cambiare pagina.

La pagina dedicata usa parametri condivisibili:

```text
/markpostura/weekplan?week=2026-W38&spaces=postura-gruppo,postura-app
```

`week` identifica il file settimanale; `spaces` contiene una o più delle cinque
categorie selezionate. Soltanto il superadmin può aprire la sorgente YAML da
`/admin/markpostura/settimane/YYYY-Www`.

## 1. Albero editoriale e Creator

```text
Percorso → Section → Corso → Contenuto
```

- **Percorso**: file YAML e pagina indice della home; ordina le section e i
  corsi di un Brand.
- **Section**: raggruppamento editoriale di corsi coerenti.
- **Corso**: contenuto padre, con `format: course` o `format: masterclass`.
- **Contenuto**: unità editoriale con un tipo: `chapter`, `scheda`, `article`,
  `video`, `exercise`.

Un capitolo ha normalmente una scheda collegata. Gli esercizi semplici restano
nel corpo della scheda; diventano contenuti autonomi solo se riusabili o dotati
di istruzioni, video o varianti proprie.

Ogni contenuto ha un solo padre strutturale e ne eredita Brand e visibilità. Un
figlio può essere più ristretto, mai più pubblico. Per riusare un contenuto si
crea un **ponte** figlio del nuovo corso, con `link_content_id` verso
l'originale; il ponte non ha figli e non può ampliare la visibilità.

La funzione Contenuti è attivabile per Brand e affidata al ruolo `creator` nel
contesto di quel Brand. Il catalogo pubblico mostra contenuti datati, corsi e
masterclass; il Percorso resta invece l'indice YAML ordinato della home.

## 2. DataSession e DataSlot — primo nucleo di 1Impegno

```text
Operator / Brand
└── DataSession
    └── DataSlot
        └── DataCommitment
```

Uno Slot è una posizione dentro una Session, non un task per definizione:

- **slot contenuto**: link a scheda, capitolo, video o esercizio;
- **slot prenotazione**: appuntamento di un Contact/User;
- **slot operativo**: preparazione, coordinamento o chiusura;
- **slot task**: azione assegnata o tracciata, soltanto quando serve davvero.

Una Session di gruppo contiene più DataCommitment partecipanti e uno o più
slot contenuto. Una Session individuale seriale ha slot prenotazione in orari
successivi. Una Session individuale parallela potrà avere slot contemporanei
solo quando esistono operatori e risorse sufficienti.

La Session può essere mostrata al pubblico come lezione, incontro,
appuntamento o evento. Non serve un modello tecnico `Event` separato.

## 3. Operator e funzione nel Brand

`operator` abilita una persona a lavorare in Impegno nel contesto di un Brand.
`role_operator` ne definisce la funzione concreta.

```text
RoleAssignment
role: operator
role_operator: insegnante | professionista | segreteria | ...
context: Node del Brand
parent: ideatore del Brand
```

Ogni Brand possiede `operator_roles`, la propria lista di funzioni. Assigned
roles deve far scegliere: Brand → utente → operator → role_operator.
La stessa persona può avere più funzioni nello stesso Brand; l'unicità deve
includere `role_operator`.

Per il primo prototipo ogni DataSession/DataSlot ha un operatore responsabile e
eredita il Brand. In seguito si potranno aggiungere tutor, segreteria,
responsabile del luogo e altri operatori come assegnazioni multiple.

## 4. Catalogo e calendario pubblico

La pagina pubblica unica è **Contenuti ed eventi**, con filtri prossimi/passati:

- contenuti, corsi e masterclass usano la data editoriale;
- una DataSession pubblicata e datata appare come evento;
- bozze, contenuti privati e Session private restano a superadmin e addetti.

Un contenuto non è mai un evento. Una Session usa contenuti tramite i suoi
slot e può essere presentata come evento quando è pubblica e datata.

## 5. Cycle e Service — esplicitamente in standby

**Cycle** sarà una dima composta da Session e Slot, ad esempio un corso di
quattro lezioni, una formazione insegnanti o una produzione video. Si valuta
solo dopo il test delle Session YAML.

**Service** sarà la configurazione commerciale/organizzativa: prezzo,
capienza, luogo/online, operatori e prenotazione. Un prezzo su un contenuto
online non crea automaticamente un Service. Il Service verrà valutato solo
dopo Cycle e casi reali di partecipazione.

Quando verrà introdotto, Cycle descriverà anche i processi Rails4Business
applicati a un Brand: per esempio la produzione dei contenuti PosturaCorretta.
Il responsabile del processo e il responsabile editoriale del Brand possono
coincidere nella fase pilota, ma restano concetti distinti.

## Piano di lavoro — viste/YAML prima del database

1. **Operator — completato**: aggiunti `operator`, `role_operator` e
   `operator_roles` al Brand e aggiornati gli Assigned roles.
2. **Week Plan — in prova**: usare i file settimanali YAML su MarkPostura e
   correggere le cinque categorie, i luoghi e gli orari su casi reali.
3. **1Impegno — prossimo**: creare una single page/prototipo alimentata da YAML per
   `DataSession → DataSlot`, senza Cycle e Service.
4. **Creator e contenuti**: attivare per Brand la funzione contenuti; provare
   Corso → Contenuto con capitoli, schede ed esercizi.
5. **Percorso PosturaCorretta**: completare `percorso.yml` con Section e corsi
   collegati, come indice della home.
6. **Catalogo pubblico**: una vista datata Contenuti ed eventi con
   prossimi/passati, visibilità pubblica e privata.
7. **Test reale**: usare YAML e correggere il vocabolario.
8. **Solo dopo**: scegliere schema database, modelli, controller e migrazioni.

## Decisioni ancora aperte

- formato YAML esatto dei ponti e dei riferimenti DataSlot → Contenuto;
- campi minimi della single page DataSession/DataSlot;
- regole definitive per Session di gruppo, seriali e parallele;
- quando una Session datata genera o aggiorna un DataCommitment;
- campi del futuro Cycle e Service, dopo il pilota.
