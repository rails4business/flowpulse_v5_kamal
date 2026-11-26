# Percorso Integrato — home come scheda della persona

Un punto alla volta: si discute, si implementa, si verifica in locale, si segna `[x]`.
Stesso linguaggio grafico della scheda PosturaCorretta ([`posturacorretta_home_ux_progressione.md`](posturacorretta_home_ux_progressione.md)).

## Decisioni (26/11/2026)

- La home di `percorsointegrato.it` (in locale `/percorso-integrato`) diventa una **scheda di esempio** con una persona
  di fantasia, segnata chiaramente "Esempio". Chi fa l'accesso vedrà in futuro la propria scheda.
- Per ora **solo la vista**, in stile cartella: niente salvataggio di dati.
- Struttura:
  1. **La persona**: nome e cognome, email, telefono (facoltativo).
  2. **La richiesta**: un solo ambito tra rosso dolore/patologia, verde benessere, blu educazione del paziente +
     descrizione. Professionisti e sedute possono poi toccare anche altri ambiti.
  3. **Apertura del percorso (presa in carico)**: chi apre il percorso, data, valutazione, proposta di percorso con le
     aree su cui lavorare (recupero, movimento, mente, nutrizione, piante/integratori/medicinali: chiavi della
     tassonomia `areas`, etichette nella scheda) + note. Colori delle aree dalla tassonomia: viola recupero, verde
     movimento, rosso mente, arancio nutrizione, blu piante/integratori/medicinali.
     Non è un programma: chi apre il percorso è uno dei professionisti e scrive poi il suo programma come gli altri.
  4. **Professionisti**: uno per riquadro con nome, ambito (colore), visita/valutazione e programma proposto.
  5. **Calendario**: Tutte · Patologia (rosso) · Benessere (verde) · Educazione (blu) | Autonomia.
     - Tutte (selezionata all'inizio) e i tre colori: sedute con data, professionista, dove, cosa.
     - Autonomia: settimana tipo da ripetere (lunedì–domenica); il mensile si valuta dopo.
- **Tre schede principali**: Info (1–3) · Professionisti (4) · Calendario (5), come uno schedario: etichette sopra il
  foglio, quella selezionata si unisce al foglio. In fondo la fascia "Esempio" con "Completa anche tu il tuo Percorso
  Integrato →" (Linee guida `#inizia`).
- **Colori**: ambiti (richiesta, sedute) chiari, con fondo tenue e pallino; aree (proposta di percorso) piene, dalla
  tassonomia.
- I dati dell'esempio stanno in un YAML in `config/data/brands/percorso-integrato/`, non nella vista.
- Stampa: tutte le sezioni; delle schede solo "Tutti" e "Autonomia" (le sedute non si ripetono). Telefono: barra delle
  schede scorrevole.
- La home attuale passa in una pagina **About**.

## Aggiornamento — pagina Linee guida, 26 novembre 2026

La precedente presentazione About, il modello esteso e Docs confluiscono in
`/percorso-integrato/linee-guida`. La scheda di esempio resta la home.

Ordine: presentazione e tre campi; ciclo, modalità, presa in carico e livelli del modello;
ruoli; corso con otto capitoli; documentazione per argomento; contatto iniziale e passi operativi. I testi delle due
presentazioni sono estratti in partial condivisi; tutti i file Markdown e l'indice documentale
rimangono conservati. Sono consultabili 31 documenti pubblici e i tre documenti tutor restano
riservati come prima. Le ancore dei documenti sono distinte, con titoli subordinati all'unico
titolo della pagina.

Desktop e mobile espongono una sola voce “Linee guida”; il collegamento della home e il pulsante
“Inizia” puntano alla nuova pagina. `/about`, `/modello` e `/docs` restano come redirect 301;
`/docs?doc=...` apre il documento corrispondente nella pagina unica. Anche `/corso` e i vecchi
URL dei capitoli rimandano alla sezione Corso di Linee guida, con il capitolo richiesto aperto.
La voce separata “Corso” viene rimossa dal menu.

Verifica locale dell'assemblaggio: **34 test, 401 asserzioni, nessun errore o fallimento**
(Percorso Integrato, domini e compatibilità del corso Stato di salute). Controllati tutti i
documenti pubblici, l'accesso riservato ai materiali tutor, gli otto capitoli, le ancore univoche
e i redirect. RuboCop pulito sui quattro file Ruby interessati; `git diff --check` senza errori.

## Attenzione

Dolore, patologia e trattamenti sono dati sanitari (categoria particolare GDPR). La scheda in home resta un esempio
senza salvataggio; la scheda vera della persona dovrà stare nell'area privata, con accessi controllati e consenso
specifico.

## Punti

1. [x] **About**: la home attuale va su `/percorso-integrato/about`, con il link nel menu (desktop e telefono).
   Quando la home diventa la scheda (punto 3), il pulsante "Inizia" del menu (`percorso_integrato_path(anchor:
   "inizia")`) va fatto puntare al riquadro giusto.
2. [x] **Dati di esempio** in `config/data/brands/percorso-integrato/scheda_esempio.yml` (persona di fantasia,
   richiesta per patologia, presa in carico, due professionisti, cinque sedute, settimana di autonomia):
   bozza da correggere.
3. [x] **Vista della scheda** in home: sezioni 1–4 (`scheda.html.erb`, dati da `PercorsoIntegratoCatalog.example_sheet`,
   anche sul dominio vero tramite `domains#show`); "Inizia" del menu porta a About `#inizia`.
4. [x] **Schede** Info / Professionisti / Calendario e, nel Calendario, Tutte / colori / Autonomia
   (`sheet_tabs_controller.js`, partial `_scheda_sedute.html.erb`, stile `.pi-sheet-*` in fondo a `application.css`).
   Tutti i pannelli restano nella pagina; sul telefono le barre scorrono di lato.
5. [ ] **Stampa** con "Scarica o stampa" (riuso dell'intestazione e del controller della scheda PosturaCorretta).
   Oggi il PDF esce bianco: la regola globale `body * { visibility: hidden }` del primo blocco `@media print` di
   `application.css` lascia visibile solo `.pc-sheet`. Da risolvere qui, senza rompere la stampa PosturaCorretta.
6. [ ] Più avanti: scheda personale dopo l'accesso, dati veri, permessi e consenso.
