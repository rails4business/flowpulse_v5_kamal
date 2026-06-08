# Accademy Roles Gem

Documento di proposta per una gemma/engine Rails chiamata provvisoriamente `accademy_roles`, pensata per gestire ruoli, permessi leggeri, menu per ruolo e una pagina riassuntiva route/link. Deve poter funzionare sia nella app host FlowPulse sia dentro/fuori l'engine `rails_flow_tree_sortable`.

Nota naming: in inglese comune sarebbe `academy_roles`, con una sola `c` dopo la `a`. `accademy_roles` puo comunque essere una scelta voluta se vuoi un nome piu personale/italianizzato. Prima di pubblicare una gemma vera, deciderei definitivamente tra:

- `accademy_roles`
- `academy_roles`
- `flow_roles`
- `academy_role_map`

## Perche `accademy_roles`

Il nome funziona bene se l'asse principale e:

- teacher;
- tutor;
- percorsi;
- corsi;
- contenuti didattici;
- academy/learning flow;
- ramificazione contenuti con `rails_flow_tree_sortable`.

Rispetto a `flow_roles`, e piu orientato al prodotto "academy". Rispetto a Rolify, e piu specifico: non solo ruoli, ma anche active role, menu registry e pagina riassuntiva.

## Responsabilita della gemma

`accademy_roles` dovrebbe occuparsi di:

1. **Role assignment**
   - ruoli reali assegnati agli utenti;
   - ruoli globali;
   - ruoli contestuali, per esempio dentro un `CreatorWorld`, un corso, un academy space, un albero FlowTree.

2. **Active role**
   - ruolo/vista attiva per dashboard;
   - non e la sorgente dei permessi;
   - serve a decidere quale menu o dashboard mostrare.

3. **Controller helpers**
   - `require_role!`;
   - `require_any_role!`;
   - `superadmin_user?`;
   - `demo_mode?`;
   - blocchi demo/read-only.

4. **Menu registry**
   - una tabella unica dei link;
   - ogni app/engine registra le sue voci;
   - l'aside o la nav leggono dal registry.

5. **Role map page**
   - pagina riassuntiva dei link divisi per ruolo;
   - utile per audit, debug e progettazione prodotto.

## Cosa NON deve fare

`accademy_roles` non dovrebbe:

- gestire autenticazione;
- decidere tutta la business logic di FlowTree;
- sostituire Pundit/Action Policy se in futuro servono policy complesse;
- conoscere route specifiche della app host;
- dipendere direttamente da `Current.user`;
- imporre che ogni progetto abbia gli stessi ruoli.

## Ruoli di base

Configurazione consigliata:

```ruby
AccademyRoles.configure do |config|
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

- `traveler`: ruolo base/vista pubblica o utente base;
- `demo`: modalita demo/sandbox;
- `creator`: crea strutture, contenuti, percorsi, alberi;
- `teacher`: insegna, costruisce moduli didattici, usa alberi/corsi;
- `tutor`: accompagna, legge progressi, segue utenti/studenti;
- `professional`: eroga servizi/competenze;
- `admin`: operativita interna;
- `superadmin`: bypass globale.

## Modello dati

Versione MVP:

```ruby
AccademyRoles::RoleAssignment
  user_id
  role
  context_type
  context_id
```

Ruolo globale:

```ruby
user.role_assignments.create!(role: :teacher)
```

Ruolo contestuale:

```ruby
user.role_assignments.create!(role: :creator, context: creator_world)
user.role_assignments.create!(role: :tutor, context: course)
user.role_assignments.create!(role: :teacher, context: flow_tree)
```

### Tabella

Per estrazione graduale dalla app attuale, conviene iniziare con tabella:

```text
role_assignments
```

Anche se il modello nella gemma e namespaced:

```ruby
class AccademyRoles::RoleAssignment < ApplicationRecord
  self.table_name = "role_assignments"
