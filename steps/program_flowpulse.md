# Programma Flowpulse

Questo file raccoglie idee, moduli e passi utili da inserire nella app. Serve come lista viva: prima si chiarisce cosa conviene fare a mano, poi cosa trasformare in componenti, gemme o engine riusabili.

## Principio di lavoro

- Tenere il core semplice e visibile.
- Prima modellare bene i dati, poi automatizzare.
- Usare gemme solo quando riducono davvero complessita o danno una base solida.
- Preferire piccoli passi verificabili rispetto a un grande sistema astratto.


## 1. Weekplan con eventi

Il weekplan dovrebbe diventare un modulo vivo, non solo una vista HTML.

Obiettivo:

- Visualizzare settimana, giorni, fasce orarie ed eventi.
- Collegare eventi a brand, percorso, routine, luogo, persona o dominio.
- Permettere vista pubblica e vista admin.

Funzioni utili:

- Eventi singoli e ricorrenti.
- Filtri per brand, area, persona, luogo, tipo evento.
- Stato evento: bozza, pubblicato, annullato, completato.
- Duplicazione rapida di una settimana.
- Esportazione futura in calendario esterno.

Gemme da valutare:

- `ice_cube` per ricorrenze.
- `icalendar` per esportare/importare calendari.
- `noticed` se serviranno notifiche interne.





## 1. rails_tree_sortable

Modulo/gemma per ordinare strutture ad albero.

Uso possibile:

- Menu.
- Percorsi.
- Moduli di contenuto.
- Routine composte.
- Sezioni pagina.
- Categorie e tassonomie.

Idea:

- Tree ordinabile con parent/children.
- Drag and drop via Stimulus.
- Persistenza posizione.
- API Rails semplice per riordinare.

Gemme/pattern da valutare:


- `closure_tree` se servono query gerarchiche piu robuste.
- `acts_as_list` per ordinamento tra fratelli.
- SortableJS via importmap o pacchetto JS leggero.



Modulo/gemma base per liste ordinabili non gerarchiche.

Da aggiungere:

- Content sortable: sezioni, blocchi, card, moduli di una pagina.
- Ordinamento admin con drag and drop.
- Endpoint standard per aggiornare posizioni.
- Helper Rails per generare liste ordinabili.

Uso possibile:

- Blocchi di una pagina pubblica.
- Eventi in evidenza.
- Risorse.
- Step di un percorso.
- Esercizi in una routine.

closure_tree è più strutturata: usa una tabella gerarchica separata e nasce proprio per alberi efficienti, con antenati/discendenti/sottoalberi e mutazioni più robuste.

Per il tuo caso:

rails_flow_tree_sortable_list
direi:

Card
  has_closure_tree order: "position"

con campi tipo:

title
content_type
parent_id
position
depth/cache opzionale
brand_id opzionale
journey_id opzionale

Poi sopra ci costruisci:

Rails model tree
↓
Stimulus controller
↓
SortableJS / nested drag-drop
↓
Turbo update
↓
Tailwind component

La cosa importante: non fare una gemma subito. Farei prima una mini app Rails pulita che ricostruisce solo:

albero card
drag & drop
cambio parent
cambio ordine
rendering Tailwind
API update posizione

Poi, quando funziona bene, la estrai come engine/gemma.

Nome buono:

rails_flow_tree_sortable

oppure più chiaro:

flow_tree_sortable

Io eviterei di rifare pari pari app_sortable_nested_ul_li_list: usala come repository archeologica, recuperi idee, logiche e UI, ma riparti con Rails 8 + Hotwire + Stimulus + Tailwind.

Scelta finale:

closure_tree = struttura solida per Flowpulse/PosturaCorretta



## 1. Domini

La gestione dei domini probabilmente e la prima cosa da consolidare, ma e anche una delle piu delicate.

Stato consigliato per ora:

- Gestione manuale assistita da admin interno.
- Record `Domain` nel database come sorgente runtime principale.
- Import/export YAML per lavorare in sicurezza e tenere backup leggibili.
- Evitare per il momento automazioni DNS complete, perche aumentano molto il rischio operativo.

Da chiarire:

- Ogni dominio punta a una pagina pubblica, un controller/action o un progetto?
- Serve un dominio canonico e alias `www` per ogni progetto?
- Serve una preview/staging per provare un dominio prima di renderlo attivo?
- Come gestire dominio, lingua, tema, layout e contenuti dedicati nello stesso record?

