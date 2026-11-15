# Home PosturaCorretta — interventi da valutare

## Obiettivo

Trasformare la home da catalogo dei contenuti a punto di ingresso comprensibile per una persona che arriva con un problema, senza applicare tutte le modifiche contemporaneamente.

Questo documento raccoglie le proposte emerse. Ogni intervento deve essere valutato e approvato prima dell'implementazione.

## Stato delle decisioni

### Prerequisito tecnico prima della revisione della home

- [x] Verificare e correggere la pubblicazione immediata dei capitoli PosturaCorretta da parte del superadmin.
- [x] Il pulsante “Pubblica” deve identificare il Brand e il dominio `posturacorretta.org`, creare una decisione editoriale completata e rendere il capitolo accessibile al pubblico.
- [ ] Eseguire una prova manuale completa con un capitolo in bozza prima di iniziare gli interventi sulla home.

| Intervento | Problema osservato | Possibile soluzione | Priorità proposta | Decisione |
| --- | --- | --- | --- | --- |
| Invito iniziale | Il vero “Inizia” si trova dentro il primo corso; “Richiedi accesso” può sembrare una lista d'attesa. | Pulsante visibile nella parte alta: “Inizia”, collegato al primo corso. | Alta | Implementato · da verificare in locale |
| Gratuità, tempi e passaggio successivo | Non è subito chiaro cosa sia gratuito, quanto richieda e cosa accada dopo il primo contenuto. | Dichiarare accesso, costo, durata indicativa e possibilità successive. Prima di mostrare tempi occorre misurarli. | Alta | Da valutare |
| Presentazione dei corsi | Molti corsi mostrati insieme possono sembrare un catalogo e non un percorso. | Presentare i sei corsi iniziali come passaggi di un unico cammino e raccogliere le metodiche successive sotto “Approfondisci”. | Alta | Prima prova implementata: “Corso 1 di 6”–“Corso 6 di 6” · da verificare in locale |
| Sezioni senza contenuti | I blocchi vuoti fanno percepire il sito come incompleto. | Nasconderli temporaneamente oppure riunirli in una sola riga di roadmap. | Media | Da valutare |
| Fiducia e responsabilità | In home non è immediatamente visibile chi cura il progetto, con quale formazione e con quali limiti professionali. | Presentare Mark Postura come fisioterapista formato nelle metodiche posturali e promotore del progetto; spiegare che la rete del Percorso Integrato accoglierà progressivamente altri professionisti. Collegare la formazione e la storia completa. | Alta | Da progettare usando le fonti MarkPostura già presenti |
| Pagamenti DASH | Nel footer può distrarre o confondere una persona interessata alla salute. | Valutare se spostarlo in una pagina dedicata ai pagamenti o al progetto. | Media | Da valutare |
| Avanzamento dopo l'accesso | La persona deve capire che cosa ha completato e quale sia il passo successivo. | Mostrare su ogni corso stato, capitoli completati, percentuale e azione “Inizia”, “Continua” o “Rivedi”. Introdurre blocchi soltanto quando hanno una ragione didattica o di sicurezza. | Media | Implementato · da verificare in locale |
| Percorso rapido | Alcune persone vogliono arrivare direttamente alla pratica. | In futuro offrire questionari e schede di orientamento prima dell'Igiene Posturale. Non presentarli come diagnosi o autorizzazione sanitaria. | Pianificata | In attesa di schede e questionari |

I capitoli non sono classificati come “teorici” o “pratici”. La parte operativa sarà rappresentata da risorse collegate al capitolo con un proprio formato, ad esempio `scheda`, `quiz`, `video` o `esercizio`. Quando queste risorse saranno disponibili, la home potrà offrire una vista rapida “Solo schede e quiz” senza creare un secondo percorso.

Il `DataCommitment` editoriale che pubblica un corso o un capitolo è distinto dal `DataCommitment` personale di apprendimento. Quando una persona che ha iniziato il corso seleziona “Segna come letto”, viene registrata la data effettiva, la data appare nel capitolo e le barre di avanzamento del corso e della home vengono ricalcolate.

### Permessi dei DataCommitment editoriali

- Il superadmin può intervenire su tutti i contenuti.
- Il creatore o l'admin del Brand può pubblicare e sospendere i contenuti del Brand.
- Un profilo delegato può farlo soltanto se possiede il ruolo `responsabile` sul Node editoriale, collegato alla gerarchia del creatore, e dispone dell'accesso al Brand.
- Il `subject_node` del DataCommitment deve appartenere realmente all'albero del Brand indicato: un ruolo posseduto su un altro progetto non concede permessi trasversali.
- `created_by_profile_id` e `published_by_profile_id` conservano rispettivamente chi ha registrato la decisione e chi ha approvato la pubblicazione; non sostituiscono la verifica dei ruoli.
- La sospensione non elimina la pubblicazione precedente: crea un nuovo DataCommitment `content` con `publication_change_kind: unpublish`, `publication_status: draft` e `publication_visibility: private`, collegato alla decisione precedente.