end
```

In futuro, se vuoi una gemma piu isolata, puoi passare a:

```text
accademy_roles_role_assignments
```

Ma non lo farei subito.

## Concern per User

La gemma dovrebbe dare:

```ruby
module AccademyRoles::UserRoles
  extend ActiveSupport::Concern

  included do
    has_many :role_assignments,
      class_name: "AccademyRoles::RoleAssignment",
      dependent: :destroy
  end

  def assigned_role_names(context = nil)
  end

  def has_role?(role, context = nil)
  end

  def assign_role(role, context = nil)
  end

  def remove_role(role, context = nil)
  end

  def switchable_roles
  end

  def can_activate_role?(role)
  end
end
```

Nella app host:

```ruby
class User < ApplicationRecord
  include AccademyRoles::UserRoles
end
```

## Active role

`active_role` resta sull'host app, non per forza nella gemma.

La gemma deve sapere come leggerlo/scriverlo:

```ruby
AccademyRoles.configure do |config|
  config.active_role_reader = ->(user) { user.active_role }
  config.active_role_writer = ->(user, role) { user.update!(active_role: role) }
end
```

Oppure con metodi:

```ruby
config.active_role_method = :active_role
config.active_role_writer = :active_role=
```

Scelta consigliata: lambda, per compatibilita con app diverse.

## Superadmin e demo

La gemma deve permettere configurazione host-specific:

```ruby
AccademyRoles.configure do |config|
  config.superadmin = ->(user) { user.superadmin == true }
  config.demo_access = ->(user) { user.demo_access == true }
end
```

Poi espone:

```ruby
user.superadmin_user?
user.has_demo_access?
controller.demo_mode?
```

Importante:

- `superadmin` e permesso reale globale;
- `demo_access` e permesso reale per entrare in demo;
- `active_role == "demo"` e modalita UI/sandbox;
- `active_role == "superadmin"` non deve essere l'unico permesso reale.

## Controller helpers

La gemma dovrebbe offrire:

```ruby
module AccademyRoles::ControllerHelpers
  def accademy_roles_user
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
  include AccademyRoles::ControllerHelpers

  private

  def accademy_roles_user
    Current.user
  end
end
```

Dentro un engine:

```ruby
module RailsFlowTreeSortable
  class ApplicationController < ActionController::Base
    include AccademyRoles::ControllerHelpers

    private

    def accademy_roles_user
      Current.user
    end
  end
end
```

## Menu registry

Questa e la parte che rende `accademy_roles` diversa da Rolify.

Ogni app/engine registra link:

```ruby
AccademyRoles.menu.register(:resources) do |item|
  item.label = "Risorse"
  item.description = "Eventi, transazioni, contatti"
  item.roles = %w[admin superadmin]
  item.path = ->(view) { view.main_app.admin_risorse_index_path }
  item.engine = :host
  item.demo_visible = false
  item.mutating = true
end
```

Per `rails_flow_tree_sortable`:

```ruby
AccademyRoles.menu.register(:flow_tree_dashboard) do |item|
  item.label = "FlowTree"
  item.description = "Alberi, template e contenuti ramificati"
  item.roles = %w[creator teacher tutor admin superadmin]
  item.path = ->(view) { view.rails_flow_tree_sortable.root_path }
  item.engine = :rails_flow_tree_sortable
  item.demo_visible = true
  item.mutating = false
end
```

L'aside host usa:

```ruby
AccademyRoles.menu.visible_for(
  user: Current.user,
  active_role: active_dashboard_role,
  view: self
)
```

## Pagina role map

La gemma dovrebbe essere mountable:

```ruby
mount AccademyRoles::Engine => "/role-map"
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

Questa pagina serve a:

- vedere cosa vede ogni ruolo;
- trovare route mancanti;
- verificare link demo;
- controllare cosa e mutating;
- documentare il prodotto mentre cresce.

