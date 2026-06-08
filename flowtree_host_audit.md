# FlowTree host audit

Audit eseguito su Rails app in `/Users/hselectronics/Documents/Code/flowpulse_v_5`.
Comandi usati: `rg`, `rg --files`, `bin/rails routes`, lettura di controller/modelli/helper/layout. `bin/rails routes` funziona; Bundler segnala solo che `/Users/hselectronics` non e scrivibile e usa una home temporanea.

Nota sul worktree: erano gia presenti modifiche non committate prima dell'audit. Questo file e l'unica aggiunta intenzionale.

## 1. Routes attuali

Fonte principale: `config/routes.rb` e output di `bin/rails routes`.

### Root

- `GET /` -> `domains#show`, helper `root_path`.
- `DomainsController#show` e pubblico (`allow_unauthenticated_access`) e renderizza:
  - il target configurato in `Current.domain.target_controller/target_action`, se esiste;
  - fallback `pages/flowpulse`, se non trova dominio/target.
- `config/domains.yml` configura:
  - `flowpulse.net` -> `pages#flowpulse`
  - `markpostura.it` -> `pages#markpostura`
  - `posturacorretta.org` -> `pages#posturacorretta`
  - alias `www.*` e domini `.com` con canonical redirect.

### Pagine pubbliche

- Auth/session:
  - `GET /session/new`, `POST /session`, `DELETE /session`, ecc. -> `sessions`
  - `GET /users/new`, `POST /users` -> `users`
  - `resources :passwords, param: :token`
- Landing/contenuti:
  - `GET /esperienze` -> `public_events#index`, helper `esperienze_path`
  - `GET /esperienze/:id` -> `public_events#show`, helper `esperienza_path`
  - `GET /markpostura` -> `pages#markpostura`
  - `GET /markposturaold` -> `pages#markpostura_old`
  - `GET /markposturastory` -> `pages#markposturastory`
  - `GET /posturacorretta` -> `pages#posturacorretta`
- Prototipi demo pubblici:
  - `GET /demo/pagine/:slug` -> `demo/view_pages#show`, helper `demo_view_page_path`
  - attenzione: `Demo::ViewPagesController` eredita da `ApplicationController` ma dichiara `allow_unauthenticated_access`, quindi non richiede login ne demo access.
- Statici diretti:
  - molti prototipi sono in `public/viste_html/*.html` e possono essere aperti direttamente da `/viste_html/...`.

### Pagine admin/superadmin

Namespace `admin`:

- `GET /admin/dashboard` -> `admin/home#dashboard`, helper `admin_dashboard_path`
- `GET /admin/elenco_pagine` -> `admin/home#elenco_pagine`
- `resources :domains`:
  - `GET /admin/domains`
  - `POST /admin/domains`
  - `GET /admin/domains/new`
  - `GET /admin/domains/:id`
  - `GET /admin/domains/:id/edit`
  - `PATCH/PUT /admin/domains/:id`
  - `DELETE /admin/domains/:id`
  - collection `GET /admin/domains/export`
  - collection `POST /admin/domains/import`
- `resources :risorse, controller: "/resources", only: [:index, :show]`
  - `GET /admin/risorse` -> `resources#index`
  - `GET /admin/risorse/:id` -> `resources#show`

Tutti i controller admin reali letti ereditano da `Admin::BaseController`, che applica `require_superadmin!`.

### Pagine utente loggato

- `GET /dashboard` -> `home#dashboard`, helper `dashboard_path`
  - richiede autenticazione;
  - redirige a `dashboard_home_path`.
- `GET /dashboard/viaggiatore` -> `pages#viaggiatori`, helper `viaggiatori_path`
  - nominalmente dashboard utente;
  - pero `PagesController` dichiara `allow_unauthenticated_access`, quindi questa route e attualmente pubblica.
- `PATCH /dashboard_role` -> `home#dashboard_role`
  - richiede autenticazione;
  - cambia `User.active_role` se l'utente puo attivare quel ruolo.

### Namespace/scope gia presenti