## Criteri per decidere

Prima di approvare un intervento chiedersi:

1. Aiuta la persona a capire da dove iniziare?
2. Aumenta fiducia e chiarezza?
3. È già sostenuto da contenuti e funzioni realmente disponibili?
4. Introduce promesse, prezzi o tempi che non possiamo ancora confermare?
5. Rende la home più semplice oppure aggiunge un'altra scelta?

## Metodo di lavoro

Si procede con un solo intervento alla volta. Ogni punto viene prima verificato in locale e soltanto dopo viene considerato concluso; gli altri restano in attesa finché non ricevono un'approvazione esplicita.

### Ordine operativo

- [x] Correggere la pubblicazione immediata dei capitoli PosturaCorretta.
- [x] Introdurre pubblicazione e sospensione tramite DataCommitment editoriali, con permessi di superadmin, admin/creatore del Brand e responsabile del Node.
- [x] Mostrare sempre agli editor autorizzati i comandi coerenti con lo stato: “Aggiorna” e “Sospendi” se pubblico, “Pubblica” se in bozza; nasconderli agli utenti senza permesso.
- [x] Separare chiaramente i due livelli: l'utente può iniziare un corso e segnare un capitolo come letto; superadmin, admin/responsabile del Node o del Brand possono pubblicare, sospendere e aggiornare sia il corso sia il capitolo.
- [x] Separare i DataCommitment editoriali dai completamenti personali degli utenti.
- [x] Sostituire “Iscriviti” con “Inizia”: l'avvio crea un DataCommitment istantaneo già concluso, mentre il progresso resta affidato ai capitoli segnati come letti.
- [x] Registrare “Segna come letto”, data effettiva e aggiornamento delle barre di avanzamento.
- [x] Nascondere la barra allo 0% prima dell'avvio, fare iniziare il corso dal primo capitolo e sbloccare “Segna come letto” rispettando l'ordine dei capitoli.
- [x] Mostrare in home lo stato “In arrivo” per i capitoli non pubblicati, “Da completare” per quelli pubblicati e “Completato il [data]” per quelli già letti.
- [x] Nella home mostrare “Inizia” soltanto sul primo capitolo di un corso non avviato e “Da completare” sugli altri capitoli pubblicati.
- [x] Tenere i corsi iniziati e il loro avanzamento nel Percorso online, non nella pagina Lezioni, che è dedicata alla pratica con insegnanti e appuntamenti.
- [x] Collocare “Segna come letto” alla fine del capitolo e usare negli indici un cerchio vuoto per i capitoli da completare e un cerchio verde con spunta e data per quelli completati.
- [x] Rendere “Aggiorna” una decisione editoriale diretta e aggiungere conferma a pubblicazione/sospensione.
- [x] Usare il cerchio verde con spunta e la data `gg/mm/aaaa` in home e nell'indice del corso; nella sidebar mostrare soltanto il cerchio. In fondo al capitolo mostrare “Letto il [data]”, senza azione per riportarlo a non letto.
- [x] Rendere visibile in home il pulsante “Inizia”.
- [x] Presentare i primi sei contenuti come “Corso 1 di 6”–“Corso 6 di 6”.
- [x] Eliminare la classificazione teoria/pratica dai capitoli.
- [x] Collegare dal footer la storia e la timeline MarkPostura.
- [x] Aggiornare il racconto MarkPostura dalla fisioterapia alla creazione di progetti.
- [ ] **Prossimo intervento unico:** prova manuale completa in locale del ciclo pubblicazione → sospensione → inizio corso → “Segna come letto” → data → avanzamento.
- [ ] Sistemare la fotografia ripetuta nella home MarkPostura.
- [ ] Progettare e approvare la pagina PosturaCorretta dedicata a persone, fondatori, curatori e professionisti.
- [ ] Inserire nella home PosturaCorretta una sintesi con rimando alla pagina delle persone.
- [ ] Valutare sezioni vuote, approfondimenti, DASH e collegamento `/contatti`.
- [ ] Aggiungere in futuro schede, quiz e vista rapida.
- [ ] Definire in futuro servizi umani, attestati ed eventuali pagamenti.

## Fiducia, formazione e rete professionale