## Integrazione con `rails_flow_tree_sortable`

`rails_flow_tree_sortable` non dovrebbe contenere un sistema ruoli completo.

Dovrebbe dipendere da `accademy_roles` oppure usare una interfaccia compatibile:

```ruby
config.current_user_method
config.authorize_with
config.menu_registry
```

Esempio controller:

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

- `creator`: crea/edit/pubblica alberi del proprio creator world;
- `teacher`: crea/edit contenuti didattici assegnati;
- `tutor`: legge alberi e aggiorna progressi/follow-up;
- `professional`: vede contenuti/servizi collegati;
- `admin`: gestione operativa;
- `superadmin`: tutto;
- `demo`: read-only/sandbox.

## Rapporto con Rolify

Rolify e molto utile come ispirazione.

Rolify fa bene:

- ruoli multipli;
- ruoli globali;
- ruoli scoped su risorse.

Pero `accademy_roles` aggiunge:

- active role/dashboard role;
- menu registry;
- role map page;
- demo mode;
- integrazione pensata con engine Rails;
- registrazione link da engine come `rails_flow_tree_sortable`.

Quindi:

- se vuoi solo ruoli: Rolify;
- se vuoi ruoli + menu + route map + active dashboard + FlowTree: `accademy_roles`.

## Estrazione dalla app attuale

Mapping:

| App attuale | Gemma futura |
| --- | --- |
| `app/models/role_assignment.rb` | `accademy_roles/app/models/accademy_roles/role_assignment.rb` |
| metodi ruoli in `User` | `AccademyRoles::UserRoles` |
| metodi ruoli in `ApplicationController` | `AccademyRoles::ControllerHelpers` |
| `NavigationHelper::DASHBOARD_MENU` | `AccademyRoles::MenuRegistry` |
| `docs/role_navigation_refactor_plan.md` | docs/README |
| `role_gem.md` | architecture notes |

Ordine:

1. Stabilizzare `RoleAssignment` in app.
2. Spostare metodi `User` in concern locale `AccademyRoles::UserRoles`.
3. Spostare helper controller in concern locale.
4. Spostare menu in registry locale.
5. Creare gemma/engine `accademy_roles`.
6. Copiare moduli nella gemma.
7. Usare `gem "accademy_roles", path: "gems/accademy_roles"`.
8. Montare `/role-map`.
9. Far registrare a `rails_flow_tree_sortable` i propri link.

## Struttura gemma

```text
accademy_roles/
  lib/
    accademy_roles.rb
    accademy_roles/engine.rb
    accademy_roles/configuration.rb
    accademy_roles/user_roles.rb
    accademy_roles/controller_helpers.rb
    accademy_roles/menu_registry.rb
    accademy_roles/menu_item.rb
  app/
    models/accademy_roles/role_assignment.rb
    controllers/accademy_roles/application_controller.rb
    controllers/accademy_roles/role_maps_controller.rb
    views/accademy_roles/role_maps/index.html.erb
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
bin/rails generate accademy_roles:install
```

Genera:

- migration `create_role_assignments`;
- initializer `config/initializers/accademy_roles.rb`;
- istruzioni per includere concern in `User`;
- route opzionale:

```ruby
mount AccademyRoles::Engine => "/role-map"
```

## API ideale

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
AccademyRoles.menu.register(:teacher_courses) do |item|
  item.label = "Corsi"
  item.roles = %w[teacher superadmin]
  item.path = ->(view) { view.teacher_courses_path }
end
```

## Decisione consigliata

Io userei `accademy_roles` se vuoi dare una direzione chiara academy/teacher/tutor/learning.

Pero, tecnicamente, la gemma deve restare abbastanza neutra da supportare:

- creator world;
- professional;
- admin;
- superadmin;
- route map;
- `rails_flow_tree_sortable`.

Quindi il nome puo essere academy-oriented, ma l'API deve restare generale.