- `namespace :admin`
- `namespace :demo`
- nessun namespace `creator`, `creator_world`, `flowtree`, `account`, `tenant`, `organization`.
- nessun engine montato con `mount`.

### Routes che sembrano dashboard o menu principali

- `dashboard_path` -> router centrale dashboard utente.
- `admin_dashboard_path` -> workspace superadmin.
- `viaggiatori_path` -> dashboard viaggiatore/esperienze.
- `demo_lavoro_path`, `demo_salute_path`, `demo_progetti_path`, `demo_mondi_path` -> viste/prototipi demo usate anche come voci di menu.
- `admin_risorse_index_path` -> area risorse, tab principali: eventi, transazioni, contatti, attenzione, luoghi, abilita, energia.
- `admin_elenco_pagine_path` -> inventario prototipi e pagine registrate.
- Link diretto `/viste_html/6_weekplan.html` nella sidebar admin.

## 2. Ruoli e permessi

### Dove sono definiti i ruoli

Ruoli centrali in `app/models/user.rb`:

```ruby
enum :active_role, {
  traveler: 0,
  demo: 1,
  creator: 2,
  tutor: 3,
  teacher: 4,
  professional: 5,
  admin: 6,
  superadmin: 7
}
```

Colonne correlate in `db/schema.rb`:

- `users.active_role: integer`, default `0`, non nullo.
- `users.role: integer`, default `0`, non nullo, ma non usato dal modello letto.
- `users.superadmin: boolean`, default `false`, non nullo.
- `users.demo_access: boolean`, nullable.
- `profiles.role: string`, presente ma non usato per autorizzazione nelle parti lette.

### Metodi disponibili

Da enum `active_role` Rails genera metodi/predicati come:

- `traveler?`
- `demo?`
- `creator?`
- `tutor?`
- `teacher?`
- `professional?`
- `admin?`
- `superadmin?`

Metodi custom in `User`:

- `can_activate_role?(role_name)`
- `ruoli_attivabili`
- `is_superadmin?`
- `has_demo_access?`
- `can_switch_roles?`

Metodi/helper in `ApplicationController`:

- `superadmin?`
- `active_dashboard_role`
- `active_dashboard_role_label`
- `dashboard_home_path`
- `ruolo_label`

Helper in `NavigationHelper`:

- `verified_link_to`
- `can_access_path?`
- `public_path?`
- `demo_path?`
- `superadmin_user?`

### Modelli coinvolti

- `User`: modello principale per login, ruoli, sessioni, profilo.
- `Profile`: `belongs_to :user`; ha `display_name`, `first_name`, `last_name`, `role`, ma non espone logica ruolo.
- `Session`: usato per cookie/sessione e `Current.session`.
- `Domain`: usato per routing pubblico multi-dominio.
- Non risultano modelli `Teacher`, `Professional`, `Creator`, `Organization`, `Account`, `Tenant`.

### Demo role

La demo ha due concetti distinti:

- `users.demo_access`: abilita accesso all'area demo protetta.
- `users.active_role == "demo"`: ruolo attivo usato da dashboard/navigation.

`User#ruoli_attivabili` include:

- sempre `"traveler"`;
- `"demo"` se `demo_access` e vero;
- `"superadmin"` se `superadmin` e vero.

`Demo::BaseController#require_demo_access!` consente accesso se:

- `user&.superadmin?`, oppure
- `user&.demo_access?`.

Rischio: `user.superadmin?` e ambiguo perche esistono sia colonna booleana `superadmin` sia enum `active_role` con valore `superadmin`. Altrove il codice evita l'ambiguita usando `Current.user&.superadmin == true || Current.user&.active_role == "superadmin"`.

### Cosa viene nascosto o bloccato in demo

`NavigationHelper#can_access_path?`:

- superadmin: tutto visibile.
- active_role demo:
  - consente path pubblici;
  - consente path `/demo`;
  - blocca il resto, quindi blocca `/admin`.
- altri utenti:
  - consente solo path pubblici, cioe non `/admin` e non `/demo`.

