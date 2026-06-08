# Flow Modules, Gemme ed Engine

Questo documento raccoglie l'idea di architettura modulare per separare ruoli, dashboard, FlowTree ed eventi senza far diventare una singola gemma troppo grande.

## Obiettivo

Costruire moduli riusabili che possano vivere prima dentro questa app Rails e poi, quando sono maturi, essere estratti in gemme o engine.

La direzione consigliata e:

```text
flow_roles
  -> rails_flow_tree_sortable
  -> flow_events
  -> app host
```

Oppure, nella fase iniziale:

```text
flowpulse_v_5
  -> layer locale FlowRoles
  -> template dashboard locale
  -> prototipo FlowTree
  -> prototipo eventi
```

Solo dopo che il comportamento e stabile conviene estrarre.

## 1. Gemma `flow_roles`

`flow_roles` dovrebbe essere la gemma dei ruoli, delle modalita UI e della navigazione role-aware.

Responsabilita principali:

- definizione ruoli disponibili
- `RoleAssignment`
- ruoli globali e contestuali
- `active_role` come vista attiva
- helper tipo `superadmin_user?`, `demo_mode?`, `teacher_user?`, `tutor_user?`, `creator_user?`, `professional_user?`
- `can_access_role?`
- menu registry
- role map/audit
- dashboard home resolver
- layout dashboard opzionale
- layout landing opzionale

La gemma puo contenere layout base, ma devono restare neutri e sovrascrivibili:

```text
app/views/layouts/flow_roles/dashboard.html.erb
app/views/layouts/flow_roles/landing.html.erb
app/views/flow_roles/shared/_sidebar.html.erb
app/views/flow_roles/shared/_topbar.html.erb
app/views/flow_roles/shared/_role_switcher.html.erb
app/views/flow_roles/role_map/show.html.erb
```

La gemma non dovrebbe contenere:

- editor FlowTree
- nodi e rami dei contenuti
- eventi reali
- dominio PosturaCorretta
- logica specifica di creator world
- pagine specifiche dell'app host

Configurazione ipotetica:

```ruby
FlowRoles.configure do |config|
  config.app_name = "FlowPulse"
  config.logo_text = "FP"
  config.current_user_method = :current_user
  config.dashboard_home_path = :dashboard_home_path

  config.roles = %i[
    traveler
    demo
    creator
    teacher
    tutor
    professional
    admin
    superadmin
  ]
end
```

Uso ipotetico nell'app:

```ruby
class Admin::BaseController < ApplicationController
  layout "flow_roles/dashboard"
end
```

## 2. Engine `rails_flow_tree_sortable`

`rails_flow_tree_sortable` dovrebbe essere l'engine del contenuto ramificato.

Responsabilita principali:

- alberi
- nodi
- rami
- ordinamento sortable
- editor visuale
- pagine preview
- pubblicazione o bozza dei contenuti
- contenuti collegabili a ruoli, corsi, percorsi, eventi o creator world

Puo usare `flow_roles`, ma non dovrebbe ridefinire i ruoli.

Dipendenza ideale:

```text
rails_flow_tree_sortable dipende da flow_roles in modo opzionale/configurabile
```

Esempio:

```ruby
RailsFlowTreeSortable.configure do |config|
  config.current_user_method = :current_user
  config.role_resolver = ->(user) { FlowRoles.roles_for(user) }
  config.can_publish_resolver = ->(user) { FlowRoles.can?(user, :publish, :flow_tree) }
end
```

Route ipotetiche:

```ruby
mount RailsFlowTreeSortable::Engine => "/flow_tree"
```

Dentro l'engine:

```text
/flow_tree
/flow_tree/trees
/flow_tree/trees/:id
/flow_tree/nodes
/flow_tree/preview/dashboard
```

Ruoli tipici:

| Ruolo | Uso FlowTree |
| --- | --- |
| creator | crea format, mappe, contenuti e alberi |
| teacher | usa alberi per percorsi, corsi e lezioni |
| tutor | usa alberi per follow-up e accompagnamento |
| professional | usa alberi per servizi, protocolli, percorsi salute |
| traveler | vede contenuti pubblicati o percorsi assegnati |
| demo | vede prototipi read-only |
| admin/superadmin | audit, gestione e pubblicazione |

## 3. Gemma o engine `flow_events`

Una gemma eventi puo avere senso, ma solo se gli eventi diventano un modulo riusabile in piu contesti.

Ha senso creare `flow_events` se gli eventi devono funzionare per:

- esperienze pubbliche
- calendario admin
- creator world
- percorsi salute
- corsi e lezioni
- eventi collegati a FlowTree
- disponibilita professionisti
- prenotazioni o iscrizioni

Responsabilita possibili:

- `Event`
- calendario
- categorie evento
- date, orari e ricorrenze
- posti disponibili
- iscrizioni
- stato evento: bozza, pubblicato, archiviato
- costi e ruoli
- collegamento a organizzazioni o creator world
- collegamento a nodi FlowTree

Possibile struttura:

```text
flow_events
  app/models/flow_events/event.rb
  app/models/flow_events/registration.rb
  app/controllers/flow_events/events_controller.rb
  app/views/flow_events/events/index.html.erb
  app/views/flow_events/events/show.html.erb
  app/views/flow_events/admin/events/index.html.erb
```

Route ipotetiche:

```ruby
mount FlowEvents::Engine => "/events"
```

Oppure in italiano, se il prodotto resta italiano:

```ruby
mount FlowEvents::Engine => "/eventi"
```

Dipendenze consigliate:

```text
flow_events
  usa flow_roles per visibilita e permessi
  puo collegarsi a rails_flow_tree_sortable per contenuti e scalette
```

Esempio di collegamento:

```text
Evento
  -> puo avere una flow_tree agenda
  -> puo avere una pagina pubblica
  -> puo avere iscrizioni
  -> puo avere ruoli abilitati alla gestione
```

## 4. Dipendenze consigliate

Meglio evitare dipendenze circolari.

Schema consigliato:

```text
flow_roles
  nessuna dipendenza da FlowTree o Eventi

rails_flow_tree_sortable
  puo usare flow_roles

flow_events
  puo usare flow_roles
  puo collegarsi opzionalmente a rails_flow_tree_sortable

app host
  monta tutto
  decide current_user, domini, tenant e routing reale
```

Da evitare:

```text
flow_roles dipende da flow_events
flow_roles dipende da rails_flow_tree_sortable
rails_flow_tree_sortable dipende obbligatoriamente da flow_events
```

## 5. Dashboard e landing

Ci sono tre opzioni.

### Opzione A: layout dentro `flow_roles`

Buona se la dashboard e soprattutto una shell role-aware.

Pro:

- ruoli, menu e role map stanno insieme
- FlowTree ed eventi possono riusare la stessa dashboard
- ogni app host parte gia con layout base

Contro:

- `flow_roles` rischia di diventare anche gemma UI
- bisogna tenere i layout molto neutri

### Opzione B: layout dentro `rails_flow_tree_sortable`

Buona se FlowTree diventa il cuore visuale del prodotto.

Pro:

- dashboard, editor e preview stanno insieme
- piu naturale se il prodotto principale e FlowTree

Contro:

- i ruoli diventano dipendenti da un engine contenuti
- eventi e dashboard admin potrebbero sembrare "figli" di FlowTree anche quando non lo sono

### Opzione C: gemma separata `flow_dashboard`

Buona se vuoi massima pulizia.

Pro:

- ruoli separati dalla UI
- FlowTree ed eventi usano la stessa shell
- piu facile mantenere dashboard e landing come template

Contro:

- una gemma in piu
- piu configurazione iniziale

## 6. Scelta consigliata ora

Per questa app, la scelta piu pratica e:

```text
1. Tenere FlowRoles locale ancora un po'
2. Stabilizzare dashboard e landing nell'app host
3. Preparare `flow_roles` come prima gemma
4. Mettere dashboard/landing opzionali dentro `flow_roles`
5. Estrarre `rails_flow_tree_sortable` come engine contenuti
6. Creare `flow_events` solo quando eventi e calendario hanno un dominio chiaro
```

Quindi, per ora:

```text
flow_roles = ruoli + menu + shell opzionale
rails_flow_tree_sortable = contenuti ramificati
flow_events = eventi, calendario e iscrizioni
```

## 7. Quando creare davvero `flow_events`

Non partire subito da una gemma eventi se l'evento e ancora solo una pagina o un prototipo.

Creala quando almeno tre di questi punti sono veri:

- eventi pubblici e admin condividono lo stesso modello
- ci sono iscrizioni o prenotazioni
- ci sono disponibilita o calendario
- gli eventi si collegano ai ruoli
- gli eventi si collegano a FlowTree
- ci sono ricorrenze, costi, stati o workflow
- vuoi riusare eventi in un altro engine o app

Prima di quel momento, meglio tenerli nell'app host.

## 8. Roadmap piccola

1. Rendere stabile il layout dashboard locale.
2. Rendere stabile il menu registry locale.
3. Pulire `FlowRoles` locale.
4. Scrivere API minima di `flow_roles`.
5. Spostare layout dashboard e landing come layout opzionali.
6. Estrarre `flow_roles` in una gemma locale path-based.
7. Collegare `rails_flow_tree_sortable` alla gemma ruoli.
8. Modellare eventi nell'app host.
9. Estrarre `flow_events` solo quando il dominio eventi e maturo.

