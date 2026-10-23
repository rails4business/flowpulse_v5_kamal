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
