# Listino, materiale, primi gruppi e tirocinio

Documento di lavoro del 14 novembre 2026. Raccoglie quello che ho capito e le domande aperte, prima
di decidere da dove iniziare. Riprende e aggiorna `docs/archivio/posturacorretta_iniziare_modalita_tirocinio.md`.
Il riferimento per le voci del listino resta `docs/posturacorretta_offerte_listino.md`.

## Todo (il più recente in alto)

- **14/11 · Carte.** Le carte sono esercizi: si fanno dopo, da affiancare alle schede pratiche delle
  lezioni.
- **14/11 · Abbonamenti in attesa.** Non si toccano le offerte per ora (nome e confini
  dell'abbonamento Intro da 4 lezioni compresi).
- **14/11 · Corso Area Massaggio e recupero** sopra la sua lezione, dopo Postura e fisiologia.
  Movimento e Mente restano come sono.
- **14/11 · Card della home**: Igiene Posturale 5 lezioni, Area Massaggio completa 35 lezioni, frase
  iniziale corretta.
- **14/11 · Fatto:** ripristinata la lezione *Sintesi del percorso* sotto Altre metodiche
  posturali; la linea `postura-recupero` e l'offerta Area completa finiscono lì (35 lezioni).

## Visione

La piattaforma fornisce **materiale** e **lezioni**. Il materiale accompagna le lezioni e può essere
usato anche da solo. Le **carte** (come nell'esempio degli strumenti somatici) sono esercizi da
scaricare o comprare, affiancati alle schede pratiche: si fanno dopo.

## Ordine di lavoro

1. **Listino** in home: percorso, lezioni e servizi.
2. **Finire il materiale** delle lezioni e dei corsi introduttivi.
3. **Primi due gruppi** in due sedi, con Mark come insegnante.
4. **Tirocinio** e **certificato insegnante** come Node.
5. Dopo: insegnanti e centri, carte, mappa del percorso di una persona.

## 1. Listino

### Stato attuale

La home mostra la sezione "Lezioni e percorsi" con 5 card (Introduzione al Percorso Integrato, Prima
settimana, Postura e fisiologia, Igiene Posturale, Area Massaggio). Avanzati e Servizi personalizzati
sono visibili solo al superadmin.

### Da correggere

- La frase "Si inizia dalla prima settimana" non è vera: si inizia dall'Introduzione al Percorso
  Integrato.
- Area Massaggio dice "n lezioni": sono 35 (linea completa fino a Sintesi del percorso).
- Igiene Posturale dice "6 lezioni": sono 5.
- Le voci non dicono **come** si fanno: online, in gruppo, in singolo.

### Domande

1. Le modalità (online / gruppo / singolo) vanno già mostrate nel listino, anche senza prezzo?
2. I servizi (per esempio valutazione posturale, trattamento) entrano ora nel listino pubblico o
   restano visibili solo al superadmin?

## 2. Materiale

### Stato attuale

- Corso "Introduzione al Percorso Integrato": 6 capitoli in bozza, ancora da scrivere.
- Corso "La prima settimana con PosturaCorretta": 7 capitoli.
- Corso "Postura e fisiologia": capitoli collegati alla lezione introduttiva.
- Corsi di Igiene Posturale e Area Massaggio: da verificare uno per uno.

### Domande

1. Per "finire il materiale" intendi i capitoli online, le schede pratiche delle lezioni, o entrambi?

## 3. Primi due gruppi

Mark insegna in due sedi. Strumenti già presenti: `DataSession` (lezione programmata), `DataSlot`
(orario e posto) e `DataCommitment` (iscrizione della persona).

Dai documenti precedenti:

- la lezione teorica è divisa in due parti da 90 minuti e sei DataSlot (massaggio e recupero,
  movimento, meditazione; percorso salute, Giardino del Corpo, risorse e Rails4Business), vedi
  `docs/progressione_lezioni_datasession_slots.md`;
- le lezioni possono essere in presenza, online o ibride;
- Mark è già l'insegnante idoneo per il modulo `introduzione` (pannello Insegnanti).

### Domande

1. Quali sono le due sedi?
2. Ogni gruppo segue l'intera linea (Introduzione → Prima settimana → Postura e fisiologia → …) o un
   solo corso?
3. Le date sono già decise?

## 4. Tirocinio e certificato insegnante

### Decisioni (14 novembre 2026)

**Nessun Node di tirocinio.** Ogni Node lezione ha due crocette: *tirocinio in singolo* e *tirocinio
in gruppo*. Una lezione senza crocette non ha tirocinio. La "linea del tirocinio" è l'elenco delle
lezioni con crocetta, parallela ai corsi.

**Regola per ogni lezione con crocetta** (in singolo e/o in gruppo, sempre con l'insegnante presente):

| | Partecipa come allievo | Guida come tirocinante |
|---|---|---|
| Non professionista | 2 volte | 1 volta |
| Professionista (ruolo `professionista`) | da decidere | da decidere |

L'insegnante formatore conferma ogni partecipazione e ogni guida. I progressi dei tirocinanti stanno
nel database, non in git.

**Il diploma è un ruolo.** Completate le lezioni di un corso, il tirocinante riceve il ruolo
operativo `insegnante` legato al **Node corso**: un ruolo per corso. Il ruolo padre è quello
dell'insegnante formatore che lo rilascia, così resta scritto chi l'ha formato.

- **Insegnante**: conduce le lezioni dei corsi per cui ha il ruolo.
- **Insegnante formatore**: conduce, segue i tirocinanti e rilascia i diplomi. Per ora è solo Mark.

**Copia dei ruoli in git** (`config/roles.yml`), solo dati già pubblici:

```yaml
roles:
  - username: mariorossi
    domain: posturacorretta.org
    node: igiene-posturale
    role: insegnante
    issued_by: markpostura
    issued_on: 2026-12-10
```

- Il diploma si rilascia in produzione, poi si esporta in `config/roles.yml` e si fa il commit.
- Al deploy l'import **aggiunge i mancanti e non toglie mai**. Le righe esistenti non vengono
  modificate: le differenze vengono solo segnalate.
- Si revoca solo in modo esplicito, con `revoked_on:`.
- Oggi gli insegnanti del pannello Insegnanti vengono dal catalogo YAML dell'accademia: andranno letti
  dai ruoli, per non avere due elenchi.

Dai documenti precedenti:

- ramo professionale: formazione → pratica personale → tirocinio → abilitazione. Il certificato
  insegnante corrisponde all'**abilitazione**;
- il tirocinio non è pubblico: si apre solo a chi ha completato il corso richiesto, ha chiesto o
  ottenuto l'iscrizione al percorso insegnante e ha i permessi;
- ordine dei ruoli da sviluppare: utente → tirocinante → insegnante → segreteria dei centri →
  amministrazione.

### Domande

1. Per il professionista: 1 volta allievo e 1 volta guida, oppure solo guida?

## 5. Dopo

- Insegnanti e centri nella home e nella pagina del percorso.
- Carte scaricabili o acquistabili.
- **Mappa del percorso di una persona**: vedere sulla mappa metropolitana le tappe percorse, a
  partire dagli eventi (`DataCommitment`, `DataSlot`, `DataSession`). Regola già decisa: quanto già
  percorso resta valido. Passando a un pacchetto più lungo i Node completati restano completati, si
  apre solo il tratto aggiuntivo e la cartina distingue il fatto da ciò che resta.

## Appunti sulla home

- La parte in alto ha la metà destra vuota: manca un'immagine o la metropolitana delle prime tappe.
- Dopo le card la pagina finisce: mancano insegnanti, sedi, contatto e footer.
- Il menu ha solo "Home".

## Documenti precedenti

Questo è il documento di lavoro principale. Quelli superati sono in `docs/archivio/`:

| Documento | Stato |
|---|---|
| `posturacorretta_offerte_listino.md` | **Riferimento** delle voci del listino (lo modifica Mark) |
| `progressione_lezioni_datasession_slots.md` | **Valido**: sessioni, sei DataSlot, griglia della mappa |
| `posturacorretta_slot4_percorso_salute.md` | **Valido**: slot 4 Nutrire il corpo |
| `archivio/posturacorretta_iniziare_modalita_tirocinio.md` | **Superato** da questo documento |
| `archivio/posturacorretta_linee_home_logica_vendita.md` | In parte superato (ordine della prima linea); vale la regola "quanto percorso resta valido" |
| `archivio/posturacorretta_home_corsi.md`, `archivio/posturacorretta_home_ingressi.md` | In parte superati dalla home a listino; valgono le regole tecniche su `tappa`/`tab` e sul tirocinio non pubblico |
| `posturacorretta_servizi_dashboard_linee_metropolitane.md` | Visione generale e ruoli, ancora valida come bozza |
| `posturacorretta_titoli_node_primi_sette_corsi.md`, `posturacorretta_revisione_rete_node_titoli.md` | Da verificare con i Node attuali |
| `posturacorretta_home_tre_punti.md`, `posturacorretta_home_valutazione_interventi.md`, `visione_posturacorretta_bozza.md` | Visione e principi (agosto–ottobre) |
| `posturacorretta_metodiche_*`, `node_show_posturacorretta_layout.md`, `posturacorretta_refactoring_guide.md`, `posturacorretta_catalogo_contenuti.md`, `posturacorretta_piano_contenuti_collaborativi.md` | Temi diversi (metodiche, layout, guide, contenuti) |
