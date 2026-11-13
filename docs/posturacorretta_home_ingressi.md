# Home PosturaCorretta — ingressi e avvio del percorso

Documento di lavoro per rendere la home di PosturaCorretta intuitiva e aiutare una persona a iniziare senza dover conoscere in anticipo la struttura della rete.

Nessuna proposta contenuta in questo documento è ancora implementata.

## Obiettivo

La home deve rispondere rapidamente a quattro domande:

1. Cosa posso fare adesso?
2. Quanto tempo e impegno richiede?
3. Quale ingresso è adatto al mio bisogno?
4. Dove mi porterà la scelta?

La rete completa e la mappa a corsie devono approfondire il percorso, non essere la prima decisione richiesta alla persona.

## Decisioni confermate (13 novembre 2026)

### A. Prima sezione della home

La prima sezione è **Educazione · capire come il corpo e la fisiologia si esprimono**
(Node `apprendimento-1-espressione`). Al suo interno la persona sceglie fra tre possibilità, che sono
le tre offerte cumulative della linea `postura-recupero`:

1. **Inizia con la prima settimana** (`prima-settimana-posturacorretta`);
2. **Igiene Posturale** (`igiene-posturale`), che comprende la prima settimana;
3. **Area completa Postura e recupero**: massaggio, ginnastica dolce e terapia manuale
   (`area-massaggio-recupero`), che comprende le due precedenti.

### B. Presentazione delle tre offerte

Tre card affiancate; la prima è evidenziata come **consigliata per iniziare**. Si vedono subito i
tre livelli, e chi è indeciso sa da dove partire.

### C. Titolo in cima alla pagina

```text
Postura · Salute · Educazione                         ← etichetta sopra il titolo
Ascolta il tuo corpo, riattiva la tua fisiologia      ← titolo
Da dove vuoi iniziare?                                ← sottotitolo, introduce le tre card
```

### D. Testi delle tre card

| | 1 · Consigliata per iniziare | 2 | 3 |
|---|---|---|---|
| Nome | Inizia con la prima settimana | Igiene Posturale | Postura e recupero |
| Una riga | Osserva la tua postura e inizia a praticare. | Porta la postura corretta nella vita di ogni giorno. | Massaggio, ginnastica dolce e terapia manuale. |
| Comprende | — | ✓ la prima settimana | ✓ prima settimana e Igiene Posturale |
| Pulsante | Inizia | Scopri | Scopri |

Durata e prezzo verranno aggiunti quando saranno decisi.

### E. Sezioni successive

Dopo la prima sezione, in quest'ordine; ognuna parte da una domanda alla persona e ha un solo pulsante:

1. **Hai un problema specifico?** → Percorso Integrato (`percorso-integrato`);
2. **Preferisci un percorso su misura?** → Servizi personalizzati (`pacchetto-gruppi`): individuali,
   aziende e associazioni sportive;
3. **Vuoi praticare una metodica?** → Educazione 2 · Consapevolezza con le metodiche posturali
   (`apprendimento-2-connessione`);
4. **Oltre la postura** → Educazione 3 · Dalla PosturaCorretta al Giardino del Corpo
   (`dalla-posturacorretta-al-giardino-del-corpo`);
5. **Vuoi insegnare?** → Diventa insegnante PosturaCorretta (`diventa-insegnante-posturacorretta`).

## 1. Azione principale

La home propone una sola CTA primaria:

```text
Inizia la prima settimana con PosturaCorretta
```

Messaggio suggerito:

> Ascolta il tuo corpo. Inizia con una settimana di osservazione, comprensione e pratica.

Informazioni sintetiche da mostrare vicino alla CTA:

(c'è già un video per questo e un lavoro da iniziare la scheda è da implementare)

Destinazione:

```text
la-prima-settimana-con-posturacorretta
```

## 2. Sezione “Scegli da dove partire”

La sezione compare dopo la CTA principale e offre tre ingressi alternativi.


### 2.1 Ho un problema: da dove inizio? (questo è da gestire)

Testo suggerito:

> Hai dolore, una difficoltà o un bisogno che vuoi comprendere? Parti da un orientamento più ampio.

Destinazione:

```text
Percorso Integrato
```

Possibile passaggio successivo:

```text
Percorso Integrato
→ Inizia il Percorso Integrato
→ Stato di Salute
→ Questionario di orientamento
```




### 2.2 voglio iniziare il percorso di educazione alla salute postura e fisiologia (questo è quello su cui dobbiamo puntare)

Il quarto ingresso può essere aggiunto in seguito oppure presentato in una sezione successiva:

### Voglio capire come funziona il mio corpo

Testo suggerito:

> Comprendi come il corpo si esprime e come funzionano postura, movimento e fisiologia.

Destinazione:

```text
Educazione 1 · Capire come si esprime il corpo e come funziona la tua fisiologia
```

Non viene proposto subito per evitare troppe scelte nella prima schermata.


## 2.3 Cerco una metodica da praticare (questo è da implementare)

Testo suggerito:

> Esplora discipline, pratiche e tecniche corporee per sviluppare consapevolezza e trovare ciò che senti più adatto.

Destinazione:

```text
Educazione 2 · Consapevolezza
→ Metodiche posturali
```

### 2.4 Voglio esplorare oltre la postura (questo è anch'esso da capire come gestire...)

Testo suggerito:

> Scopri connessioni tra corpo, ambiente, natura, arte, relazioni ed esperienze.

Destinazione:

```text
Educazione 3 · Connessione dalla PosturaCorretta al Giardino del Corpo
```

Passaggio successivo:

```text
Il Giardino del Corpo
```




## 4. Node di ingresso

Si propone di creare tre Node pubblici di orientamento: in realtà questi node ci sono già...



Caratteristiche:

- possiedono titolo, descrizione ed eventuale immagine;
- sono visibili e utilizzabili nella home;
- non duplicano i contenuti dei Node di destinazione;
- non sono container di corsia;
- hanno una sola destinazione;
- possono essere esclusi dalla corsia principale di PosturaCorretta.

## 5. Nuovo tipo di Node

Per distinguerli dai ponti tecnici si propone:

```text
view_type: entry_point
```

Differenze rispetto a `access_bridge`:

| `entry_point` | `access_bridge` |
|---|---|
| visibile nella home | nascosto come card tecnica |
| possiede contenuto editoriale | descrive soprattutto una relazione |
| parla con il linguaggio della persona | usa una funzione tecnica nella rete |
| può avere immagine e CTA | viene normalmente reso come collegamento |

Il modello può continuare a utilizzare `link_node` per indicare la destinazione, purché il Node di ingresso rimanga senza figli.

## 6. Struttura proposta della home

```text
Nav

Hero
├─ promessa principale
├─ tempo e impegno richiesti
└─ CTA: Inizia la prima settimana

Scegli da dove partire
├─ Ho un problema
├─ Cerco una metodica
└─ Voglio esplorare oltre la postura

Come funziona la prima settimana
├─ Osserva
├─ Comprendi
├─ Prova
└─ Scegli come continuare

Percorso PosturaCorretta
├─ Educazione 1
├─ Educazione 2
└─ Educazione 3

Mappa/corsie della rete

Approfondimenti e contenuti

Footer
```

## 7. Regole UX

- una sola CTA primaria sopra la piega;
- massimo tre scelte alternative nella prima sezione;
- usare bisogni e intenzioni, non nomi tecnici della rete;
- ogni card deve anticipare chiaramente la destinazione;
- mantenere titoli brevi nella home e titoli completi nei Node;
- mostrare il percorso completo soltanto dopo la prima scelta;
- conservare modalità e corsie aperte quando si entra nella mappa;
- garantire un pulsante chiaro per tornare alla home.

## 8. Possibili varianti

### Variante A — orientamento prima della pratica

CTA primaria:

```text
Trova il tuo punto di partenza
```

Porta al Questionario di orientamento sullo stato di salute.

### Variante B — pratica immediata

CTA primaria:

```text
Inizia la prima settimana
```

Il Questionario rimane un ingresso secondario attraverso “Ho un problema”.

Raccomandazione attuale: Variante B, perché permette di iniziare subito e mantiene l’orientamento disponibile senza renderlo obbligatorio.

## 9. Implementazione proposta

1. Approvare testi, titoli e destinazioni.
2. Creare i tre Node `entry_point` nel catalogo YAML.
3. Importare e verificare i collegamenti.
4. Creare una partial per la CTA principale.
5. Creare una partial per le tre card di ingresso.
6. Inserire le partial nella home Node Show di PosturaCorretta.
7. Collegare le card alle pagine Node o alla vista a corsie appropriata.
8. Verificare desktop e mobile.
9. Misurare clic sulla CTA principale e sui tre ingressi.

## 10. Decisioni da prendere

1. Confermare `Inizia la prima settimana` come CTA primaria.
2. Confermare i tre Node di ingresso.
3. Decidere se il quarto ingresso “Voglio capire il corpo” debba comparire subito o successivamente.
4. Decidere se le card aprano il Node Show oppure direttamente la vista a corsie focalizzata.
5. Approvare i testi definitivi delle card.
6. Scegliere eventuali immagini o icone per i tre ingressi.
