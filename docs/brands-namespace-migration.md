# Ipotesi di migrazione verso lo scope `Brands`

## Obiettivo

Raccogliere sotto namespace coerenti tutto il codice dei brand, compresi GeneraImpresa e Impegno. Un brand può offrire soltanto un sito oppure anche funzionalità utilizzabili dagli altri brand.

La struttura deve permettere di:

- riconoscere immediatamente a quale brand appartiene un file;
- aggiungere nuovi brand senza affollare controller e viste principali;
- configurare dominio, titolo, descrizione, favicon e ingresso del brand nello stesso modo;
- estrarre in futuro un brand da Flowpulse con un impatto limitato;
- permettere a PosturaCorretta, SvuotaMente e altri brand di usare le funzionalità di GeneraImpresa e Impegno senza duplicarne il codice.

## Struttura finale proposta

```text
app/
├── controllers/
│   ├── brands/
│   │   ├── base_controller.rb
│   │   ├── genera_impresa/
│   │   ├── impegno/
│   │   │   └── commitments_controller.rb
│   │   ├── posturacorretta/
│   │   └── svuotamente/
│   └── domains_controller.rb
│
├── models/
│   ├── brands/
│   │   ├── genera_impresa/
│   │   ├── impegno/
│   │   │   └── commitment.rb
│   │   ├── posturacorretta/
│   │   └── svuotamente/
│   └── domain.rb
│
├── helpers/
│   └── brands/
│       ├── genera_impresa_helper.rb
│       ├── impegno_helper.rb
│       ├── posturacorretta_helper.rb
│       └── svuotamente_helper.rb
│
└── views/
    ├── brands/
    │   ├── genera_impresa/
    │   ├── impegno/
    │   ├── posturacorretta/
    │   │   ├── shared/
    │   │   ├── accademia/
    │   │   ├── contenuti/
    │   │   ├── metodiche/
    │   │   ├── percorso/
    │   │   └── progetti/
    │   └── svuotamente/
    ├── layouts/
    └── shared/
```

Anche i dati possono seguire la stessa organizzazione:

```text
config/data/
├── brands/
│   ├── genera_impresa/
│   ├── impegno/
│   ├── posturacorretta/
│   └── svuotamente/
└── shared/
```

Lo spostamento dei dati può avvenire dopo quello dei controller e delle viste, perché modifica numerosi percorsi YAML già utilizzati.

## Cosa appartiene a un brand

Un elemento va sotto `Brands` quando appartiene funzionalmente o pubblicamente a un brand. Questo vale anche quando le sue funzionalità vengono utilizzate dagli altri brand.

- ha senso soltanto per quel brand;
- utilizza palette, navigazione o contenuti specifici;
- non deve essere richiamato dagli altri domini;
- potrebbe essere estratto insieme al sito del brand.

Esempi:

- pagine Accademia, Percorso, Metodiche e Progetti di PosturaCorretta;
- catalogo pubblico di GeneraImpresa;
- calendario, timer e attività di Impegno;
- mercato, luoghi e inventario di SvuotaMente.

## Cosa deve rimanere condiviso

Restano fuori da `Brands` soltanto le fondamenta realmente comuni all’intera applicazione:

Devono restare condivisi:

- `Domain`, che decide quale brand o servizio servire;
- autenticazione, profili e autorizzazioni;
- layout e componenti realmente comuni;
- amministrazione dei domini;
- infrastruttura Flowpulse.

### Impegno è un brand condivisibile

Impegno vive interamente sotto `Brands::Impegno`, ma può essere utilizzato da PosturaCorretta, GeneraImpresa, eventi, percorsi e futuri domini.

Il modello attuale può essere trasferito senza rinominare subito la tabella:

```text
module Brands
  module Impegno
    class Commitment < ApplicationRecord
      self.table_name = "data_commitments"
    end
  end
end
```

Durante la migrazione, `DataCommitment` resterà come alias temporaneo. Gli URL `/impegni` possono rimanere invariati anche se il controller diventa `Brands::Impegno::CommitmentsController`.

PosturaCorretta e gli altri brand useranno il servizio tramite query e servizi espliciti, per esempio:

```ruby
Brands::Impegno::Calendar.for_profile(Current.user.profile, domain: current_domain)
Brands::GeneraImpresa::ProjectCatalog.for_domain(current_domain)
```

## Ruolo di `DomainsController`

`DomainsController` non dovrebbe conoscere nel dettaglio come preparare ogni brand. Dovrebbe soltanto:

1. risolvere il dominio;
2. applicare canonical host e lingua;
3. individuare il controller e l’azione configurati;
4. inoltrare la richiesta al corretto ingresso pubblico.

L’obiettivo futuro è eliminare progressivamente condizioni come:

```ruby
if target_controller == "brands/genera_impresa"
```

e utilizzare un dispatcher o una route per dominio con una lista esplicita di destinazioni consentite.

La configurazione continuerà a vivere in `config/domains.yml`:

```yaml
posturacorretta.org:
  target_controller: brands/posturacorretta
  target_action: home

generaimpresa.it:
  target_controller: brands/genera_impresa
  target_action: index

impegno.it:
  target_controller: brands/impegno
  target_action: index

svuotamente.it:
  target_controller: brands/svuotamente
  target_action: index
```

## Piano di migrazione

### Fase 1 — Base condivisa dei brand

- creare `Brands::BaseController`;
- centralizzare layout pubblico, dominio e metadati;
- definire convenzioni per header, footer, favicon e navigazione;
- aggiungere test che aprono ogni brand sia tramite route sia tramite dominio.

### Fase 2 — GeneraImpresa e SvuotaMente

Questa parte è già iniziata.

- mantenere controller e viste sotto `Brands`;
- separare i dati dei progetti GeneraImpresa dai progetti PosturaCorretta;
- trasformare gradualmente il prototipo HTML di SvuotaMente in layout e partial Rails;
- evitare dipendenze dirette dalle viste PosturaCorretta.

### Fase 3 — Impegno

- creare `Brands::Impegno`;
- spostare controller e viste degli impegni mantenendo `/impegni`;
- introdurre `Brands::Impegno::Commitment` sulla tabella `data_commitments`;
- mantenere temporaneamente l’alias `DataCommitment`;
- conservare i filtri per profilo, dominio e brand;
- verificare timer, sovrapposizioni e attività GeneraImpresa.

### Fase 4 — Viste PosturaCorretta

Spostare una sezione alla volta:

1. header, footer e componenti condivisi;
2. Percorso;
3. Accademia;
4. Metodiche;
5. Contenuti;
6. Eventi;
7. Libro;
8. Progetti, per ultimi perché hanno più dipendenze.

Per ogni sezione:

- spostare viste e partial;
- aggiornare i percorsi espliciti nei `render`;
- aggiornare helper e test;
- verificare route, dominio e responsive;
- eliminare il vecchio file soltanto dopo il test della nuova posizione.

### Fase 5 — Helper e cataloghi

- spostare gli helper specifici sotto `Brands::Posturacorretta`;
- separare helper di visualizzazione da calcoli economici e di progetto;
- spostare i cataloghi in namespace coerenti;
- mantenere alias temporanei per non rompere chiamate esistenti.

### Fase 6 — Dati YAML

- trasferire `config/data/posturacorretta` in `config/data/brands/posturacorretta`;
- trasferire `config/data/generaimpresa` in `config/data/brands/genera_impresa`;
- introdurre `config/data/brands/impegno` per i contenuti del sito del brand, se necessari;
- aggiungere un loader comune che costruisca i percorsi;
- evitare percorsi YAML scritti direttamente nei controller.

### Fase 7 — Pulizia finale

- rimuovere controller e alias di compatibilità;
- rimuovere cartelle storiche vuote;
- archiviare le numerose copie `.erb` non utilizzate;
- controllare che nessun riferimento punti ai vecchi percorsi;
- documentare come aggiungere un nuovo brand.

## Stima indicativa

La migrazione tecnica può essere divisa in piccoli interventi:

| Parte | Stima |
|---|---:|
| Base controller e dispatcher | 0,5–1 giornata |
| GeneraImpresa e SvuotaMente | 0,5 giornata |
| Impegno, alias e compatibilità | 1–1,5 giornate |
| Viste PosturaCorretta | 2–3 giornate |
| Helper e cataloghi | 1 giornata |
| YAML e loader | 0,5–1 giornata |
| Test, pulizia e verifica produzione | 1 giornata |

Stima complessiva prudente: **6–8 giornate di lavoro**. Può essere distribuita nel tempo senza fermare lo sviluppo delle funzionalità.

## Rischi principali

- partial richiamati tramite percorsi espliciti;
- helper che dipendono da `controller_name` o `controller_path`;
- URL generati in JavaScript o contenuti YAML;
- banner e componenti caricati automaticamente dal layout;
- file duplicati che rendono difficile capire quale vista sia effettivamente usata;
- differenze tra accesso `/posturacorretta/...` e accesso dal dominio ufficiale.

## Criteri di completamento

La migrazione sarà conclusa quando:

- ogni pagina specifica di un brand vive sotto `Brands`;
- i progetti SvuotaMente non compaiono nel catalogo PosturaCorretta;
- Impegno vive sotto `Brands::Impegno` e continua a funzionare da più domini;
- ogni dominio utilizza titolo, descrizione e favicon corretti;
- non rimangono condizioni specifiche dei brand nei layout condivisi;
- tutte le route pubbliche mantengono gli URL attuali;
- i test di dominio, controller e rendering risultano verdi.

## Strategia consigliata

Non eseguire un unico grande spostamento. Procedere per sezione, mantenendo invariati gli URL pubblici e introducendo alias temporanei. SvuotaMente e GeneraImpresa costituiscono la base già avviata; Impegno va migrato come blocco autonomo; PosturaCorretta può essere trasferito progressivamente iniziando dai componenti meno dipendenti. Fino all’avvio esplicito della migrazione, le nuove funzionalità possono continuare a essere sviluppate sulla struttura corrente evitando ulteriori spostamenti parziali.