- PosturaCorretta non deve essere presentato come il lavoro isolato di una sola persona.
- Mark Postura è il promotore attuale e va presentato anzitutto come **fisioterapista formato nelle metodiche posturali**.
- Il Percorso Integrato potrà mostrare progressivamente gli altri professionisti reali che aderiranno alla rete, ciascuno con ruolo, formazione e responsabilità verificabili.
- La regola di sicurezza è già spiegata nel corso *Postura e salute: il Percorso Integrato*: quando la salute può essere in pericolo o la persona si riconosce nell'area rossa, la priorità è rivolgersi al medico o al professionista sanitario adatto prima di proseguire autonomamente.
- In home è sufficiente un richiamo sintetico a questa regola; la spiegazione completa resta nel corso, evitando di duplicarla in più versioni.

### Materiali MarkPostura da sistemare e riutilizzare

- La timeline non è stata eliminata: esiste ancora come pagina editoriale pubblicata in `config/data/sites/markpostura_it/pages/timeline.yml`, con sorgente Knight Lab/Google Sheet. Il footer PosturaCorretta ora la collega con la voce “La storia di Mark Postura”.
- La cronologia formativa strutturata è già presente in `config/data/posturacorretta/accademia/teachers/markpostura.yml` e comprende laurea in Fisioterapia e percorsi in Osteopatia, Corpo e Coscienza e Metodo GDS.
- La home MarkPostura riutilizza la stessa immagine nel blocco iniziale e nel blocco “Chi trovi dall'altra parte”; occorre scegliere immagini differenti o usare una sola fotografia.
- Prima di creare il blocco nella home PosturaCorretta, sistemare la fonte MarkPostura: dicitura professionale, formazione, collegamento alla timeline e fotografie non duplicate.

### Pagina PosturaCorretta dedicata alle persone

- Valutare una pagina “Persone e fondatori” o “Chi ha dato vita al progetto”, composta da card collegate ai profili e alle rispettive storie.
- Distinguere chiaramente fondatori, curatori e professionisti della rete: non tutte le persone presenti devono essere chiamate fondatrici.
- Ogni card dovrà usare soltanto dati reali e verificabili: ruolo nel progetto, professione, formazione pertinente e collegamento al profilo completo.
- La home potrà mostrare una sintesi e rimandare a questa pagina, evitando di trasformarsi in una raccolta di biografie.

## Orientamento economico da approfondire

- La prima sezione rimane ad accesso libero.
- L'eventuale pagamento non viene presentato come una “valutazione”: è legato a un intervento umano, come accompagnamento, lezioni o supervisione.
- L'attestato può essere a pagamento soltanto se comprende una verifica reale svolta da una persona.
- Un abbonamento alla piattaforma sarà valutato in futuro soltanto in presenza di un servizio continuativo; per ora non viene introdotto.

## Review UX della landing a listino — 15 novembre 2026

### Sintesi

La home attuale è pulita e leggibile, ma comunica più un **catalogo in costruzione** che un percorso
affidabile per una persona che cerca orientamento o aiuto. La priorità non è aggiungere molte sezioni:
è rendere più chiari il primo passo, il funzionamento del percorso e le ragioni per fidarsi.

Questa review riguarda la landing attiva in
`app/views/nodes/posturacorretta_home/_landing.html.erb` e il listino in
`config/data/posturacorretta/listino.yml`. Non sostituisce le decisioni precedenti: raccoglie i punti
da discutere prima di intervenire.

### Problemi osservati e possibili interventi

#### 1. “Da dove vuoi iniziare?” offre una sola risposta

La domanda promette una scelta, ma nella parte iniziale compare soltanto il pulsante
“Inizia con PosturaCorretta”. Le due alternative da valutare sono:

- sostituire la domanda con **“Il primo passo consigliato”**, mantenendo un'unica azione;
- mantenere la domanda e offrire due o tre ingressi reali per bisogno, per esempio:
  **“Ho dolore o un problema”**, **“Voglio conoscere e prevenire”**, **“Sono un professionista”**.

Non vanno introdotte scelte che conducono a pagine vuote o percorsi non ancora disponibili.

#### 2. La promessa iniziale è evocativa ma poco concreta

“Ascolta il tuo corpo, riattiva la tua fisiologia” esprime la visione, ma non spiega subito che cosa
offre PosturaCorretta. Può restare come titolo se viene accompagnato da una frase concreta, ad esempio:

> Un percorso educativo di lezioni, pratica e professionisti per conoscere il corpo e orientarti
> nelle scelte di salute.

Il testo definitivo deve evitare promesse terapeutiche e descrivere soltanto ciò che è realmente
disponibile.

#### 3. La home entra troppo presto nel listino

Tra l'hero e le offerte manca un breve ponte che chiarisca:

- per chi è il percorso;
- come funziona;
- che cosa ottiene la persona;
- perché può fidarsi del progetto.

