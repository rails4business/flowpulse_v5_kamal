# Revisione vista Esperienze — 1Impegno

Riferimento visivo da ricostruire:

- `docs/private_prototypes/viste_html/0_dataevent_show.html`
- vista reale: `/impegno/esperienze/:id`

Obiettivo: una singola pagina leggibile per costruire e consultare un'esperienza, senza introdurre livelli artificiali nel database.

## Registro correzioni

Per ogni punto annotare una riga nel formato: `pagina / vista / cosa si vede / cosa deve succedere / esempio`.

### Risolte

- [x] `Esperienze → Lista` raccoglie Sessioni, Slot e Impegni, con o senza data.
- [x] La tabella usa le colonne `Tipo`, `Nome`, `Inizio`, `Fine`; gli elementi senza data mostrano `—`.
- [x] Corretta la chiusura HTML che lasciava la tabella `Lista` fuori dal controller delle tab e quindi invisibile al clic.
- [x] La vista è richiamabile dall'URL con `?vista=giorni` oppure `?vista=lista`; il cambio tab aggiorna il parametro senza ricaricare la pagina.
- [x] In modifica, ogni Giorno segue la gerarchia: `+ Sessione` prima delle Sessioni; in ogni Sessione `+ Slot` prima degli Slot; sotto ogni Slot `+ Commitment`. Non esistono scorciatoie dirette tra i livelli nella vista Giorni.
- [x] Quando `Modifica` è attivo, il clic su Esperienza, Sessione, Slot o Commitment apre un unico modal precompilato. Il salvataggio aggiorna titolo e dati specifici del livello; per i Commitment aggiorna anche lo stato.
- [x] Il `+ Slot` di una Sessione precompila il giorno e l'orario: parte dall'inizio della Sessione oppure dalla fine dell'ultimo Slot; propone la fine della Sessione quando è successiva.
- [x] La modalità modifica viene conservata nell'URL con `?modifica=1` e ripristinata dopo refresh o salvataggio.
- [x] Rimossa la struttura nativa `details/summary`: freccia e titolo della Sessione condividono ora una riga `flex`, identica a quella del Giorno e al prototipo.
- [x] Sessione, Slot e Commitment hanno `position`: con le date prevale `starts_at`, senza date prevale l'ordine manuale. Il riordino drag & drop resta successivo.
- [x] Esperienze è una sottovista dell’Agenda di 1Impegno, senza diventare una quarta area principale accanto ad Agenda, Luoghi e Contatti.
- [x] Il Weekplan legge anche le Sessioni programmate delle Esperienze, oltre ai Commitment personali.
- [x] Il pulsante `Registra` può creare un Commitment diretto nell’Esperienza e avviarne subito il tempo effettivo.
- [x] Sessioni e Commitment collegati presenti nel Weekplan aprono lo show dell’Esperienza.

## Struttura decisa

```text
DataExperience (Esperienza)
├── DataCommitment diretto
├── DataSlot diretto
└── DataSession
    ├── DataCommitment della Sessione
    └── DataSlot
        └── DataCommitment dello Slot
```

`Day` **non è un record**: è un raggruppamento calcolato dagli `starts_at` degli Slot che appartengono a una Sessione.

### Regola delle date e della matriosca

- Esperienza, Sessione, Slot e DataCommitment possono nascere come **bozze senza date**.
- Quando un elemento viene programmato, riceve `starts_at` e `ends_at`.
- Si può iniziare dalla matriosca più piccola: un DataCommitment diretto o uno Slot diretto.
- Creando un contenitore superiore, gli elementi esistenti potranno essere spostati al suo interno: Commitment → Slot → Sessione.
- Non si inseriscono date fittizie automatiche.

## Cosa è già disponibile

