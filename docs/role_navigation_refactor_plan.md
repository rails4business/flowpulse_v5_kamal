# Role navigation refactor plan

Obiettivo: consolidare i ruoli `teacher` e `tutor`, mantenendo `traveler`, `demo`, `creator`, `professional`, `admin`, `superadmin`, e preparando sidebar, dashboard e futura integrazione FlowTree.

Stato aggiornato: `active_role` resta solo il ruolo/vista attiva. I permessi reali non devono dipendere da `active_role`; ora vengono preparati con `RoleAssignment`, mentre `superadmin` e `demo_access` restano flag globali su `User`. Il primo layer locale `FlowRoles` e stato introdotto senza estrarre ancora una gemma.

## 1. Stato attuale dei ruoli

I ruoli di vista sono concentrati in `User.active_role`, enum integer:

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

Colonne correlate:

- `users.active_role`: integer, default `0`, non nullo. E il ruolo attivo usato da dashboard e menu, non la fonte primaria dei permessi.
- `users.role`: integer, default `0`, non nullo. Presente nello schema ma non usato dalla logica letta.
- `users.superadmin`: boolean, default `false`, non nullo. Usato come bypass/admin reale in vari punti.
- `users.demo_access`: boolean. Abilita l'utente a usare il ruolo/area demo.
- `profiles.role`: string. Presente ma non usato per autorizzazioni.
- `role_assignments.role`: enum integer per assegnare ruoli reali globali o contestuali.
- `role_assignments.context_type/context_id`: contesto polimorfico opzionale, pensato per `CreatorWorld` e futuri engine.

Ruoli attivabili da `User#ruoli_attivabili`:

- sempre `traveler`;
- `demo` se `demo_access`;
- ruoli globali presenti in `role_assignments`;
- tutti i ruoli in `User::SWITCHABLE_ROLES` se `superadmin`.

I ruoli contestuali, per esempio `creator` dentro un futuro `CreatorWorld`, non diventano automaticamente ruoli globali attivabili: servono per autorizzare quel contesto specifico.

Regola active role:

- `active_role` e solo modalita UI/dashboard;
- `safe_active_role` restituisce `active_role` solo se `can_activate_role?` e vero;
- se il ruolo salvato non e piu attivabile, la UI usa fallback `traveler`;
- `active_dashboard_role` usa `safe_active_role`, quindi dashboard/menu non mostrano viste non autorizzate.

Helper/punti principali:

- `User#can_activate_role?(role_name)` controlla che il ruolo esista nell'enum e sia incluso in `ruoli_attivabili`.
- `User#can_switch_roles?` abilita il selettore ruolo se superadmin o se ci sono piu ruoli attivabili.
- `ApplicationController#dashboard_home_path` manda `superadmin` e `admin` verso `admin_dashboard_path`, `creator` verso `creator_world_root_path`, `teacher` verso `teacher_root_path`, `tutor` verso `tutor_root_path`, `professional` verso `professional_root_path`, `demo` verso `demo_viaggiatori_path` e gli altri verso `viaggiatori_path`.
- `NavigationHelper#verified_link_to` nasconde link non accessibili lato navigazione.
- `Admin::BaseController#require_superadmin!` protegge area admin con `superadmin_user?`.
- `Demo::BaseController#require_demo_access!` protegge area demo con `superadmin_user?` o `has_demo_access?`.

Nota importante: `superadmin_user?` deve restare permesso reale basato sul boolean `users.superadmin`. Il valore `active_role == "superadmin"` e solo vista attiva/simulazione. Il superadmin puo vedere/simulare tutti i ruoli perche `ruoli_attivabili` restituisce tutto `SWITCHABLE_ROLES` e `has_assigned_role?` fa bypass intenzionale su `superadmin_user?`.

## 2. Stato di `teacher` e `tutor`

Stato attuale:

- `tutor` occupa il valore `3`.
- `teacher` occupa il valore `4`.
- `professional`, `admin`, `superadmin` occupano rispettivamente `5`, `6`, `7`.
- `teacher` e `tutor` sono presenti sia come viste attive sia come ruoli reali assegnabili tramite `RoleAssignment`.

