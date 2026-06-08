# Step 0007 - Dashboard UX cleanup Tailwind-first

## Obiettivo

Rimettere a posto la UX dashboard usando TailwindCSS come fonte principale del layout, riducendo il CSS custom al minimo.

Il problema non e piu solo una singola pagina come `/admin/elenco_pagine`: il problema e che la dashboard ha attraversato piu forme durante gli step precedenti:

- shell custom con classi `.dashboard-app-*`;
- layout `dashboard` poi assorbito da `application`;
- vecchie classi legacy `.dashboard-shell`, `.dashboard-aside`, `.dashboard-main`;
- Tailwind inline nelle view;
- CSS custom per breakpoint, fixed sidebar, scroll e topbar.

Risultato: anche quando il DOM e corretto, la UX resta fragile e difficile da debuggare.

La soluzione e rifare il layout dashboard con Tailwind quasi puro, mantenendo solo piccoli hook semantici per i test.

## Stato

In applicazione.

Fatto:

- aggiunto contract DOM con `data-layout="dashboard"` e `data-dashboard-*`;
- convertito `application.html.erb` a struttura dashboard Tailwind-first;
- create partial `shared/dashboard/*`;
- rimossa la vecchia partial `shared/_dashboard_aside.html.erb`;
- rimosso il blocco CSS custom dashboard recente da `application.css`;
- aggiornati i test HTML contract;
- suite test verde.

Da verificare:

- controllo browser reale su `/admin/elenco_pagine`;
- controllo browser reale su `/admin/role_map`;
- eventuale scelta breakpoint `lg` vs `md` per sidebar desktop;
- pulizia delle vecchie classi legacy `.dashboard-shell*` ancora usate da pagine landing/pubbliche.

## Decisione

Usare due layout principali:

```text
application
  app/dashboard
  sidebar sx
  topbar interna
  main contenuto

landing
  pubblico
  auth
  demo non-dashboard
  pagine visuali/prototipo senza aside
```

Regola:

- `application` e il layout app;
- `landing` e il layout pubblico;
- non creare un terzo layout `dashboard`;
- non usare partial shell manuali nelle view dashboard.

## 1. Contract DOM dashboard

Ogni pagina dashboard deve renderizzare questa struttura:

```html
<body data-layout="dashboard">
  <aside data-dashboard-sidebar>...</aside>
  <div data-dashboard-frame>
    <header data-dashboard-topbar>...</header>
    <main data-dashboard-main>...</main>
  </div>
</body>
```

Gli attributi `data-*` servono per test e debug.

Le classi Tailwind possono cambiare; il contract testabile no.

Stato: fatto.

## 2. Application layout Tailwind-first

`app/views/layouts/application.html.erb` deve diventare simile al template statico:

```erb
<body data-layout="dashboard" class="bg-slate-50 text-slate-900">
  <div class="min-h-screen">
    <div data-dashboard-overlay class="fixed inset-0 z-30 hidden bg-slate-900/50 lg:hidden"></div>

    <aside data-dashboard-sidebar class="fixed inset-y-0 left-0 z-40 flex w-72 -translate-x-full flex-col border-r border-slate-200 bg-white transition-transform lg:translate-x-0">
      <%= render "shared/dashboard/sidebar" %>
    </aside>

    <div data-dashboard-frame class="min-w-0 lg:pl-72">
      <header data-dashboard-topbar class="sticky top-0 z-20 flex h-16 items-center justify-between border-b border-slate-200 bg-white/90 px-4 backdrop-blur lg:px-8">
        <%= render "shared/dashboard/topbar" %>
      </header>

      <main data-dashboard-main class="min-h-[calc(100vh-4rem)] min-w-0 p-4 lg:p-8">
        <%= yield %>
      </main>
    </div>
  </div>
</body>
```

Nota:

- usare classi Tailwind dirette;
- niente CSS custom per grid/sidebar/topbar/main;
- niente calcoli CSS custom se Tailwind basta;
- niente `overflow: hidden` globale finche non serve davvero.

Stato: fatto.

## 3. Partial da creare

Creare o sistemare:

```text
app/views/shared/dashboard/_sidebar.html.erb
app/views/shared/dashboard/_sidebar_brand.html.erb
app/views/shared/dashboard/_sidebar_nav.html.erb
app/views/shared/dashboard/_role_switcher.html.erb
app/views/shared/dashboard/_topbar.html.erb
```

Responsabilita:

- `_sidebar`: contenitore interno sidebar;
- `_sidebar_brand`: logo/nome app e bottone chiusura mobile;
- `_sidebar_nav`: gruppi menu da `FlowRoles::MenuRegistry`;
- `_role_switcher`: vista/ruolo attivo;
- `_topbar`: titolo contesto, pulsante menu mobile, profilo.

La vecchia `app/views/shared/_dashboard_aside.html.erb` puo restare temporaneamente come wrapper, ma deve diventare sottile o essere sostituita.

