# Piano Educazione, linee, offerte e percorso insegnante

## Struttura confermata (12 novembre 2026)

```text
PosturaCorretta  ⇄ ponte ⇄ Percorso Integrato
├─ 2. Educazione 1 · Come si esprime il corpo
│  ├─ 1. La prima settimana con PosturaCorretta      → linea Postura e recupero + 3 offerte
│  │  └─ Lezione 1 · Inizia con PosturaCorretta      → stazione prima di Area Massaggio
│  │     (ponti esistenti verso Area Massaggio, Movimento, Mente)
│  ├─ 2. Postura e fisiologia                        → linea autonoma Postura e fisiologia
│  │  └─ cinque lezioni in sequenza:
│  │     Area Massaggio → Movimento → Mente → Alimentazione → Farmaci
├─ Servizi personalizzati                            → pacchetti = future offerte
│  ├─ Individuali
│  │  ├─ Trattamento singolo
│  │  └─ Pacchetto percorso
│  └─ Percorso Aziende e associazioni sportive
├─ 3. Educazione 2 · Consapevolezza con le metodiche posturali
├─ 4. Educazione 3 · Dalla PosturaCorretta al Giardino del Corpo
└─ 5. Diventa insegnante PosturaCorretta             → solo contenitore
```

`Postura e fisiologia` resta figlio di Educazione 1 ma è separato dalla Prima settimana: nella home e
sulla mappa compare come linea distinta, percorribile anche senza acquistare la prima linea.

`Area Massaggio e recupero` è direttamente una lezione. Il precedente Node intermedio
`Orientarsi nell’area Massaggio e recupero` è stato eliminato perché duplicava la stessa funzione.

Il ponte `accesso-posturacorretta-da-percorso-integrato` (Educazione alla salute del Percorso
Integrato) punta a `postura-e-fisiologia`. Il ponte `accesso-percorso-integrato-da-posturacorretta`
collega PosturaCorretta al Percorso Integrato.

## Linee attive

1. `postura-recupero`: parte da La prima settimana e continua nell'Area Massaggio e recupero.
2. `postura-fisiologia`: parte da Postura e fisiologia e attraversa in ordine le cinque aree.

## Home PosturaCorretta

Ordine delle sezioni:

1. presentazione;
2. linea Postura e recupero con le tre offerte;
3. linea Postura e fisiologia;
4. Voglio risolvere un problema / Percorso Integrato;
5. Servizi personalizzati (prezzo da definire);
6. Educazione 2;
7. Educazione 3;
8. Diventa insegnante.

## Offerte già modellate

La prima linea mantiene tre ingressi progressivi:

1. Inizia con PosturaCorretta;
2. Percorso Igiene Posturale, con credito del primo ingresso;
3. Percorso Area Massaggio e recupero, comprendente i precedenti (bozza).

### Regole delle offerte (verificate all'import)

- un'offerta è una tratta continua della propria linea, dalla stazione iniziale alla finale;
- le offerte incluse stanno sulla stessa linea e dentro la tratta dell'offerta che le include, così
  ogni offerta può soltanto avanzare e comprendere le precedenti;
- i Node che dichiarano l'offerta in `offer_slugs` sono esattamente le stazioni della tratta.

`Percorso Igiene Posturale` termina sull'ultima lezione del corso (`igiene-posturale-recettori-sensoriali`).

Nella home ogni offerta si apre dalla prima stazione non compresa nelle offerte incluse.

## Mappa metropolitana

Ogni linea è disegnata come tracciato colorato (`settings.color` della linea, altrimenti il colore
della stazione iniziale). Dalla legenda si seleziona una linea per vedere solo quella e, sotto, le
sue offerte come tratte; selezionando un'offerta se ne evidenzia il tratto sulla mappa.

## Coordinate della mappa

Le coordinate restano nel database (`metro_map_placements`: una mappa per dominio, `x`, `y` e
`collapsed` per Node). Nello YAML sono salvate dentro ogni Node:

```yaml
postura-e-fisiologia:
  map_placements:
    posturacorretta.org: { x: 120.0, y: 340.0 }
```

`bin/rails nodes:import` le scrive nel database. L'export `nodes.yml` dalla mappa admin riporta
nel file le coordinate salvate nel database. `metro_maps.yml` conserva soltanto titolo e stato di
ogni mappa.

## Aggiornamento dei cataloghi

Node, linee, offerte e coordinate si modificano negli YAML in sviluppo e arrivano in produzione con
il deploy, che li importa. Se qualcosa viene modificato direttamente in produzione (per esempio
dalla mappa admin), si scaricano gli YAML aggiornati, si copiano nel repository e tornano in
produzione al deploy successivo.

## Versionamento delle linee: non previsto

Le linee non vengono versionate. Ciò che una persona ha percorso resta registrato nei propri Data
Commitment e nelle partecipazioni agli eventi: se una linea cambia, la persona ritrova le modifiche
e gli aggiornamenti, e una linea può comunque essere ripetuta.

## Da decidere

### Prezzi dei Servizi personalizzati

I Node sotto `Servizi personalizzati` diventeranno offerte quando saranno stabiliti prezzo e modalità:

- percorso online;
- lezione individuale;
- lezione di gruppo;
- eventuali combinazioni.

### Percorso insegnante — seconda fase

In questa fase esiste soltanto il Node contenitore `Diventa insegnante PosturaCorretta`.
Successivamente dovranno essere definiti:

- le linee per diventare insegnante, unendo i Node dei corsi da completare;
- requisiti di accesso per ogni corso;
- formazione e pratica personale richieste;
- tirocinio associato ai singoli corsi;
- partecipazione come tirocinante alle lezioni individuali, di gruppo o ibride;
- supervisione, verifica e abilitazione.

Il tirocinio non viene creato come figlio uguale per ogni corso: sarà collegato alle lezioni
programmate e ai ruoli della persona dopo aver definito le regole didattiche.