`verified_link_to` non renderizza link se `can_access_path?` restituisce false.

`app/views/shared/_dashboard_aside.html.erb`:

- se superadmin, mostra link navigabili.
- se non superadmin, mostra le stesse voci come card bloccate, tranne la voce attiva.
- mostra selettore ruolo solo se `Current.user.can_switch_roles?`.

Nota: il blocco e soprattutto di navigazione/visibilita. Le autorizzazioni server-side vere sono nei controller (`Admin::BaseController`, `Demo::BaseController`). Le pagine pubbliche e i file statici restano apribili direttamente.

## 3. Current context

### `current_user`, `current_profile`, tenant/account/organization

- Non esiste un metodo `current_user` globale nei controller letti.
- Il contesto utente passa da `Current.user`, delegato da `Current.session`.
- Non esiste `current_profile`; le viste usano `Current.user.profile`.
- Non risultano tenant, account, organization o simili.
- Esiste routing per dominio tramite `Current.domain`, ma non e un tenant applicativo completo.

### Current object

`app/models/current.rb`:

```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :session, :domain
  delegate :user, to: :session, allow_nil: true
end
```

`Authentication#resume_session` imposta `Current.session` leggendo `cookies.signed[:session_id]`.

`CurrentDomain` imposta/legge `Current.domain` con:

- `current_domain_host`
- `dedicated_domain_host`
- `Domain.find_for_host`.

### Helper globali per ruolo/accesso

- `ApplicationController` espone come helper:
  - `superadmin?`
  - `active_dashboard_role`
  - `active_dashboard_role_label`
  - `dashboard_home_path`
  - `ruolo_label`
- `Authentication` espone:
  - `authenticated?`
- `CurrentDomain` espone:
  - `current_domain`
  - `current_domain_host`
  - `dedicated_domain_host`
- `NavigationHelper` incapsula visibilita link via `verified_link_to`.

## 4. Layout e navigazione

### Layout usati

- `app/views/layouts/application.html.erb`
  - layout standard;
  - renderizza `shared/flowpulse/nav`;
  - mostra flash;
  - usa `main` full-width per alcune pagine (`home#index`, `pages#flowpulse`, `pages#mari`, `pages#viaggiatori`), altrimenti container `max-w-7xl`.
- `app/views/layouts/domains.html.erb`
  - usato da `PagesController` con `layout "domains"`;
  - renderizza sempre `shared/flowpulse/nav`;
  - non ha wrapper `main`, yield diretto.
- mailer layouts non rilevanti.

### Sidebar/menu/header esistenti

- Header/nav principale: `app/views/shared/flowpulse/_nav.html.erb`
  - visibile solo se `dedicated_domain_host` e in `localhost`, `flowpulse.net`, `www.flowpulse.net`.
  - link: Flowpulse root, Esperienze, Progetti, Percorsi.
  - se autenticato: dropdown profilo, selettore ruolo, Dashboard, Profilo, Esci.
  - se non autenticato: Accedi, Registrati.
- Sidebar dashboard: `app/views/shared/_dashboard_aside.html.erb`
  - voci: Dashboard Superadmin, Domini, Risorse, Lavoro, Salute, Elenco pagine, Weekplan.
  - usa `verified_link_to` solo se superadmin.
  - per non superadmin mostra voci bloccate.
- Dashboard admin: `app/views/admin/home/dashboard.html.erb`
  - card interne: Risorse, Domini, Lavoro, Salute, Elenco pagine.
- Dashboard viaggiatore: `app/views/pages/viaggiatori.html.erb`
  - sidebar locale con sezioni: Eventi, Categorie, Brand.

### Come vengono mostrati/nascosti link per ruolo

- La logica generale e `verified_link_to` + `NavigationHelper#can_access_path?`.
- Superadmin vede tutto.
- Demo vede pubblico + `/demo`.
- Utente normale vede solo pubblico.
- La sidebar dashboard replica una seconda logica:
  - superadmin naviga;
  - non superadmin vede card disabilitate/bloccate.

