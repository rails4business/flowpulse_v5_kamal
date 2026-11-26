# Percorso Integrato — home come scheda della persona

Un punto alla volta: si discute, si implementa, si verifica in locale, si segna `[x]`.
Stesso linguaggio grafico della scheda PosturaCorretta ([`posturacorretta_home_ux_progressione.md`](posturacorretta_home_ux_progressione.md)).

## Decisioni (26/11/2026)

- La home di `percorsointegrato.it` (in locale `/percorso-integrato`) diventa una **scheda di esempio** con una persona
  di fantasia, segnata chiaramente "Esempio". Chi fa l'accesso vedrà in futuro la propria scheda.
- Per ora **solo la vista**, in stile cartella: niente salvataggio di dati.
- Struttura:
  1. **La persona**: nome e cognome, email, telefono (facoltativo).
  2. **La richiesta**: rosso dolore/patologia, verde benessere, blu educazione del paziente (anche più di uno) +
     descrizione.
  3. **Presa in carico**: professionista referente, data, valutazione, proposta di percorso.
  4. **Professionisti** (sempre visibili, sopra le schede): una riga per professionista con nome, ambito (colore),
     visita e programma.
  5. **Schede**: Tutti · Patologia (rosso) · Benessere (verde) · Educazione (blu) · Autonomia.
     - Tutti e i tre colori: sedute con data, professionista, dove, cosa.
     - Autonomia: settimana tipo da ripetere (lunedì–domenica); il mensile si valuta dopo.
- I dati dell'esempio stanno in un YAML in `config/data/brands/percorso-integrato/`, non nella vista.
- Stampa: tutte le sezioni; delle schede solo "Tutti" e "Autonomia" (le sedute non si ripetono). Telefono: barra delle
  schede scorrevole.
- La home attuale passa in una pagina **About**.

## Attenzione

Dolore, patologia e trattamenti sono dati sanitari (categoria particolare GDPR). La scheda in home resta un esempio
senza salvataggio; la scheda vera della persona dovrà stare nell'area privata, con accessi controllati e consenso
specifico.

## Punti

1. [x] **About**: la home attuale va su `/percorso-integrato/about`, con il link nel menu (desktop e telefono).
   Quando la home diventa la scheda (punto 3), il pulsante "Inizia" del menu (`percorso_integrato_path(anchor:
   "inizia")`) va fatto puntare al riquadro giusto.
2. [ ] **Dati di esempio** nel YAML (persona di fantasia, richiesta, presa in carico, due o tre professionisti,
   sedute, settimana di autonomia): bozza da correggere.
3. [ ] **Vista della scheda** in home: sezioni 1–4.
4. [ ] **Schede** Tutti / colori / Autonomia (a schermo con le etichette, sul telefono scorrevoli).
5. [ ] **Stampa** con "Scarica o stampa" (riuso dell'intestazione e del controller della scheda PosturaCorretta).
6. [ ] Più avanti: scheda personale dopo l'accesso, dati veri, permessi e consenso.