Rischio residuo:

- verificare eventuali dati reali esistenti prima del deploy;
- se ci sono record con active role non piu coerente, allinearli con una data migration;
- evitare di usare `active_role` come sorgente di autorizzazione.

Conclusione: `active_role` va trattato come stato UI. I permessi reali sono da leggere da `role_assignments`, `superadmin` e `demo_access`.

## 3. Cosa controllare per `teacher` e `tutor`

Controlli principali:

- `teacher` e `tutor` devono restare in `User::SWITCHABLE_ROLES`.
- `RoleAssignment` deve poter assegnare `teacher` e `tutor`.
- I selettori ruolo in nav/sidebar dipendono da `ruoli_attivabili`; quindi teacher/tutor sono selezionabili solo se assegnati globalmente o se superadmin.
- `dashboard_home_path` distingue creator/professional/teacher/tutor e manda ciascun ruolo alla dashboard dedicata.
- `FlowRoles::MenuRegistry` include voci creator/teacher/tutor/professional con route reali.
- I test coprono assegnazione ruolo, cambio dashboard, accesso negato e bypass superadmin sulle dashboard di ruolo.

Rischi laterali gia presenti da considerare nel refactor:

- `ResourcesController` dichiara `allow_unauthenticated_access`, anche se route e sotto `/admin/risorse`. La visibilita link non basta come autorizzazione.
- `PagesController` e pubblico; `viaggiatori_path` e nominalmente dashboard ma apribile senza login.
- `Demo::ViewPagesController` e pubblico anche se nel namespace demo.

## 4. Migrazione consigliata per `active_role`

Regola aggiornata: `active_role` non assegna permessi. Serve solo per scegliere la dashboard/vista attiva.

Mappa attuale implementata:

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

Azioni consigliate prima di deploy su dati reali:

- verificare quanti utenti hanno `active_role` diverso da `traveler`, `demo`, `superadmin`;
- se i valori erano gia usati, decidere mapping dati prima della migrazione;
- evitare di usare `active_role` come sorgente di autorizzazione;
- usare `role_assignments` per ruoli reali globali o contestuali.

## 5. Aggiornamenti necessari a `User#ruoli_attivabili` e `can_activate_role?`

Stato implementato:

```ruby
return SWITCHABLE_ROLES if superadmin_user?

attivabili = ["traveler"]
attivabili.concat(assigned_role_names)
attivabili << "demo" if demo_access_enabled?
SWITCHABLE_ROLES & attivabili.uniq
```

Ruoli ordinati:

```ruby
SWITCHABLE_ROLES = %w[
  traveler
  demo
  creator
  teacher
  tutor
  professional
  admin
  superadmin
].freeze
```

Regole:

- superadmin puo attivare tutte le viste;
- `demo_access` aggiunge `demo`;
- un ruolo globale in `role_assignments` aggiunge la vista corrispondente;
- un ruolo contestuale non aggiunge automaticamente la vista globale;
- `can_activate_role?` rifiuta ruoli non presenti nell'enum.

`RoleAssignment` implementato:

```ruby
RoleAssignment
  user_id
  role
  context_type
  context_id
```

Ruoli assegnabili:

- `creator`
- `teacher`
- `tutor`
- `professional`
- `admin`

Il contesto e opzionale:

- senza contesto: ruolo globale, quindi puo entrare in `ruoli_attivabili`;
- con contesto: ruolo valido solo dentro quel contesto, per esempio futuro `CreatorWorld`.

## 6. Aggiornamenti alla sidebar/aside

File aggiornati/principali:

- `app/views/shared/_dashboard_aside.html.erb`
- `app/views/shared/flowpulse/_nav.html.erb`
- `app/helpers/navigation_helper.rb`
- `app/controllers/application_controller.rb`

Sidebar attuale:

- e una sidebar unica "Workspace";
- mostra sempre voci superadmin/prototipi, ma le blocca per non superadmin;
- voci attuali:
  - Dashboard Superadmin
  - Domini
  - Risorse
  - Lavoro
  - Salute
  - Elenco pagine
  - Weekplan

