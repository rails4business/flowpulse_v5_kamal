# Flowpulse — Guida di integrazione della pagina “Sovranità, Progetti e Comunità”

Prototipo visuale associato (privato, solo superadmin):
`docs/private_prototypes/viste_html/flowpulse_sovranita_progetti_community.html`.

Il prototipo è raggiungibile dall'area Flowpulse e dal footer di 1Impegno. Il
registro dati di riferimento resta `config/data/flowpulse/projects.yml`.

## Scopo

Questa pagina non è una landing page commerciale tradizionale.

Deve diventare la **pagina pubblica di raccordo** fra:

- la visione di Flowpulse;
- i progetti interni;
- i progetti nati o sostenuti tramite GeneraImpresa;
- persone che hanno già un progetto;
- community esterne già attive;
- persone che vogliono aderire, contribuire o utilizzare un progetto;
- avanzamenti, bisogni e prossimi obiettivi dei progetti.

Il principio principale è:

> Flowpulse non deve possedere tutti i progetti. Deve rendere più facile farli nascere, organizzarli, collegarli e sostenerli quando contribuiscono alle sovranità.

---

## Narrazione principale da mantenere

La sequenza concettuale è questa:

### 1. PosturaCorretta

**Conoscere tramite l’esperienza come funzioniamo e riattivare i nostri sistemi fisiologici.**

PosturaCorretta è il punto di partenza educativo.

Non presentarlo come “cura del dolore”.

Il percorso parte da:

- esperienza corporea;
- metodiche posturali;
- percezione;
- movimento;
- fisiologia;
- riattivazione;
- coscienza corporea.

### 2. Percorso Integrato

**Percorso per la salute del corpo.**

Quando serve un intervento coordinato per la salute:

- obiettivi;
- valutazioni;
- professionisti;
- attività;
- verifiche;
- percorso individuale.

### 3. Il Giardino del Corpo

**Oltre la salute del corpo: prenderci cura del mondo in cui viviamo.**

Le tre aree del Giardino del Corpo sono:

- Salute
- Risorse
- Apprendimento

Devono essere raccontate come un tutt’uno.

Il concetto è:

> Se il corpo sta meglio, possiamo usare le nostre energie per conoscere, creare, imparare, lavorare, coltivare, esprimerci, partecipare e prenderci cura del territorio e delle relazioni.

---

# Le sovranità

La pagina usa come mappa:

- Sovranità Monetaria
- Sovranità Politica
- Sovranità sul Territorio
- Sovranità Alimentare
- Sovranità sulla Salute
- Sovranità Educativa
- Sovranità Personale

Non presentare la sovranità come isolamento o autosufficienza assoluta.

Definizione consigliata:

> Capacità progressiva di comprendere, scegliere, organizzarsi e collaborare senza dipendere inutilmente da un unico sistema.

---

# Sovranità personale: strumenti concreti

Questi progetti/strumenti vanno collegati alla sovranità personale.

## GeneraImpresa — Abbondanza

Scopo:

- sostenere persone che hanno un progetto;
- far partire imprese o progetti necessari;
- verificare che abbiano un uso concreto;
- cercare una fattibilità tecnica;
- cercare una fattibilità organizzativa;
- cercare una fattibilità economica;
- trovare risorse;
- trovare persone;
- trovare partner;
- trovare strumenti;
- trovare primi utenti;
- verificare costi e possibili ricavi.

GeneraImpresa NON deve diventare una semplice raccolta di idee.

Ogni progetto deve poter mostrare:

- problema/bisogno;
- soluzione;
- destinatari;
- stato;
- avanzamento percentuale;
- ultimo risultato;
- prossimo obiettivo;
- risorse necessarie;
- persone cercate;
- modello economico;
- aggiornamenti;
- modalità di partecipazione.

## Professionisti digitali / Rails4Business — Realizzazione

Servono per portare a compimento progetti che necessitano di:

- sviluppo software;
- Rails;
- siti;
- UI;
- automazioni;
- dati;
- integrazioni;
- contenuti;
- strumenti digitali.

## 1Impegno — Organizzazione e responsabilità

Deve servire a:

- obiettivi;
- calendario;
- attività;
- responsabilità;
- progressione;
- prossimi passi;
- organizzazione personale;
- organizzazione dei progetti.

## Canta che ti passa — Armonia

Area:

- canto;
- musica;
- espressione;
- pratica;
- apprendimento musicale;
- armonia personale.

## Calendario delle stagioni

Scopo:

- conoscere i cicli naturali;
- conoscere attività agricole e territoriali;
- recuperare tradizioni;
- collegare eventi alle stagioni;
- conoscere piante, colture, territorio e produzioni locali.

## Inside Adventure

Scopo:

- teatro;
- lettura;
- linguaggio;
- esplorazione;
- capacità cognitive;
- possibilità dell’essere umano;
- esperienze di apprendimento.