## 5. Policy/autorizzazioni

### Pundit, CanCanCan o sistema custom

- Non risultano Pundit o CanCanCan nei file letti e nelle ricerche.
- Sistema custom basato su:
  - `Authentication` concern;
  - `Admin::BaseController#require_superadmin!`;
  - `Demo::BaseController#require_demo_access!`;
  - helper di navigazione per nascondere link.

### Controller concern usati

- `Authentication`
  - incluso in `ApplicationController`;
  - richiede autenticazione di default;
  - controller pubblici chiamano `allow_unauthenticated_access` o `skip_before_action`.
- `CurrentDomain`
  - incluso in `ApplicationController`;
  - espone dominio corrente e host dedicato.

### Before action importanti

- `ApplicationController`
  - `before_action :resume_session`
  - `allow_browser versions: :modern`
- `Authentication`
  - `before_action :require_authentication`, incluso globalmente.
- `HomeController`
  - `allow_unauthenticated_access only: [:index, :progetti, :lavoro, :salute]`
  - `before_action :require_authentication, only: [:dashboard, :dashboard_role]`
- `Admin::BaseController`
  - `before_action :require_superadmin!`
- `Demo::BaseController`
  - `before_action :require_demo_access!`
- `DomainsController`
  - `allow_unauthenticated_access`
  - `before_action :set_domain`
- `PagesController`
  - `allow_unauthenticated_access`
  - `layout "domains"`
- `ResourcesController`
  - `allow_unauthenticated_access`, ma quando instradato come `/admin/risorse` e collegato dall'admin. Questo significa che la protezione server-side di `admin/risorse` non passa da `Admin::BaseController`.

## 6. Proposta di integrazione FlowTree

### Dove montare FlowTree

Proposta: montare FlowTree come engine o namespace dedicato sotto tre ingressi distinti:

1. Superadmin operativo: `/admin/flowtree`
2. Creator world: `/creator_world/flowtree`
3. Pubblico/read-only: `/flowtree` oppure pagine specifiche sotto `/esperienze`/landing, se serve esposizione pubblica.

Motivo: l'app ha gia separazione concettuale tra admin, demo/prototipi e pubblico. Evitare di mettere FlowTree sotto `/demo` come area principale: `/demo` oggi contiene prototipi e viste statiche, non una feature stabile.

### Pagine FlowTree sotto superadmin

Sotto `/admin/flowtree`:

- Dashboard globale FlowTree.
- Gestione template/tree types.
- Editor completo nodi/rami/stati.
- Import/export YAML/JSON.
- Mapping template -> dominio/pagina/progetto.
- Gestione permessi e visibilita dei template.
- Audit/versioni/pubblicazioni.
- Collegamenti a `admin/domains` se un albero determina landing o target dominio.

Controller suggerito:

- `Admin::Flowtree::BaseController < Admin::BaseController`
- oppure engine montato con vincolo superadmin.

### Pagine FlowTree sotto `creator_world`

Sotto `/creator_world/flowtree`:

- Alberi del creator.
- Editor limitato ai propri template/progetti.
- Gestione contenuti, step, percorsi, eventi collegati.
- Anteprima pubblica.
- Pubblicazione controllata, se l'utente ha ruolo `creator`.

Questa area richiede prima una policy custom per creator/proprietario, perche oggi `creator` esiste solo come valore enum e non come permesso reale. Va introdotto un `CreatorWorld::BaseController` con filtro tipo:

- utente autenticato;
- `Current.user.creator?` o ruolo attivo `creator`;
- eventuale superadmin bypass;
- futura ownership su profilo/progetto/spazio.

### Pagine FlowTree pubbliche

Sotto `/flowtree` o sotto route piu semantiche:

- Anteprime read-only di alberi pubblicati.
- Percorsi pubblici collegati a landing/progetti.
- Eventuali embed in `pages#flowpulse`, `pages#markpostura`, `public_events`.

Per pagine pubbliche conviene evitare editor e azioni mutative. Solo show/list pubblicati, preferibilmente filtrati da `Domain` o da slug pubblico.