Aggiornamento consigliato:

- spostare la definizione delle voci in helper o oggetto semplice, non inline nella partial;
- ogni item dovrebbe avere:
  - `key`
  - `title`
  - `subtitle`
  - `path`
  - `roles`
  - `demo_visible`
  - `mutating` o `readonly`
- mostrare solo le voci pertinenti al ruolo attivo, invece di mostrare tutto bloccato;
- nelle pagine admin mostrare solo strumenti admin/superadmin, non tutte le dashboard di ruolo simulate.

Esempio concettuale:

```ruby
[
  { key: :traveler_dashboard, roles: %w[traveler demo creator teacher tutor professional admin superadmin] },
  { key: :creator_world, roles: %w[creator admin superadmin] },
  { key: :teacher_area, roles: %w[teacher professional admin superadmin] },
  { key: :tutor_area, roles: %w[tutor teacher professional admin superadmin] },
  { key: :professional_area, roles: %w[professional admin superadmin] },
  { key: :admin_resources, roles: %w[admin superadmin] },
  { key: :admin_domains, roles: %w[superadmin] }
]
```

Nav principale:

- il selettore ruolo usa `Current.user.ruoli_attivabili`;
- aggiornare label e ruoli disponibili;
- il link `Dashboard` deve puntare alla dashboard del ruolo attivo, non sempre admin/viaggiatori.

`NavigationHelper`:

- sostituire `public_path?`/`demo_path?` come unico criterio con policy per ruolo;
- mantenere `verified_link_to` solo per UI;
- aggiungere protezioni controller vere per dashboard/azioni.

## 7. Tabella pagine per ruolo

| Ruolo | Pagine/route attuali o proposte | Accesso | Note |
| --- | --- | --- | --- |
| pubblico | `/`, `/esperienze`, `/esperienze/:id`, `/markpostura`, `/markposturaold`, `/markposturastory`, `/posturacorretta`, login/registrazione/password, eventuali FlowTree pubblicati read-only | pubblico | Root passa da `domains#show`; attenzione ai file statici `/viste_html/*` sempre pubblici. |
| traveler | `/dashboard`, `/dashboard/viaggiatore`, `/esperienze` | autenticato per dashboard router e dashboard viaggiatore | Dashboard esperienza/eventi/brand. Le esperienze pubbliche restano sotto `/esperienze`. |
| demo | `/demo/mari`, `/demo/viaggiatori`, `/demo/carta_nautica`, `/demo/mondi`, `/demo/progetti`, `/demo/lavoro`, `/demo/salute`, `/demo/pagine/:slug` | demo_access o superadmin per controller demo, ma `/demo/pagine/:slug` oggi pubblico | Demo deve essere read-only/sandbox, senza mutate reali. |
| creator | `/creator_world`, proposta futura `/creator_world/flowtree`, creator dashboard, gestione progetti/format/contenuti | autenticato + ruolo creator o superadmin | Dashboard locale creata; FlowTree non montato. |
| teacher | `/teacher`, proposta futura `/teacher/courses`, `/teacher/lessons`, `/teacher/flowtree` read/write didattico limitato | autenticato + role assignment `teacher` o superadmin | Dashboard locale creata; puo gestire contenuti formativi e percorsi assegnati. |
| tutor | `/tutor`, proposta futura `/tutor/students`, `/tutor/sessions`, `/tutor/progress` | autenticato + ruolo tutor o superadmin | Dashboard locale creata; ruolo operativo di accompagnamento e follow-up. |
| professional | `/professional`, proposta futura servizi, disponibilita, competenze, eventi collegati | autenticato + ruolo professional o superadmin | Dashboard locale creata. |
| admin | `/admin/dashboard`, `/admin/risorse`, gestione operativa non dominio | autenticato + role assignment `admin` o superadmin | Admin operativo ora distinto dal superadmin. |
| superadmin | `/admin/dashboard`, `/admin/domains`, `/admin/elenco_pagine`, import/export domini, FlowTree admin completo | autenticato + `users.superadmin` | Bypass completo. `active_role == "superadmin"` resta vista attiva, non permesso reale. |