- Esperienza: titolo e descrizione.
- Sessione: titolo, sempre collegata a un'Esperienza.
- Slot: titolo, inizio e fine opzionali; può appartenere direttamente all'Esperienza oppure a una Sessione.
- DataCommitment: può appartenere direttamente all'Esperienza, a una Sessione o a uno Slot.
- Lo show raggruppa gli Slot datati in `Day → Sessione → Slot`.
- La vista `Lista` mostra tutti gli elementi come tabella: tipo, nome, inizio e fine.
- Sessioni, Slot e Impegni senza data restano nello stesso registro e mostrano `—` negli orari.
- Il pulsante `+` apre il modal già impostato sul tipo e sul contenitore richiesti.

## Cosa non è ancora a posto

### 1. Fedeltà al prototipo

- Confrontare a video ogni distanza: header, riga Day, riga Sessione, riga Slot, linee verticali e margini.
- Verificare se il `+` deve stare nell'header, come ora, oppure apparire solo in modalità modifica.
- Decidere se il collegamento `← Esperienze / Apri agenda` deve restare sopra al pannello: non è nel prototipo originario.
- Uniformare stato chiuso/aperto di Day e Sessioni con il comportamento desiderato.

### Separazione delle due letture

- Sopra: solo elementi con data, raggruppati in `Day`.
- La seconda vista, `Lista`, è il registro completo dell'Esperienza: Sessioni, Slot e Impegni programmati o ancora senza data.
- Dentro un Day: prima le Sessioni con i loro Slot; se non esiste una Sessione, elenco diretto di Slot o Impegni.
- Non esiste una seconda sezione `Da organizzare`: gli elementi senza data sono riconoscibili dai valori `—` nella tabella.

### 2. Elementi senza collocazione

- Uno Slot diretto con data compare nel Day come elemento programmato, anche senza Sessione.
- Una Sessione senza Slot deve avere solo il titolo oppure un'indicazione esplicita che mancano gli Slot?
- Gli Impegni diretti dell'Esperienza devono restare in fondo oppure diventare una riga dell'albero principale?

### 3. Creazione e modifica

- Il modal oggi crea elementi **diretti sull'Esperienza**.
- Da definire come aggiungere un elemento dentro una Sessione o dentro uno Slot: icona `+` sulla riga, menu contestuale o modalità modifica.
- Da definire la modifica inline: titolo, descrizione, date e orari devono poter essere cambiati nella stessa pagina.
- Da definire se eliminazione e riordino servono già nel pilota.

### 4. Dati minimi e controlli

- Validare `ends_at > starts_at` per DataSlot.
- Decidere se Sessione può avere inizio/fine propri o se gli orari derivano sempre dagli Slot.
- Mostrare DataCommitment della Sessione accanto alla Sessione oppure in una sezione espandibile.
- Definire il significato visivo del pallino di un DataCommitment: pianificato, in corso, fatto, annullato.

### 5. Partecipanti e ruoli

- Oggi gli avatar mostrano i `DataCommitment` collegati allo Slot.
- Da definire come aggiungere una persona, un contatto o un operatore come partecipante.
- Da definire quando un DataCommitment è un'attività personale e quando è una partecipazione.
- Non introdurre ancora Service, Cycle, capienza, pagamenti o ruoli operativi nella vista pilota.

### 6. Calendario e uso futuro

- Il Weekplan legge già le Sessioni programmate e i Commitment personali. L’eventuale rappresentazione autonoma degli Slot resta da decidere dopo l’uso del pilota.
- Una Sessione editoriale, una lezione, una masterclass e una registrazione video useranno la stessa struttura.
- Cycle e Service restano fuori da questa fase; saranno aggiunti solo dopo aver validato questo flusso.

## Ordine consigliato

1. Confrontare e rifinire **solo lo show** rispetto al prototipo.
2. Definire il comportamento di Slot e Impegni diretti.
3. Aggiungere la creazione contestuale nei punti giusti dell'albero.
4. Aggiungere modifica inline e date/orari.
5. Collegare gli Slot al calendario settimanale.