Stato: fatto. La vecchia partial e stata rimossa.

## 4. Menu registry

Il menu resta guidato da:

```ruby
FlowRoles.menu_for(...)
FlowRoles.grouped_menu_for(...)
dashboard_aside_menu_groups(...)
```

La view non deve contenere logica di permessi.

Stato: invariato e confermato. La visibilita resta guidata da `FlowRoles`/helper.

Da migliorare nella sidebar:

- label piu corte;
- descrizioni meno invasive;
- badge compatti;
- active state chiaro ma non troppo pesante;
- menu superadmin leggibile anche quando lungo.

## 5. CSS da rimuovere o ridurre

In `app/assets/stylesheets/application.css` rimuovere o non usare piu per il layout dashboard:

```css
.dashboard-layout
.dashboard-template
.dashboard-sidebar-overlay
.dashboard-app-aside
.dashboard-app-aside__brand
.dashboard-app-aside__header
.dashboard-app-aside__nav
.dashboard-app-aside__switcher
.dashboard-content-frame
.dashboard-topbar
.dashboard-app-main
.dashboard-icon-button
.dashboard-profile-button
```

Rimuovere anche le vecchie classi dashboard legacy quando non piu referenziate:

```css
.dashboard-shell
.dashboard-shell--with-aside
.dashboard-aside
.dashboard-main
```

CSS custom ammesso:

- scrollbar opzionale;
- CSS di pagine/prototipi storici non ancora migrati;
- piccoli fix impossibili o brutti da esprimere con Tailwind.

Stato: fatto per il CSS dashboard custom recente. Le classi legacy `.dashboard-shell*` restano per pagine landing/pubbliche ancora non migrate.

## 6. Wrapper contenuto main

Le pagine dashboard dovrebbero avere contenuto centrale coerente:

```erb
<div class="space-y-6">
  <header class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
    ...
  </header>

  ...
</div>
```

Oppure creare una partial/component locale se la ripetizione cresce.

Prima pagina da sistemare:

- `/admin/elenco_pagine`

Poi:

- `/admin/dashboard`;
- `/admin/role_map`;
- `/admin/risorse`;
- `/admin/domains`;
- `/dashboard/viaggiatore`;
- `/creator_world`;
- `/teacher`;
- `/tutor`;
- `/professional`.

## 7. Mobile

Mobile deve essere semplice:

- sidebar nascosta fuori schermo;
- bottone topbar apre sidebar;
- overlay chiude sidebar;
- bottone X in sidebar chiude;
- main resta in flusso normale;
- niente scroll body bloccato finche la sidebar non e aperta.

Se serve JS, tenerlo piccolo e locale nel layout o in Stimulus in uno step successivo.

## 8. Test automatici

Aggiungere o aggiornare test per il contract:

```ruby
assert_includes response.body, 'data-layout="dashboard"'
assert_includes response.body, "data-dashboard-sidebar"
assert_includes response.body, "data-dashboard-frame"
assert_includes response.body, "data-dashboard-topbar"
assert_includes response.body, "data-dashboard-main"
assert_equal 1, response.body.scan("data-dashboard-sidebar").count
```

E per landing:

```ruby
assert_not_includes response.body, 'data-layout="dashboard"'
assert_not_includes response.body, "data-dashboard-sidebar"
```

Stato: fatto in `test/controllers/home_controller_test.rb`.

## 9. Verifica visuale reale

Verificare in browser:

- `/admin/elenco_pagine`;
- `/admin/role_map`;
- `/admin/dashboard`;
- `/dashboard/viaggiatore`.

Viewport:

- desktop `1440x900`;
- laptop/tablet `1024x768`;
- tablet `768x1024`;
- mobile `390x844`.

Criteri:

- desktop: sidebar a sinistra, main a destra;
- desktop: topbar sopra il main, non sopra la sidebar;
- desktop: il contenuto non finisce sotto la sidebar;
- mobile: sidebar si apre e chiude;
- root/landing: nessuna sidebar dashboard;
- non ci sono due nav principali sovrapposte.

## 10. Sequenza implementazione

1. Aggiungere `data-*` contract al layout `application`.
2. Spostare sidebar/topbar in partial `shared/dashboard/*`.
3. Convertire layout e sidebar a Tailwind puro.
4. Rimuovere CSS custom dashboard da `application.css`.
5. Aggiornare test HTML contract.
6. Eseguire:

```bash
PARALLEL_WORKERS=0 bin/rails test
bin/rails zeitwerk:check
```

7. Fare verifica browser reale.

Stato:

- punti 1-6 completati;
- punto 7 ancora da fare manualmente in browser.

## Criterio di completamento

Lo step e completo solo quando:

- `/admin/elenco_pagine` e chiaramente sidebar sx + topbar + main;
- il layout usa Tailwind per la struttura;
- il CSS custom dashboard e stato ridotto o rimosso;
- landing pubblica non eredita la dashboard;
- i test sono verdi;
- il DOM contract e stabile con `data-*`.