## 8. Regole demo

Regole consigliate:

- Demo vede:
  - pagine pubbliche;
  - area `/demo`;
  - eventuali dashboard simulate read-only;
  - anteprime FlowTree pubbliche o sandbox.
- Demo non puo:
  - creare/modificare/cancellare record reali;
  - importare/esportare domini o FlowTree reali;
  - pubblicare contenuti;
  - accedere ad admin;
  - cambiare ownership, ruoli, permessi;
  - usare azioni mutative fuori da sandbox.

Implementazione consigliata:

- mantenere `demo_access` come permesso per entrare in demo;
- usare `active_role == "demo"` come modalita di simulazione UI;
- aggiungere helper esplicito `demo_mode?`;
- nei controller, bloccare metodi mutativi quando `demo_mode?`;
- non affidarsi solo a `verified_link_to`.

## 9. Proposta routes pulita per dashboard e FlowTree futuro

Obiettivo: separare dashboard stabili da prototipi `/demo`.

Dashboard locali implementate:

```ruby
get "dashboard" => "home#dashboard", as: :dashboard

namespace :creator_world do
  root "dashboard#show"
end

namespace :teacher do
  root "dashboard#show"
end

namespace :tutor do
  root "dashboard#show"
end

namespace :professional do
  root "dashboard#show"
end
```

Proposta futura se si vuole normalizzare anche traveler:

```ruby
get "dashboard" => "dashboards#show", as: :dashboard

namespace :traveler do
  root "dashboard#show"
end

namespace :creator_world do
  root "dashboard#show"
end

namespace :teacher do
  root "dashboard#show"
end

namespace :tutor do
  root "dashboard#show"
end

namespace :professional do
  root "dashboard#show"
end

namespace :admin do
  get "dashboard" => "home#dashboard", as: :dashboard
end
```

`DashboardsController#show` dovrebbe fare routing per ruolo:

- `traveler` -> `traveler_root_path`
- `demo` -> `demo_viaggiatori_path`
- `creator` -> `creator_world_root_path`
- `teacher` -> `teacher_root_path`
- `tutor` -> `tutor_root_path`
- `professional` -> `professional_root_path`
- `admin` -> `admin_dashboard_path`
- `superadmin` -> `admin_dashboard_path`

Proposta FlowTree:

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
      member { get :preview }
    end
  end
end

namespace :teacher do
  namespace :flowtree do
    resources :courses, only: [:index, :show]
    resources :trees, only: [:index, :show, :edit, :update]
  end
end

namespace :tutor do
  namespace :flowtree do
    resources :trees, only: [:index, :show]
    resources :progresses, only: [:index, :show, :update]
  end
end

namespace :flowtree do
  resources :trees, only: [:index, :show], param: :slug, path: "/"