Possibili step:

1. Rendere l'admin domini comodo e sicuro.
2. Aggiungere stato: `draft`, `active`, `paused`.
3. Aggiungere anteprima dominio senza pubblicazione piena.
4. Aggiungere validazioni su host, canonical host, action e locale.
5. Solo dopo valutare automazioni DNS/deploy.



## 5. Content

Serve un livello contenuti piu ordinato, senza diventare subito un CMS enorme.

Tipi possibili:

- Pagina.
- Sezione.
- Blocco.
- Card.
- Media.
- Call to action.
- Gallery.
- Risorsa scaricabile.

Decisione utile:

- Partire con blocchi semplici e template ERB.
- Evitare editor visuale troppo presto.
- Tenere campi strutturati quando il contenuto deve essere filtrabile o riusabile.

Gemme da valutare:

- `friendly_id` per slug leggibili.
- `mobility` se la traduzione multilingua diventa centrale.
- `acts-as-taggable-on` solo se le tassonomie non bastano.
- Active Storage gia disponibile per media e allegati.

## 6. Percorsi

I percorsi sembrano uno dei mattoni centrali di Flowpulse.

Struttura possibile:

- Percorso.
- Moduli o tappe.
- Lezioni/contenuti.
- Eventi collegati.
- Routine collegate.
- Risorse.
- Progressi utente.

Domande:

- Un percorso e pubblico, privato o misto?
- E legato a un brand/dominio?
- Ha iscrizione, pagamento o solo consultazione?
- Puo avere date fisse o essere evergreen?

## 7. Routine

Le routine possono collegare salute, lavoro, esercizi, abitudini e follow-up.

Struttura possibile:

- Routine.
- Step.
- Frequenza.
- Durata.
- Materiali.
- Check-in.
- Storico completamenti.

Collegamenti:

- Routine dentro percorsi.
- Routine assegnate a utenti/gruppi.
- Routine pubbliche come contenuto.
- Routine con eventi ricorrenti nel weekplan.

## 8. Transaction

Le transaction sono probabilmente da lasciare dopo domini, contenuti, percorsi e routine, perche richiedono un modello piu stabile.

Possibili significati:

- Pagamenti.
- Iscrizioni.
- Prenotazioni.
- Acquisti.
- Movimenti interni o crediti.
- Passaggi di stato tracciabili.

Gemme/servizi da valutare:

- `pay` per pagamenti Rails, se serve Stripe o simili.
- `money-rails` per importi e valute.
- `aasm` o `state_machines-activerecord` per stati complessi.
- `paper_trail` per audit/versioni, se serve sapere chi ha cambiato cosa.

## 9. Altre gemme utili da valutare

Qualita e sicurezza:

- `annotate` per leggere meglio modelli e schema.
- `strong_migrations` prima di fare migrazioni delicate in produzione.
- `rack-attack` per protezione base da traffico aggressivo.

Admin e UX interna:

- Hotwire e Stimulus, gia presenti, come base principale.
- ViewComponent o Phlex solo se i partial diventano troppo difficili da mantenere.
- `pagy` per paginazione leggera.

Ricerca:

- Prima query Rails semplici.
- `pg_search` quando PostgreSQL sara il database centrale.
- Search esterna solo molto piu avanti.

Media:

- Active Storage, gia pronto.
- `image_processing`, gia presente.
- Eventuale CDN/ottimizzazione immagini dopo il deploy stabile.

## Ordine suggerito

1. Consolidare domini manuali e admin.
2. Trasformare weekplan in modello eventi.
3. Estrarre sortable semplice: `rails_flow_sortable`.
4. Estendere ad alberi: `rails_flow_tree_sortable`.
5. Ordinare contenuti in blocchi/template.
6. Modellare percorsi.
7. Modellare routine.
8. Collegare routine, eventi e percorsi.
9. Introdurre transaction solo quando il flusso utente e chiaro.

## Note operative

- La gestione domini conviene tenerla manuale finche non e stabile il modello mentale.
- Weekplan, percorsi e routine dovrebbero condividere eventi, persone, luoghi e brand.
- Sortable e tree sortable possono diventare gemme interne solo dopo averli usati almeno in due punti reali della app.
- Le transaction vanno progettate con cautela: quando entrano soldi, iscrizioni o stati ufficiali, serve meno fantasia e piu tracciabilita.