---

# Progetti della rete

Questa è la parte più importante da trasformare in dati Rails.

La pagina deve mostrare **tre tipi di progetto**.

## A. Progetti Flowpulse

Esempi:

- PosturaCorretta
- Percorso Integrato
- Il Giardino del Corpo
- 1Impegno
- Rails4Business
- GeneraImpresa

## B. Progetti avviati o sostenuti tramite GeneraImpresa

Non necessariamente diventano proprietà di Flowpulse.

Devono poter avere:

- proprietario/responsabile proprio;
- pagina propria;
- aggiornamenti;
- partecipanti;
- bisogni;
- metriche;
- collegamenti ad altri progetti.

## C. Progetti/community esterne già attive

Esempio principale:

- Dash / Digital Cash

Flowpulse non deve duplicarli.

Deve mostrare:

- cosa fanno;
- perché sono coerenti con una o più sovranità;
- come aderire;
- come contribuire;
- come possono collegarsi ai progetti Flowpulse;
- eventuali obiettivi comuni.

In futuro possono entrare altri progetti indipendenti.

---

# Modello dati Rails consigliato

Non implementare tutto obbligatoriamente in una volta.

Partire da `Project`.

```ruby
Project
  name:string
  slug:string
  summary:text
  description:text

  project_type:string
  # flowpulse
  # generaimpresa
  # community
  # independent

  status:string
  progress:integer

  owner_name:string
  website_url:string

  current_goal:text
  last_result:text
  economic_model:text

  active:boolean
  open_to_participation:boolean

  published_at:datetime
```

## ProjectUpdate

```ruby
ProjectUpdate
  project:references
  title:string
  body:text
  progress:integer
  published_at:datetime
```

Serve per creare una vera timeline pubblica dell’avanzamento.

Esempio:

- 10 settembre — completato prototipo;
- 20 settembre — primi 5 tester;
- 1 ottobre — avviata sperimentazione;
- 15 ottobre — raggiunto primo cliente.

---

## ProjectNeed

```ruby
ProjectNeed
  project:references

  title:string
  description:text

  need_type:string
  # person
  # skill
  # money
  # place
  # equipment
  # partner
  # user
  # developer
  # professional

  status:string
```

La pagina deve poter mostrare:

> Questo progetto sta cercando:
> sviluppatore Rails · fisioterapista · spazio · produttore locale · 10 tester

---

## ProjectParticipation

```ruby
ProjectParticipation
  project:references
  user:references

  role:string
  status:string

  message:text
```

Possibili ruoli:

- interessato;
- partecipante;
- professionista;
- collaboratore;
- tester;
- sviluppatore;
- organizzatore;
- partner;
- sostenitore.

---

## Sovereignty

```ruby
Sovereignty
  name:string
  slug:string
  description:text
```

Relazione molti-a-molti:

```ruby
ProjectSovereignty
  project:references
  sovereignty:references
```

Un progetto può contribuire a più sovranità.

Esempio Dash:

- Monetaria
- Politica
- Economica

Esempio PosturaCorretta:

- Salute
- Educativa
- Personale

---

# Community / organizzazioni

Se serve distinguere un progetto dalla comunità che lo gestisce:

```ruby
Organization
  name:string
  slug:string
  description:text
  website_url:string
  organization_type:string
```

Poi:

```ruby
Project belongs_to :organization, optional: true
```

Esempi:

- Flowpulse
- Dash Community
- associazioni locali;
- imprese;
- gruppi;
- cooperative;
- comunità.

---

# Pagina indice

Route consigliata:

```ruby
get "/progetti", to: "projects#index"
```

La pagina deve permettere filtri:

- Tutti
- Flowpulse
- GeneraImpresa
- Community esterne
- Progetti indipendenti
- Cercano persone
- Sovranità

Esempio query:

```ruby
@projects = Project
  .where(active: true)
  .includes(:sovereignties, :project_needs)
  .order(updated_at: :desc)
```

---

# Scheda progetto

Route:

```ruby
resources :projects, only: [:index, :show]
```

Ogni `/projects/:slug` dovrebbe avere:

1. nome;
2. organizzazione;
3. descrizione;
4. sovranità;
5. stato;
6. percentuale avanzamento;
7. ultimo risultato;
8. prossimo obiettivo;
9. timeline aggiornamenti;
10. bisogni aperti;
11. persone/ruoli cercati;
12. modello economico, quando pubblico;
13. link ufficiali;
14. bottone “Partecipa”;
15. progetti collegati.

---

# GeneraImpresa

GeneraImpresa può diventare una vista/pipeline dei progetti.

Stati consigliati:

```text
idea
↓
analisi
↓
fattibilità
↓
modello economico
↓
prototipo
↓
test
↓
attivo
↓
sostenibile
```