end
```

Base controller consigliati:

- `Admin::BaseController`: admin/superadmin, con distinzione tra admin operativo e superadmin.
- `CreatorWorld::BaseController`: creator o superadmin.
- `Teacher::BaseController`: teacher o superadmin.
- `Tutor::BaseController`: tutor o superadmin.
- `Professional::BaseController`: professional o superadmin.
- `Flowtree::PublicController`: pubblico read-only.

## 10. Lista step piccoli da implementare

1. Fatto: introdurre `RoleAssignment`
   - migration `create_role_assignments`;
   - modello `RoleAssignment`;
   - associazione `User has_many :role_assignments`;
   - ruoli globali e contestuali;
   - indici unici per ruolo globale e ruolo contestuale.

2. Fatto: centralizzare ruoli/label
   - `User::ROLE_LABELS`;
   - `User::SWITCHABLE_ROLES`;
   - `ruolo_label` delega alle label centralizzate.

3. Fatto: aggiornare `ruoli_attivabili`
   - superadmin puo simulare tutti;
   - demo_access aggiunge demo;
   - role assignment globale aggiunge il ruolo;
   - role assignment contestuale resta limitato al contesto.

4. Fatto: proteggere active role/dashboard
   - `safe_active_role`;
   - `active_role_attivabile?`;
   - `active_dashboard_role` usa solo il ruolo sicuro;
   - `PATCH /dashboard_role` aggiorna solo ruoli attivabili.

5. Fatto: introdurre layer locale `FlowRoles`
   - `FlowRoles::UserRoles`;
   - `FlowRoles::ControllerHelpers`;
   - `FlowRoles::MenuItem`;
   - `FlowRoles::MenuRegistry`.

6. Fatto: aggiungere metodi permesso su `User`
   - `superadmin_user?`;
   - `admin_user?`;
   - `creator_user?(context = nil)`;
   - `teacher_user?(context = nil)`;
   - `tutor_user?(context = nil)`;
   - `professional_user?(context = nil)`.

7. Fatto: aggiungere test modello
   - ruolo globale attivabile;
   - ruolo contestuale non globale;
   - superadmin bypass;
   - demo_access.

8. Da fare prima del deploy su dati reali:
   - contare utenti con `active_role = 3`;
   - contare utenti con `active_role = 4`, `5`, `6`, `7`;
   - se esistono dati reali, scrivere data migration di mapping;
   - decidere se azzerare a `traveler` gli `active_role` non piu coerenti.

9. Fatto: completare routing dashboard ruolo
   - aggiunto routing per `creator`, `teacher`, `tutor`, `professional`;
   - `dashboard_home_path` manda ogni active role autorizzato alla home corretta;
   - fallback prudente su `viaggiatori_path` o root.

10. Fatto: introdurre base controller per ruoli:
   - `CreatorWorld::BaseController`;
   - `Teacher::BaseController`;
   - `Tutor::BaseController`;
   - `Professional::BaseController`;
   - ogni base controller usa `require_role!`, con bypass superadmin.

11. Fatto: semplificare dashboard di ruolo
   - creator/teacher/tutor/professional usano la partial comune `shared/role_dashboard`;
   - i controller passano solo configurazione della dashboard;
   - ridotta duplicazione HTML nelle view di ruolo.

12. Fatto: refactor sidebar/menu registry
   - lista item estratta in `FlowRoles::MenuRegistry`;
   - item assegnati per ruolo;
   - partial `_dashboard_aside` guidata dalla tabella.
   - route reali collegate per creator/teacher/tutor/professional.

13. Fatto parziale: refactor nav
   - aggiornare selettore ruoli;
   - link Dashboard verso `dashboard_home_path`;
   - trigger profilo ridotto al cerchio avatar/iniziale.
   - dashboard dedicate collegate per creator/teacher/tutor/professional.

14. Fatto: role map/audit locale
    - route `/admin/role_map`;
    - controller `Admin::RoleMapsController`;
    - view con link divisi per ruolo;
    - accesso solo superadmin.

15. Fatto parziale: proteggere server-side le pagine:
    - `ResourcesController` ora richiede `admin_user?`;
    - `Admin::BaseController` ora richiede admin o superadmin;
    - `Admin::DomainsController` resta superadmin;
    - `Admin::HomeController#elenco_pagine` resta superadmin.
    - `/dashboard/viaggiatore` richiede autenticazione.

16. Da fare: completare protezioni server-side:
    - non affidarsi solo a `verified_link_to`;
    - valutare se `/demo/pagine/:slug` deve restare pubblico o passare sotto `Demo::BaseController`.

17. Fatto parziale: aggiungere test controller/navigation
    - cambio ruolo assegnato verso dashboard dedicata;
    - accesso negato/consentito a namespace ruolo;
    - superadmin puo accedere a tutte le dashboard di ruolo.
    - `/dashboard/viaggiatore` richiede autenticazione.

18. Da fare: preparare FlowTree:
    - prima solo `/admin/flowtree`;
    - poi pubblico read-only;
    - poi creator/teacher/tutor con permessi specifici;
    - demo solo sandbox/read-only.
