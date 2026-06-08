# Flow Roles Gem

Documento di proposta per una gemma/engine Rails chiamata `flow_roles`, pensata per gestire ruoli reali, active role, menu registry e una pagina riassuntiva route/link per ruolo. Deve funzionare nella app host FlowPulse e negli engine Rails, in particolare `rails_flow_tree_sortable`.

## Perche `flow_roles`

`flow_roles` e un nome piu neutro di `academy_roles`:

- non limita il dominio alla formazione;
- resta coerente con FlowPulse e FlowTree;
- puo servire creator, teacher, tutor, professional, admin e superadmin;
- puo essere usata anche da altri engine;
- non lega la gemma a un solo prodotto.

La gemma dovrebbe essere un piccolo layer di ruolo/accesso/navigazione, non una piattaforma completa di autorizzazione.

## Idea centrale

Separare quattro cose:

1. **Ruoli assegnati**
   - permessi reali;
   - globali o contestuali;
   - esempio: `teacher` globale, `creator` dentro un `CreatorWorld`, `tutor` dentro un corso.

2. **Active role**
   - vista/dashboard attiva;
   - non e la fonte dei permessi;
   - serve a scegliere menu e dashboard.

3. **Access helpers**
   - metodi leggibili per controller e view;
   - esempio: `teacher_user?`, `creator_user?(context)`, `admin_user?`, `demo_mode?`.

4. **Menu/route map**
   - registro unico dei link;
   - ogni app/engine registra le sue voci;
   - pagina audit con link divisi per ruolo.

## Cosa deve fare

`flow_roles` dovrebbe occuparsi di:

- role assignments;
- ruoli globali;
- ruoli contestuali;
- active role/switchable roles;
- helper controller;
- menu registry;
- role map page;
- configurazione host-specific per current user, demo e superadmin.

## Cosa non deve fare

`flow_roles` non dovrebbe:

- gestire login/autenticazione;
- sostituire completamente Pundit/Action Policy se servono policy complesse;
- conoscere route specifiche dell'app host;
- dipendere direttamente da `Current.user`;
- contenere business logic di `rails_flow_tree_sortable`;
- imporre gli stessi ruoli a tutti i progetti.

## Ruoli consigliati

Configurazione host:

```ruby
FlowRoles.configure do |config|
  config.roles = %w[
    traveler
    demo
    creator
    teacher
    tutor
    professional
    admin
    superadmin
  ]

  config.assignable_roles = %w[
    creator
    teacher
    tutor
    professional
    admin
  ]

  config.labels = {
    "traveler" => "Viaggiatore",
    "demo" => "Demo",
    "creator" => "Creator",
    "teacher" => "Teacher",
    "tutor" => "Tutor",
    "professional" => "Professionista",
    "admin" => "Admin",
    "superadmin" => "Superadmin"
  }
end
```

Regole:

- `traveler`: base/default;
- `demo`: modalita sandbox/read-only;
- `creator`: crea strutture, alberi, contenuti, format;
- `teacher`: crea o gestisce contenuti didattici;
- `tutor`: segue persone, progressi, follow-up;
- `professional`: servizi/competenze;
- `admin`: operativita interna;
- `superadmin`: bypass globale.

## Modello dati

MVP:

```ruby
FlowRoles::RoleAssignment
  user_id
  role
  context_type
  context_id
```

Ruolo globale:

```ruby
user.assign_role(:teacher)
```

Ruolo contestuale:

```ruby
user.assign_role(:creator, creator_world)
user.assign_role(:teacher, flow_tree)
user.assign_role(:tutor, course)
```

### Tabella

Per estrazione graduale dall'app attuale:

```text
role_assignments
```

Con modello namespaced:

```ruby
class FlowRoles::RoleAssignment < ApplicationRecord
  self.table_name = "role_assignments"
end
```

Questo evita una migration di rename immediata.

In futuro, se serve maggiore isolamento:

```text
flow_roles_role_assignments
```

## Concern per User

La gemma dovrebbe dare:

```ruby
module FlowRoles::UserRoles
  extend ActiveSupport::Concern

  included do
    has_many :role_assignments,
      class_name: "FlowRoles::RoleAssignment",
      dependent: :destroy
  end

  def assign_role(role, context = nil)
  end

  def remove_role(role, context = nil)
  end

  def assigned_role_names(context = nil)
  end

  def has_role?(role, context = nil)
  end

  def switchable_roles
  end

  def can_activate_role?(role)
  end
end
```

Nell'app host:

```ruby
class User < ApplicationRecord
  include FlowRoles::UserRoles
end
```

## Active role

`active_role` resta un concetto UI. La gemma deve leggerlo/scriverlo tramite configurazione:

```ruby
FlowRoles.configure do |config|
  config.active_role_reader = ->(user) { user.active_role }
  config.active_role_writer = ->(user, role) { user.update!(active_role: role) }
end
```

Oppure:

```ruby
config.active_role_method = :active_role
config.active_role_writer = :active_role=
```

Consiglio: usare lambda, per compatibilita con host app ed engine diversi.

## Superadmin e demo

La gemma non deve presumere colonne specifiche. Configurazione:

```ruby
FlowRoles.configure do |config|
  config.superadmin = ->(user) { user.superadmin == true }
  config.demo_access = ->(user) { user.demo_access == true }
end
```

Metodi esposti:

```ruby
user.superadmin_user?
user.has_demo_access?
controller.demo_mode?
```

Regole:

- `superadmin` e permesso reale globale;
- `demo_access` e permesso reale per accedere alla demo;
- `active_role == "demo"` e modalita UI/sandbox;
- `active_role == "superadmin"` non dovrebbe essere l'unica fonte di permesso reale.

## Controller helpers

La gemma dovrebbe offrire:

```ruby
module FlowRoles::ControllerHelpers
  def flow_roles_user
    Current.user
  end

  def require_role!(role, context: nil)
  end

  def require_any_role!(*roles, context: nil)
  end

  def require_superadmin!
  end

  def block_demo_mutations!
  end
end
```

Nella app host:

```ruby
class ApplicationController < ActionController::Base
  include FlowRoles::ControllerHelpers

  private

  def flow_roles_user
    Current.user
  end
end
```

In un engine:

```ruby
module RailsFlowTreeSortable
  class ApplicationController < ActionController::Base
    include FlowRoles::ControllerHelpers

    private

    def flow_roles_user
      Current.user
    end
  end
end
```

## Menu registry

Il menu registry e il pezzo chiave per evitare condizioni sparse nelle view.

Host app:

```ruby
FlowRoles.menu.register(:resources) do |item|
  item.label = "Risorse"
  item.description = "Eventi, transazioni, contatti"
  item.roles = %w[admin superadmin]
  item.path = ->(view) { view.main_app.admin_risorse_index_path }
  item.engine = :host
  item.demo_visible = false
  item.mutating = true
end
```

Engine `rails_flow_tree_sortable`:

```ruby
FlowRoles.menu.register(:flow_tree_dashboard) do |item|
  item.label = "FlowTree"
  item.description = "Alberi, template e contenuti ramificati"
  item.roles = %w[creator teacher tutor admin superadmin]
  item.path = ->(view) { view.rails_flow_tree_sortable.root_path }
  item.engine = :rails_flow_tree_sortable
  item.demo_visible = true
  item.mutating = false
end
```

Aside:

```ruby
FlowRoles.menu.visible_for(
  user: Current.user,
  active_role: active_dashboard_role,
  view: self
)
```

## Role map page

La gemma puo essere mountable:

```ruby
mount FlowRoles::Engine => "/role-map"
```

Pagine:

- `/role-map`
- `/role-map/menu`
- `/role-map/routes`
- `/role-map/users/:id`

La pagina principale mostra:

| Ruolo | Link | Path | Engine | Demo | Mutating | Stato |
| --- | --- | --- | --- | --- | --- | --- |
| traveler | Esperienze | `/dashboard/viaggiatore` | host | si | no | ok |
| creator | FlowTree | `/flowtree` | rails_flow_tree_sortable | si | si/no | ok |
| teacher | Corsi | `/teacher/courses` | rails_flow_tree_sortable | no | si | route mancante |
| tutor | Progressi | `/tutor/progress` | rails_flow_tree_sortable | no | si | route mancante |
| admin | Risorse | `/admin/risorse` | host | no | si | ok |
| superadmin | Domini | `/admin/domains` | host | no | si | ok |

Serve a:

- vedere cosa vede ogni ruolo;
- trovare route mancanti;
- controllare demo/read-only;
- vedere quali link arrivano dall'host e quali dagli engine;
- documentare il prodotto mentre cresce.

## Integrazione con `rails_flow_tree_sortable`

`rails_flow_tree_sortable` non dovrebbe contenere un sistema ruoli completo.

Deve poter dipendere da `flow_roles` oppure usare un'interfaccia compatibile:

```ruby
config.current_user_method
config.authorize_with
config.menu_registry
```

Controller esempio:

```ruby
module RailsFlowTreeSortable
  class TreesController < ApplicationController
    before_action -> {
      require_any_role!(
        :creator,
        :teacher,
        :admin,
        context: current_creator_world
      )
    }
  end
end
```

Regole possibili:

- creator: crea/edit/pubblica alberi del proprio creator world;
- teacher: crea/edit contenuti didattici assegnati;
- tutor: legge alberi e aggiorna progressi/follow-up;
- professional: vede contenuti/servizi collegati;
- admin: gestione operativa;
- superadmin: tutto;
- demo: read-only/sandbox.

## Rapporto con Rolify

Rolify fa bene:

- ruoli multipli;
- ruoli globali;
- ruoli scoped su risorse.

`flow_roles` aggiunge:

- active role/dashboard role;
- menu registry;
- role map page;
- demo mode;
- integrazione pensata con engine Rails;
- registrazione link da engine come `rails_flow_tree_sortable`.

Scelta:

- se vuoi solo ruoli: Rolify;
- se vuoi ruoli + menu + route map + active dashboard + FlowTree: `flow_roles`.

## Estrazione dalla app attuale

Mapping:

| App attuale | Gemma futura |
| --- | --- |
| `app/models/role_assignment.rb` | `flow_roles/app/models/flow_roles/role_assignment.rb` |
| metodi ruoli in `User` | `FlowRoles::UserRoles` |
| metodi ruoli in `ApplicationController` | `FlowRoles::ControllerHelpers` |
| `NavigationHelper::DASHBOARD_MENU` | `FlowRoles::MenuRegistry` |
| `docs/role_navigation_refactor_plan.md` | docs/README |
| `role_gem.md` | architecture notes |

Ordine:

1. Stabilizzare `RoleAssignment` in app.
2. Spostare metodi `User` in concern locale `FlowRoles::UserRoles`.
3. Spostare helper controller in concern locale.
4. Spostare menu in registry locale.
5. Creare gemma/engine `flow_roles`.
6. Copiare moduli nella gemma.
7. Usare `gem "flow_roles", path: "gems/flow_roles"`.
8. Montare `/role-map`.
9. Far registrare a `rails_flow_tree_sortable` i propri link.

## Struttura gemma

```text
flow_roles/
  lib/
    flow_roles.rb
    flow_roles/engine.rb
    flow_roles/configuration.rb
    flow_roles/user_roles.rb
    flow_roles/controller_helpers.rb
    flow_roles/menu_registry.rb
    flow_roles/menu_item.rb
  app/
    models/flow_roles/role_assignment.rb
    controllers/flow_roles/application_controller.rb
    controllers/flow_roles/role_maps_controller.rb
    views/flow_roles/role_maps/index.html.erb
  db/
    migrate/
      create_role_assignments.rb
  config/
    routes.rb
  test/
    dummy/
```

## Generator

```bash
bin/rails generate flow_roles:install
```

Genera:

- migration `create_role_assignments`;
- initializer `config/initializers/flow_roles.rb`;
- istruzioni per includere concern in `User`;
- route opzionale:

```ruby
mount FlowRoles::Engine => "/role-map"
```

## API ideale

User:

```ruby
user.assign_role(:teacher)
user.assign_role(:creator, creator_world)
user.remove_role(:teacher)
user.has_role?(:teacher)
user.has_role?(:creator, creator_world)
user.switchable_roles
user.can_activate_role?(:teacher)
```

Controller:

```ruby
require_role!(:admin)
require_role!(:creator, context: current_creator_world)
require_any_role!(:teacher, :tutor, context: current_creator_world)
require_superadmin!
block_demo_mutations!
```

Menu:

```ruby
FlowRoles.menu.register(:teacher_courses) do |item|
  item.label = "Corsi"
  item.roles = %w[teacher superadmin]
  item.path = ->(view) { view.teacher_courses_path }
end
```

## Checklist estrazione

- [ ] `RoleAssignment` non dipende da modelli specifici host.
- [ ] `User` usa concern e non contiene logica ruoli lunga.
- [ ] `ApplicationController` usa concern controller.
- [ ] Menu item usano lambda per path.
- [ ] Nessun riferimento diretto a `Current.user` dentro la gemma.
- [ ] Nessun riferimento diretto a route host dentro la gemma.
- [ ] Demo e superadmin sono configurabili.
- [ ] Test gemma passano su dummy app.
- [ ] Test host passano con gemma locale.
- [ ] `rails_flow_tree_sortable` puo registrare menu e usare helper ruoli.

## Decisione consigliata

`flow_roles` e il nome migliore tra quelli discussi se vuoi una gemma generale, riusabile e compatibile con piu engine.

La gemma dovrebbe essere:

- piccola;
- configurabile;
- mountable;
- pensata per route map/menu registry;
- indipendente dalla business logic di FlowTree.

`rails_flow_tree_sortable` dovrebbe usare `flow_roles`, non duplicare un proprio sistema ruoli.