Per un progetto legato alla salute, orientamento e fiducia devono precedere la proposta economica.
Il ponte dovrebbe essere compatto e non trasformarsi in una seconda pagina di presentazione.

#### 4. La progressione non usa ancora un ordine univoco

Nella home “Igiene Posturale” precede “Area Massaggio e recupero”; nella sequenza interna di
`Posturacorretta::HomeJourney::STATIONS` l'Area Massaggio precede Igiene Posturale. Occorre decidere
un solo ordine didattico e applicarlo a:

- card della home;
- mappa del percorso;
- corsi e lezioni;
- offerte cumulative;
- testi che descrivono il passo precedente e quello successivo.

Finché l'ordine non è condiviso, non conviene rafforzare graficamente la numerazione delle tappe.

#### 5. Troppi elementi comunicano incompiutezza

La dicitura “Prezzi in definizione” e la presenza ripetuta di “In arrivo” possono far percepire il
progetto come non pronto. Per la versione pubblica si propone di:

- mostrare in primo piano soltanto ciò che è disponibile;
- raccogliere le anticipazioni in un'unica sezione discreta “Prossimamente”;
- non mostrare un avviso sui prezzi se in quella fase la persona non può ancora acquistare;
- mantenere le voci operative o sperimentali riservate al superadmin.

#### 6. Le card descrivono soprattutto il formato

Indicazioni come “1 lezione + corso online” sono utili, ma non spiegano il beneficio. Ogni card
dovrebbe usare questa gerarchia:

1. risultato o utilità per la persona;
2. formato e impegno richiesto;
3. cosa comprende;
4. azione disponibile.

Esempio di direzione editoriale:

> Comprendi come orientarti tra i diversi professionisti e costruisci la base del tuo percorso.

Il testo va poi completato con informazioni verificabili su lezione, corso online, durata e costo.

#### 7. Mancano elementi immediati di affidabilità

Prima del listino serve una fascia sintetica che mostri almeno alcuni elementi verificabili:

- chi cura e promuove il progetto;
- formazione e responsabilità professionali pertinenti;
- metodo educativo e limiti del servizio;
- professionisti, sedi o esperienze reali già disponibili;
- eventuali testimonianze reali, solo con consenso e fonte verificabile.

Questo punto si collega alla sezione “Fiducia, formazione e rete professionale” del presente documento
e alla futura pagina dedicata alle persone. Non vanno inventati numeri, risultati o prove sociali.

#### 8. La progressione è lunga su mobile

Le card passano correttamente a una colonna, ma cinque blocchi consecutivi possono sembrare cinque
prodotti separati. Su mobile una timeline verticale compatta renderebbe più evidente che si tratta di
passaggi cumulativi dello stesso cammino.

La timeline deve comunque lasciare chiari:

- il punto di partenza;
- le tappe disponibili;
- ciò che è compreso nei passaggi successivi;
- la differenza tra contenuto online, lezione e servizio umano.

### Struttura proposta della home

Ordine da valutare, senza considerarlo ancora approvato:

1. **Promessa chiara** — visione più spiegazione concreta dell'offerta.
2. **Primo passo consigliato** — una sola azione se esiste un ingresso valido per tutti.
3. **Ingressi per bisogno** — soltanto se portano a destinazioni reali e differenti.
4. **Come funziona** — spiegazione sintetica in tre passaggi.
5. **Percorso e listino disponibile** — tappe pubblicate, ordine univoco, benefici prima del formato.
6. **Fiducia** — persone, competenze, metodo, limiti e presenza sul territorio.
7. **Azione conclusiva** — ripresa coerente del primo passo o contatto appropriato.

### Prima proposta operativa

Il primo intervento consigliato è limitato alla parte iniziale:

1. decidere se la home propone un unico primo passo o più ingressi per bisogno;
2. riscrivere hero, sottotitolo e CTA in base a quella decisione;
3. aggiungere un ponte molto breve prima del listino;
4. verificare il risultato su desktop e mobile;
5. soltanto dopo, semplificare il listino e progettare il blocco fiducia.

### Decisioni da prendere

- [ ] La home deve suggerire un solo primo passo oppure offrire ingressi diversi per bisogno?
- [ ] Qual è l'ordine didattico definitivo tra Igiene Posturale e Area Massaggio e recupero?
- [ ] Quali tappe sono realmente disponibili e quindi mostrabili al pubblico oggi?
- [ ] Quali informazioni su durata, gratuità, prezzo e modalità possiamo dichiarare con certezza?
- [ ] Quali elementi reali di fiducia sono pronti per essere pubblicati nella home?
- [ ] Il listino resta nella home oppure la home presenta il percorso e rimanda a una pagina dedicata?
