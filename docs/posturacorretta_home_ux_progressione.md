# Home PosturaCorretta — UX: stato dei lavori

Un punto alla volta: si discute, si implementa, si verifica in locale, si segna `[x]`.

Documenti collegati: [`ecosistema_persona_tre_progetti.md`](ecosistema_persona_tre_progetti.md) (Il Giardino del
Corpo è un progetto distinto), [`posturacorretta_home_valutazione_interventi.md`](posturacorretta_home_valutazione_interventi.md),
[`richieste_profili_iscrizioni.md`](richieste_profili_iscrizioni.md).

## Fatto (26/11/2026, non committato, test non ancora lanciati)

- [x] **Capitolo 2 nuovo** "Come si affronta il programma: Scopri, Pratica, Approfondisci" nel corso
  `inizia-con-posturacorretta` (`course.yml` + `chapters/come-si-affronta-il-programma.md`, `demo: true`).
  Importato e pubblicato in sviluppo. **In produzione: dopo il deploy pubblicarlo subito con "Pubblica"**, altrimenti
  blocca il "Segna come letto" dei capitoli successivi.
- [x] **Home senza barra delle schede.** Tolto il blocco Scopri/Pratica/Approfondisci (ora nel capitolo 2); "Scopri di
  più" porta al capitolo. Sotto la scheda tre sezioni con "Vai" (Percorso educativo, Consapevolezza, Connessione).
- [x] **Pagine `?area=…`**: breadcrumb "Home › Area" al posto delle schede; `?area=intro` → 301 alla home.
- [x] **Scheda del programma** (`_program_sheet.html.erb`), una sola per schermo e stampa: il corso è un titolo nel
  cerchio; ogni lezione ha due righe (☐ Online/Centro/Domicilio, icone singolo/gruppo; data `__/__/__ __:__`, centro,
  firma del professionista); legenda delle icone. I capitoli non compaiono in home (sono materiale della lezione e
  stanno nello show).
- [x] **Riquadro "I tuoi dati"** in fondo alla scheda (`_participant_box.html.erb`): modulo Nome e cognome, Email,
  Telefono facoltativo + privacy, che invia la richiesta PosturaCorretta esistente (`BrandRequest`, `kind: access`);
  per chi ha fatto l'accesso mostra i dati; in stampa diventa righe da compilare.
- [x] **Pagina bianca nel PDF**: `print_date_controller.js` non annulla più lo spostamento della scheda quando
  Stimulus lo stacca e riattacca.

## Da fare, un punto alla volta

1. [ ] Lanciare `bin/rails test test/controllers/nodes_controller_test.rb`.
2. [ ] Tipo di richiesta distinto per le iscrizioni al programma (es. `iscrizione_programma`): prima verificare i
   `kind` usati e il pannello del Brand.
3. [ ] Dopo "Iscriviti" tornare alla home con un messaggio (oggi si finisce su "Richiedi un invito").
4. [ ] Hero: togliere o riformulare "Salute perfetta con PosturaCorretta".
5. [ ] Telefono: "1 / 7" si sovrappone a "Continua" nel piè di pagina della scheda.
6. [ ] Decidere: approvazione delle iscrizioni a mano o automatica; "Richiedi accesso" nel menu sì/no.
7. [ ] Testi delle tre sezioni da completare (Percorso educativo).
8. [ ] Più avanti: precompilare la scheda con prenotazioni e conferma dell'insegnante; data di completamento.

## Questioni aperte collegate

- Pagine doppie: `/posturacorretta/espressione`, `/consapevolezza`, `/connessione` e `?area=…` mostrano lo stesso
  contenuto; decidere quale tenere.
- Link sul dominio reale: su `posturacorretta.org` i link devono puntare alla radice, non a `/posturacorretta/...`.
- Flusso dati sviluppo/produzione: revisione rimasta aperta in
  [`prompts/flusso_dati_sviluppo_produzione_db_yml_md.md`](prompts/flusso_dati_sviluppo_produzione_db_yml_md.md)
  (lavoro coi file in locale, registro in entrambi i DB, conflitti, scarico della produzione, passaggio da
  `config/data` a `docs/dati`).