### Cosa nascondere in demo

Se `active_role == "demo"`:

- nascondere editor completo;
- nascondere import/export;
- nascondere delete/destroy;
- nascondere pubblicazione reale;
- consentire solo prototipi o sandbox read-only;
- se serve edit demo, salvare su entita demo/non persistenti o con flag sandbox.

Server-side: non basta `verified_link_to`; servono filtri controller per bloccare azioni mutative. La demo oggi blocca link, ma i controller devono proteggere direttamente.

### Proposta routes pulita

Se FlowTree e engine:

```ruby
namespace :admin do
  mount FlowTree::Engine => "/flowtree", as: :flowtree
end

namespace :creator_world do
  mount FlowTree::Engine => "/flowtree", as: :flowtree
end

scope :flowtree, as: :public_flowtree do
  get "/" => "flowtree/public_trees#index"
  get "/:slug" => "flowtree/public_trees#show"
end
```

Se FlowTree e controller locali:

```ruby
namespace :admin do
  namespace :flowtree do
    root "dashboard#show"
    resources :templates
    resources :trees do
      member do
        get :preview
        post :publish
      end
      collection do
        get :export
        post :import
      end
    end
  end
end

namespace :creator_world do
  namespace :flowtree do
    root "trees#index"
    resources :trees do
      member do
        get :preview
      end
    end
  end
end

namespace :flowtree do
  resources :trees, only: [:index, :show], param: :slug, path: "/"
end
```

Base controller consigliati:

- `Admin::Flowtree::BaseController < Admin::BaseController`
- `CreatorWorld::BaseController < ApplicationController`
- `Flowtree::PublicController < ApplicationController` con `allow_unauthenticated_access`

### Rischi o conflitti con routes/layout esistenti

- Ambiguita `superadmin?`: verificare se indica enum `active_role == "superadmin"` o colonna booleana. Per FlowTree usare un metodo unico esplicito, ad esempio `superadmin_user?`/`can_admin_flowtree?`.
- `PagesController` e pubblico: non mettere dashboard/editor FlowTree in `PagesController`.
- `/demo/pagine/:slug` e pubblico: non usarlo come protezione per prototipi sensibili.
- `/admin/risorse` usa `ResourcesController` che dichiara `allow_unauthenticated_access`; se FlowTree prende esempio da questo pattern, rischia esposizione involontaria. Meglio controller admin sotto `Admin::BaseController`.
- `verified_link_to` nasconde link ma non autorizza richieste dirette.
- Layout:
  - `application` e adatto a dashboard con navbar/container.
  - `domains` e piu adatto a landing pubbliche e pagine dominio.
  - FlowTree editor dovrebbe usare `application` o layout dedicato tipo `flowtree`, non `domains`.
- Namespace `/demo` contiene sia pagine protette (`Demo::BaseController`) sia `Demo::ViewPagesController` pubblico: evitare assunzioni globali sul namespace.
- `Domain#target_controller/target_action` fa render dinamico di viste controller/action: FlowTree pubblico potrebbe integrarsi via `Domain.settings` o target dedicato, ma va controllato per non trasformare routing dominio in bypass autorizzativo.
- Le route statiche `/viste_html/*` sono sempre pubbliche. Se FlowTree genera HTML statico, non metterci output non pubblico.

### Sequenza consigliata

1. Introdurre metodi autorizzativi espliciti e non ambigui:
   - `can_admin_flowtree?`
   - `can_access_creator_world?`
   - `demo_mode?`
2. Aggiungere `CreatorWorld::BaseController`.
3. Montare/creare FlowTree prima sotto `/admin/flowtree`.
4. Aggiungere read-only pubblico solo per alberi pubblicati.
5. Solo dopo, aprire `/creator_world/flowtree` con ownership e limiti chiari.
6. Aggiornare `shared/_dashboard_aside.html.erb` e `shared/flowpulse/_nav.html.erb` usando `verified_link_to`, ma mantenere sempre i blocchi server-side nei controller.
