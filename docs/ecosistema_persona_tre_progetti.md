# La persona al centro: architettura dei progetti

Questo documento definisce la relazione tra PosturaCorretta, Percorso Integrato e Il Giardino del Corpo. È la fonte strategica da usare per home, presentazioni e mappe dell’ecosistema.

La home precedente è conservata come riferimento in `config/data/posturacorretta/home/home_old_backup.yml`; il relativo inventario si trova in `config/data/posturacorretta/home/README.md`.

## La regola principale

Al centro c’è la **persona**, osservata nel rapporto tra corpo, fisiologia, ambiente interno e ambiente esterno.

Intorno alla persona ci sono due direzioni principali:

1. **PosturaCorretta — educazione, salute e accompagnamento**
   - PosturaCorretta in un mese;
   - pratica individuale e gruppi;
   - Accademia e formazione degli insegnanti;
   - metodiche posturali;
   - Percorso Integrato come sottobrand operativo.

2. **Il Giardino del Corpo — filosofia ed esperienze**
   - eventi, natura e territorio;
   - musica, espressione, cultura e relazioni;
   - sviluppo armonico della persona;
   - prospettiva futura di un luogo o agriturismo rigenerativo.

## Percorso Integrato

Il **Percorso Integrato** non è per ora un brand editoriale separato. È un sottobrand di PosturaCorretta dedicato alla parte operativa e professionale:

- tutor e raccolta del bisogno;
- programmi personalizzati;
- professionisti con competenze verticali;
- coordinamento di obiettivi, attività e verifiche.

Può conservare nome, colore e identità grafica riconoscibili, ma deve essere presentato come **un progetto PosturaCorretta**. Un dominio dedicato potrà essere valutato soltanto quando avrà pubblico, contenuti e attività sufficienti per funzionare autonomamente.

## Canale editoriale

Il canale YouTube rimane unico e si chiama **PosturaCorretta**. I contenuti vengono distinti attraverso playlist e rubriche:

- PosturaCorretta in un mese;
- Accademia ed educazione;
- insegnanti e metodiche posturali;
- Percorso Integrato, professionisti e programmi;
- eventi e introduzioni alla filosofia del Giardino del Corpo.

Ogni contenuto deve indicare progetto o rubrica, autore e figure coinvolte, senza richiedere la creazione di canali separati.

## Relazione tra i progetti

Le persone possono iniziare:

- dall’educazione PosturaCorretta;
- dal Percorso Integrato, quando hanno un bisogno concreto;
- dagli eventi del Giardino del Corpo, quando incontrano la filosofia attraverso un’esperienza.

Non è una sequenza obbligatoria. Il Percorso Integrato appartiene però all’architettura di PosturaCorretta, mentre Il Giardino del Corpo rimane un progetto collegato distinto.

## Architettura digitale

- `posturacorretta.org`: educazione, primo mese, Accademia, metodiche posturali e Percorso Integrato;
- `ilgiardinodelcorpo.it`: filosofia, esperienze ed eventi;
- `flowpulse.net`: infrastruttura digitale che collega e sostiene i progetti.

## Regola grafica

Nelle mappe:

- la persona occupa il centro;
- PosturaCorretta e Il Giardino del Corpo sono le due direzioni principali;
- Percorso Integrato compare all’interno o in continuità con PosturaCorretta, con la dicitura **un progetto PosturaCorretta**;
- Flowpulse appare all’esterno o sopra la mappa come infrastruttura;
- le connessioni non devono suggerire un percorso obbligatorio.

## Capitolo conclusivo condiviso

Le pagine principali devono mantenere un collegamento conclusivo che ricomponga l’ecosistema intorno alla persona. Il contenuto condiviso è mantenuto nel partial `app/views/shared/ecosystem/_three_projects_connection.html.erb`.

Il partial dovrà essere riallineato nella successiva revisione della home per mostrare chiaramente che Percorso Integrato è un sottobrand di PosturaCorretta e non un terzo brand autonomo.