La percentuale di avanzamento NON deve sostituire questi stati.

La percentuale comunica rapidamente.

Lo stato spiega in quale fase reale si trova il progetto.

---

# Dashboard progetto

Per ogni responsabile progetto prevedere una piccola dashboard:

```text
PROGETTO
Nome

STATO
Prototipo

AVANZAMENTO
58%

ULTIMO RISULTATO
Primo test completato

PROSSIMO OBIETTIVO
10 utenti reali

CERCHIAMO
1 developer
2 tester
1 partner

AGGIORNAMENTO
Pubblica aggiornamento
```

Questo permette alla pagina pubblica di non diventare obsoleta.

---

# Collegamenti fra progetti

Creare in futuro:

```ruby
ProjectConnection
  source_project:references
  target_project:references

  connection_type:string
  description:text
```

Tipi:

- collaborates_with
- uses
- supports
- supplies
- funded_by
- developed_by
- participates_in
- accepts_payment_with
- member_of

Esempio:

```text
PosturaCorretta
    ↓ usa
1Impegno

PosturaCorretta
    ↓ sviluppato con
Rails4Business

Flowpulse projects
    ↓ sperimentano pagamenti
Dash

GeneraImpresa
    ↓ sostiene
Nuovo progetto locale
```

Questa relazione sarà utile per creare in futuro una **mappa visuale dell’ecosistema**.

---

# Dash / Digital Cash

Dash deve essere presentato come **community e infrastruttura esterna già attiva**, non come progetto Flowpulse.

Flowpulse può costruire un percorso:

```text
conoscere Dash
↓
creare wallet
↓
utilizzarlo nei progetti
↓
abilitare servizi/pagamenti
↓
misurare adozione
↓
entrare nella community
↓
contribuire
↓
presentare proposal
↓
ottenere eventualmente sostegno dalla treasury
↓
accumulare progressivamente DASH
↓
1.000 DASH
↓
masternode
↓
partecipazione diretta alla governance Dash
```

Importante:

la proposal non deve essere descritta come sistema per finanziare genericamente Flowpulse.

Una proposal deve avere un beneficio concreto e misurabile per l’ecosistema Dash.

Esempi possibili:

- wallet onboarding;
- merchant adoption;
- eventi;
- integrazione software;
- strumenti open source;
- formazione;
- caso d’uso territoriale;
- metriche di adozione.

---

# Regola editoriale

Quando ChatGPT modifica questa pagina:

NON trasformarla in:

- pagina crypto;
- pagina politica;
- pagina business;
- catalogo di marchi;
- manifesto astratto.

Mantenere sempre la storia:

```text
PERSONA
↓
CORPO
↓
POSTURACORRETTA
↓
PERCORSO INTEGRATO
↓
GIARDINO DEL CORPO
↓
SALUTE · RISORSE · APPRENDIMENTO
↓
SOVRANITÀ
↓
PROGETTI
↓
PERSONE + COMPETENZE + RISORSE
↓
RETE
↓
COMMUNITY
↓
PARTECIPAZIONE
```

Dash entra successivamente come uno dei progetti/community esterni più importanti per:

- sovranità monetaria;
- scambi;
- proposal;
- governance.

---

# Migrazione dall’HTML prototipo

Il file HTML allegato contiene un array JavaScript:

```javascript
const projects = [...]
```

È soltanto un mockup.

Nel progetto Rails sostituire l’array con dati dal database.

Esempio partial:

```erb
<%= render partial: "projects/project_card",
           collection: @projects,
           as: :project %>
```

Creare preferibilmente:

```text
app/views/projects/index.html.erb
app/views/projects/_project_card.html.erb
app/views/projects/show.html.erb
app/views/project_updates/_project_update.html.erb
app/views/project_needs/_project_need.html.erb
```

Se il progetto usa Hotwire, i filtri possono essere implementati con Turbo Frames o Stimulus.

Non introdurre React se non è già necessario.

---

# Prima implementazione consigliata

Realizzare solo:

1. `Project`
2. `ProjectUpdate`
3. `ProjectNeed`
4. `Sovereignty`
5. pagina `/progetti`
6. pagina `/progetti/:slug`
7. bottone “Partecipa”
8. form per aggiornamento progetto

Poi aggiungere:

- Organization
- ProjectParticipation
- ProjectConnection
- dashboard
- mappe visuali
- metriche
- integrazione Dash.

---

# Obiettivo finale

Una persona che arriva sulla pagina deve poter rispondere subito a cinque domande:

1. **Qual è la visione?**
2. **Quali progetti esistono già?**
3. **A che punto sono?**
4. **Dove c’è bisogno di me?**
5. **Come posso partecipare o portare un mio progetto?**

Se una modifica rende una di queste risposte meno chiara, va rivista.
