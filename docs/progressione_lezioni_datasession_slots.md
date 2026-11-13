Valutazione articolare lo metterei nella home e lo cancellerei dalle lezioni

# Progressione uniforme delle lezioni 

1. Sessione:
Lezione Introduzione al Percorso Integrato
- Tre percorsi complementari 
- Il paradigma e il metodo scientifico
- Il tuo stato di salute
- Educazione 1 come si esprime il corpo Percorso educazione alla salute con postura e fisiologia
- Educazione 2 Consapevolezza con le metodiche posturali
- Educazione 3 La Connessione il corpo un mondo da scoprire 




2. Sessione
Lezione: La prima settimana con posturacorretta
- Postura e fisiologia educazione alla salute 
- Come si adatta la fisiologia
- Area Massaggio e recupero (coscienza ginnastica dolce autotrattamento)
- Movimento e allenamento
- Mente 
- Massaggio 
- Mangiare e nutrirsi
- Medicinali
- Parte pratica una scheda con i primi 3 pilastri 
- Una routine completa 



3. Sessione 
Lezione: Introduzione all'area recupero e massaggio
Lezione: Introduzione all'area movimento e allenamento
Lezione: Introduzione all'area recupero e massaggio
Lezione: Introduzione a postura e fisiologia e metterei le 2 aree mangiare e farmaci qui dentro insieme alla fisiologia e alle altre cose
Lezione: lezioni il gdc (cose crescita personale evoluzione essere umano)
Lezione: lezioni rails4b (risorse progetti)


4. Sessione 



## I sei DataSlot della lezione teorica gratuita

├─ Prima parte · 90 minuti · corpo e pratica
│  ├─ DataSlot 1 · Massaggio e recupero
│  ├─ DataSlot 2 · Movimento
│  └─ DataSlot 3 · Meditazione e consapevolezza
│
└─ Seconda parte · 90 minuti · salute, connessione e risorse
   ├─ DataSlot 4 · Percorso salute
   ├─ DataSlot 5 · Giardino del Corpo
   └─ DataSlot 6 · Risorse e Rails4Business
```


## Mappa metropolitana 

sarebbeo da spostare corsi e lezioni a dx e servizi a sx così da rendere possibile un organizzazione visiva più 


e poi mettere le 6 file in percorso salute andrebbero mangiare e medicinali e gli altri corsi capisci? 

### Fatto (13 novembre 2026)

- A sinistra i Node che non generano lezioni: Percorso Integrato, Servizi personalizzati,
  Educazione 2, Diventa insegnante. A destra quelli che generano lezioni: Educazione 1 ed Educazione 3.
- La linea Postura e recupero è in fila su una retta (non più a serpentina); gli approfondimenti
  stanno sopra la lezione da cui escono.
- Massaggio, Movimento e Mente sono tre file parallele.

- Tolta la linea Postura e fisiologia (`removed_slugs` in `metro_lines.yml`).
- La linea Postura e recupero parte da Area Massaggio e recupero. Tolta l'offerta "Inizia con
  PosturaCorretta" (`removed_slugs` in `offers.yml`); Igiene Posturale parte da Area Massaggio e non
  comprende altre offerte.
- Tabella sessioni × slot disegnata sulla mappa admin (`grid` in `config/metro_maps.yml`).
- Valutazione della mobilità articolare: figlia diretta di PosturaCorretta (a sinistra sulla mappa),
  fuori dalla linea e dalle offerte; Igiene Posturale è figlia di Area Massaggio. Nella home va
  aggiunta quando si rifà la landing.

### Mappa lezioni PosturaCorretta (in discussione)

**Sessioni sulle x** e **slot sulle y**, per ora dentro la mappa attuale (a destra; a sinistra
restano i Node senza lezioni). Prima si sistemano i Node nella griglia, poi linee e offerte.

```text
                    Sess. 1    Sess. 2           Sess. 3                       Sess. 4 →
                                                 [Postura e fisiologia] ← corso
Slot 1  Massaggio   Intro PI ─ Prima settimana ─ Introduzione a P. e f. ────── Area Massaggio ─ Igiene Posturale…
Slot 2  Movimento                                                              Area Movimento ─ corsi…
Slot 3  Mente                                                                  Area Mente ───── corsi…
Slot 4  Salute                                                                 Nutrire il corpo ┬ Alimentazione (alternate)
                                                                                                └ Farmaci
Slot 5  Giardino del Corpo                                                      Il Giardino del Corpo
Slot 6  Rails4Business                                                         Rails4Business
```

Ogni corso sta sopra la sua prima lezione, nella stessa colonna. Slot 4: vedi
`posturacorretta_slot4_percorso_salute.md`.

Slot 5 e 6: Il Giardino del Corpo e Rails4Business (da Educazione 3) partono dalla Sessione 4; le
loro lezioni si definiscono più avanti, con la formazione professionisti.

- Catena di lezioni da Educazione 1:
  `Introduzione al Percorso Integrato` → `La prima settimana con PosturaCorretta` → `Area Massaggio e recupero`.
  `Lezione 1 · Inizia con PosturaCorretta` è stata unita alla Prima settimana (rimossa con
  `removed_slugs`). Postura e fisiologia resta punto di ingresso con un ponte verso Area Massaggio.
- Una colonna = una sessione = un Node: corsi e lezioni occupano una colonna ciascuno.

### Prossimi passi

1. Rifare linee e offerte.
2. Le altre file (Alimentazione, Farmaci, Giardino del Corpo, Rails4Business): da vedere dopo.
3. I 6 slot diventeranno 2 incontri, base (le 3 M) e avanzato; per ora contano soltanto Node, linee e offerte.