require 'fileutils'

content = <<~HTML
<% content_for :landing_nav do %>
  <%= render "posturacorretta/header" %>
<% end %>

<%
  human_areas = [
    {
      slug: "care",
      percorso: "Patologia",
      verb: "Esisto",
      title: "Cura, patologie e riabilitazione",
      description: "L’ambito sanitario dedicato alla diagnosi, al dolore, alla terapia, alla riabilitazione e all’accompagnamento professionale.",
      topics: "Patologie • Dolore • Terapia • Riabilitazione",
      positive: "Mi sento al sicuro",
      blockage: "Paura",
      button_classes: "from-red-300/90 via-red-500/80 to-red-800/65 text-white shadow-red-900/10 focus-visible:ring-red-300",
      glow_color: "rgba(239,68,68,.35)",
      panel_classes: "border-red-200 bg-red-50",
      badge_classes: "bg-red-600 text-white",
      title_classes: "text-red-950",
      copy_classes: "text-red-900",
      accent_classes: "text-red-800",
      positive_classes: "border-red-200 text-red-950",
      positive_label_classes: "text-red-600"
    },
    {
      slug: "vitality",
      percorso: "Prevenzione",
      verb: "Sento",
      title: "Prevenzione nelle attività",
      description: "Imparare ad ascoltare il corpo e prevenire i rischi nelle attività quotidiane, sportive, lavorative e ricreative.",
      topics: "Attività quotidiane • Sport • Ergonomia • Lavoro • Sicurezza",
      positive: "Provo piacere",
      blockage: "Senso di colpa",
      button_classes: "from-orange-200/90 via-orange-500/80 to-orange-700/65 text-white shadow-orange-900/10 focus-visible:ring-orange-300",
      glow_color: "rgba(249,115,22,.35)",
      panel_classes: "border-orange-200 bg-orange-50",
      badge_classes: "bg-orange-500 text-white",
      title_classes: "text-orange-950",
      copy_classes: "text-orange-900",
      accent_classes: "text-orange-800",
      positive_classes: "border-orange-200 text-orange-950",
      positive_label_classes: "text-orange-600"
    },
    {
      slug: "performance",
      percorso: "Performances",
      verb: "Agisco",
      title: "Performance, lavoro e formazione",
      description: "Sviluppare capacità fisiche, professionali e cognitive per agire con maggiore autonomia ed efficacia.",
      topics: "Performance • Lavoro • Formazione • Capacità cognitive • Tecnologia • IA",
      positive: "Esprimo la mia volontà",
      blockage: "Vergogna e senso d’impotenza",
      button_classes: "from-amber-200/90 via-amber-400/80 to-amber-600/65 text-amber-950 shadow-amber-900/10 focus-visible:ring-amber-300",
      glow_color: "rgba(245,158,11,.35)",
      panel_classes: "border-amber-200 bg-amber-50",
      badge_classes: "bg-amber-400 text-amber-950",
      title_classes: "text-amber-950",
      copy_classes: "text-amber-900",
      accent_classes: "text-amber-800",
      positive_classes: "border-amber-200 text-amber-950",
      positive_label_classes: "text-amber-600"
    },
    {
      slug: "wellbeing",
      percorso: "Benessere",
      verb: "Armonizzo",
      title: "Benessere e servizi alla persona",
      description: "Discipline e servizi rivolti all’equilibrio, alla cura di sé e alla qualità della relazione con il proprio corpo e con gli altri.",
      topics: "Discipline bio-naturali • Fitness • Estetica • Servizi alla persona",
      positive: "Amo e accolgo",
      blockage: "Dolore e chiusura",
      button_classes: "from-emerald-300/95 via-emerald-500/85 to-emerald-700/70 text-white shadow-emerald-900/20 focus-visible:ring-emerald-300",
      glow_color: "rgba(16,185,129,.35)",
      panel_classes: "border-emerald-200 bg-emerald-50",
      badge_classes: "bg-emerald-600 text-white",
      title_classes: "text-emerald-950",
      copy_classes: "text-emerald-900",
      accent_classes: "text-emerald-800",
      positive_classes: "border-emerald-200 text-emerald-950",
      positive_label_classes: "text-emerald-600"
    },
    {
      slug: "expression",
      percorso: "Fisiologia",
      verb: "Esprimo",
      title: "Educazione e Accademia Postura e Fisiologia",
      description: "Educazione, divulgazione e studio del corpo per conoscere, praticare e trasmettere ciò che si è appreso.",
      topics: "Educazione • Accademia • Divulgazione • Studio • Insegnamento",
      positive: "Comunico ciò che sento e conosco",
      blockage: "Menzogna e non detto",
      button_classes: "from-sky-300/90 via-sky-500/75 to-sky-700/60 text-white shadow-sky-900/10 focus-visible:ring-sky-300",
      glow_color: "rgba(14,165,233,.35)",
      panel_classes: "border-sky-200 bg-sky-50",
      badge_classes: "bg-sky-600 text-white",
      title_classes: "text-sky-950",
      copy_classes: "text-sky-900",
      accent_classes: "text-sky-800",
      positive_classes: "border-sky-200 text-sky-950",
      positive_label_classes: "text-sky-600"
    },
    {
      slug: "evolution",
      percorso: "Mondo interno",
      verb: "Comprendo",
      title: "Evoluzione armonica",
      description: "Modelli e pratiche per osservare le sfere dell’essere umano, sviluppare consapevolezza e trasformare le abitudini.",
      topics: "Modelli • Sfere dell’essere umano • Consapevolezza • Visione • Abitudini",
      positive: "Vedo con chiarezza",
      blockage: "Illusione e confusione",
      button_classes: "from-indigo-300/90 via-indigo-500/75 to-indigo-700/60 text-white shadow-indigo-900/10 focus-visible:ring-indigo-300",
      glow_color: "rgba(99,102,241,.35)",
      panel_classes: "border-indigo-200 bg-indigo-50",
      badge_classes: "bg-indigo-600 text-white",
      title_classes: "text-indigo-950",
      copy_classes: "text-indigo-900",
      accent_classes: "text-indigo-800",
      positive_classes: "border-indigo-200 text-indigo-950",
      positive_label_classes: "text-indigo-600"
    },
    {
      slug: "community",
      percorso: "Relazioni e ambiente",
      verb: "Appartengo",
      title: "Stile di vita, ambiente e territorio",
      description: "Il rapporto della persona con i luoghi, la natura, le relazioni, i gruppi e la comunità di cui fa parte.",
      topics: "Ambiente • Territorio • Natura • Relazioni • Gruppi • Comunità",
      positive: "Mi sento parte del tutto",
      blockage: "Separazione e attaccamento",
      button_classes: "from-violet-300/90 via-violet-500/75 to-violet-700/60 text-white shadow-violet-900/10 focus-visible:ring-violet-300",
      glow_color: "rgba(139,92,246,.35)",
      panel_classes: "border-violet-200 bg-violet-50",
      badge_classes: "bg-violet-600 text-white",
      title_classes: "text-violet-950",
      copy_classes: "text-violet-900",
      accent_classes: "text-violet-800",
      positive_classes: "border-violet-200 text-violet-950",
      positive_label_classes: "text-violet-600"
    }
  ]

  audiences = [
    {
      initial: "S",
      eyebrow: "Area sanitaria",
      title: "Professionisti sanitari",
      description: "Percorsi, metodiche e contenuti per approfondire la lettura del corpo e accompagnare cura, terapia e riabilitazione.",
      topics: "Cura • Valutazione • Terapia • Riabilitazione",
      card_classes: "border-red-200 bg-red-50",
      icon_classes: "bg-red-600 text-white",
      eyebrow_classes: "text-red-600",
      title_classes: "text-red-950",
      copy_classes: "text-red-800",
      topics_classes: "text-red-700"
    },
    {
      initial: "B",
      eyebrow: "Area benessere",
      title: "Professionisti del benessere",
      description: "Percorsi, metodiche e contenuti da integrare nelle attività dedicate al movimento, all’equilibrio e alla cura della persona.",
      topics: "Movimento • Prevenzione • Benessere • Servizi",
      card_classes: "border-emerald-200 bg-emerald-50",
      icon_classes: "bg-emerald-600 text-white",
      eyebrow_classes: "text-emerald-600",
      title_classes: "text-emerald-950",
      copy_classes: "text-emerald-800",
      topics_classes: "text-emerald-700"
    },
    {
      initial: "T",
      eyebrow: "Aperto a tutti",
      title: "Educazione accessibile a tutti",
      description: "Contenuti divulgativi e pratiche di base per conoscere il corpo, comprendere la propria salute e scegliere con maggiore consapevolezza.",
      topics: "Informazione • Pratica • Consapevolezza • Autonomia",
      card_classes: "border-sky-200 bg-sky-50",
      icon_classes: "bg-sky-600 text-white",
      eyebrow_classes: "text-sky-600",
      title_classes: "text-sky-950",
      copy_classes: "text-sky-800",
      topics_classes: "text-sky-700"
    }
  ]
%>

<div id="top" class="bg-white text-slate-900 antialiased">
  
  <section class="bg-gradient-to-b from-blue-50/70 via-white to-slate-50/70 px-5 py-12 md:py-16 xl:py-20" aria-labelledby="human-areas-title" data-chakra-container>
    <div class="mx-auto max-w-6xl">
      <header class="mx-auto max-w-3xl text-center">
        <p class="text-xs font-semibold uppercase tracking-[0.18em] text-blue-700">
          Postura e Ambiti
        </p>
        <h2 id="human-areas-title" class="mt-3 text-3xl font-semibold tracking-tight text-slate-950 md:text-4xl">
          Come può aiutarti la postura?
        </h2>
        <p class="mt-4 text-base leading-7 text-slate-600">
          Le metodiche posturali aiutano a osservare come il corpo si organizza, si muove e si adatta alle attività e all’ambiente. Possono offrire un punto di partenza per comprendere meglio la salute e orientare il percorso più adatto.
        </p>
      </header>

      <div class="mt-10 lg:mt-16 lg:grid lg:grid-cols-[140px_1fr] lg:gap-12 xl:gap-20 lg:items-start">
        
        <!-- Colonna Spine (solo Desktop) -->
        <div class="hidden lg:flex chakra-spine relative flex-col items-center gap-5 pb-8" role="tablist">
          <% human_areas.each_with_index do |area, index| %>
            <button
              type="button"
              data-chakra-tab="<%= area.fetch(:slug) %>"
              class="chakra-circle bg-gradient-to-br shadow-lg focus:outline-none focus-visible:ring-4 <%= area.fetch(:button_classes) %> <%= 'is-active' if index.zero? %>"
              style="--chakra-glow: <%= area.fetch(:glow_color) %>"
              role="tab"
              aria-selected="<%= index.zero? %>"
              tabindex="<%= index.zero? ? 0 : -1 %>"
            >
              <%= area.fetch(:percorso) %>
            </button>
          <% end %>
        </div>

        <!-- Colonna Pannelli (e Accordion Mobile) -->
        <div class="relative w-full lg:min-h-[40rem] flex flex-col gap-3 lg:block">
          <% human_areas.each_with_index do |area, index| %>
            
            <!-- MOBILE BUTTON (Accordion Header) -->
            <button 
              type="button"
              data-chakra-tab="<%= area.fetch(:slug) %>" 
              class="mobile-chakra-btn lg:hidden w-full flex items-center gap-4 text-left p-3 rounded-2xl border border-slate-200 bg-white shadow-sm focus:outline-none focus-visible:ring-2 focus-visible:ring-indigo-300 transition-all <%= 'is-active border-indigo-200 ring-2 ring-indigo-50' if index.zero? %>"
              aria-expanded="<%= index.zero? %>"
            >
              <div class="flex-shrink-0 w-12 h-12 rounded-full flex items-center justify-center text-white font-bold bg-gradient-to-br <%= area[:button_classes] %>">
                <span class="text-[11px] uppercase tracking-wider"><%= area[:percorso][0..2] %></span>
              </div>
              <div class="flex-1">
                 <div class="text-[10px] font-bold uppercase tracking-wider <%= area[:accent_classes] %>"><%= area[:percorso] %></div>
                 <div class="font-bold text-slate-900 leading-tight mt-0.5"><%= area[:title] %></div>
              </div>
              <div class="chevron flex-shrink-0 w-8 h-8 rounded-full bg-slate-50 flex items-center justify-center text-slate-400 text-[10px] transition-transform duration-300">▼</div>
            </button>
            
            <!-- PANNELLO DETTAGLIO -->
            <article
              id="panel-<%= area.fetch(:slug) %>"
              data-chakra-panel="<%= area.fetch(:slug) %>"
              class="chakra-panel-wrapper rounded-[1.75rem] border p-6 shadow-sm md:p-8 <%= area.fetch(:panel_classes) %> <%= 'is-active hidden' unless index.zero? %> <%= 'is-active' if index.zero? %>"
              role="tabpanel"
            >
              <span class="inline-flex rounded-full px-3 py-1 text-xs font-bold uppercase tracking-[0.14em] <%= area.fetch(:badge_classes) %>">
                <%= area.fetch(:verb) %> &middot; <%= area.fetch(:percorso) %>
              </span>
              <h3 class="mt-5 text-2xl font-semibold tracking-tight md:text-3xl <%= area.fetch(:title_classes) %>">
                <%= area.fetch(:title) %>
              </h3>
              <p class="mt-4 text-base leading-7 <%= area.fetch(:copy_classes) %>">
                <%= area.fetch(:description) %>
              </p>
              <p class="mt-5 text-sm font-semibold leading-6 <%= area.fetch(:accent_classes) %>">
                <%= area.fetch(:topics) %>
              </p>

              <div class="mt-7 grid gap-3 sm:grid-cols-2">
                <div class="rounded-2xl border bg-white/70 p-4 <%= area.fetch(:positive_classes) %>">
                  <p class="text-xs font-bold uppercase tracking-wider <%= area.fetch(:positive_label_classes) %>">Espressione positiva</p>
                  <p class="mt-2 font-semibold"><%= area.fetch(:positive) %></p>
                </div>
                <div class="rounded-2xl border border-slate-200 bg-white/70 p-4 text-slate-800">
                  <p class="text-xs font-bold uppercase tracking-wider text-slate-500">Ciò che blocca</p>
                  <p class="mt-2 font-semibold"><%= area.fetch(:blockage) %></p>
                </div>
              </div>
            </article>
            
          <% end %>
        </div>
      </div>
      
      <p class="mt-5 text-center text-sm leading-6 text-slate-500">
        I sette ambiti costituiscono una <strong class="font-semibold text-slate-700">mappa simbolica e interdisciplinare</strong> della persona, non una classificazione clinica.
      </p>

      <!-- Pubblici -->
      <section class="mt-14 border-t border-slate-200 pt-12 md:mt-20 md:pt-16" aria-labelledby="audiences-title">
        <header class="mx-auto max-w-3xl text-center">
          <p class="text-xs font-semibold uppercase tracking-[0.18em] text-blue-700">
            A chi è rivolto
          </p>
          <h2 id="audiences-title" class="mt-3 text-3xl font-semibold tracking-tight text-slate-950 md:text-4xl">
            Percorsi per persone e professionisti
          </h2>
          <p class="mt-4 text-base leading-7 text-slate-600">
            Puoi partire da zero, approfondire la tua pratica oppure integrare nuovi contenuti nel tuo lavoro, nel rispetto delle competenze di ogni figura.
          </p>
        </header>

        <div class="mt-8 grid gap-5 md:grid-cols-3">
          <% audiences.each do |audience| %>
            <article class="flex h-full flex-col rounded-[1.75rem] border p-6 shadow-sm transition duration-200 hover:-translate-y-1 hover:shadow-lg <%= audience.fetch(:card_classes) %>">
              <div class="flex h-11 w-11 items-center justify-center rounded-2xl text-lg font-bold <%= audience.fetch(:icon_classes) %>" aria-hidden="true">
                <%= audience.fetch(:initial) %>
              </div>
              <p class="mt-5 text-xs font-bold uppercase tracking-[0.16em] <%= audience.fetch(:eyebrow_classes) %>">
                <%= audience.fetch(:eyebrow) %>
              </p>
              <h3 class="mt-2 text-xl font-semibold tracking-tight <%= audience.fetch(:title_classes) %>">
                <%= audience.fetch(:title) %>
              </h3>
              <p class="mt-3 text-sm leading-6 <%= audience.fetch(:copy_classes) %>">
                <%= audience.fetch(:description) %>
              </p>
              <p class="mt-auto pt-5 text-sm font-semibold <%= audience.fetch(:topics_classes) %>">
                <%= audience.fetch(:topics) %>
              </p>
            </article>
          <% end %>
        </div>
      </section>
    </div>
  </section>

  <script>
    (() => {
      const root = document.currentScript.closest("[data-chakra-container]");
      if (!root || root.dataset.chakraReady === "true") return;
      root.dataset.chakraReady = "true";

      const tabs = Array.from(root.querySelectorAll("[data-chakra-tab]"));
      const panels = Array.from(root.querySelectorAll("[data-chakra-panel]"));

      function activateChakra(slug) {
        tabs.forEach(tab => {
          const isMatch = tab.dataset.chakraTab === slug;
          tab.classList.toggle("is-active", isMatch);
          if (tab.classList.contains("chakra-circle")) {
            tab.setAttribute("aria-selected", isMatch);
            tab.tabIndex = isMatch ? 0 : -1;
          }
          if (tab.classList.contains("mobile-chakra-btn")) {
            tab.setAttribute("aria-expanded", isMatch);
          }
        });

        panels.forEach(panel => {
          const isMatch = panel.dataset.chakraPanel === slug;
          if (isMatch) {
            panel.classList.remove("hidden");
            setTimeout(() => panel.classList.add("is-active"), 10);
          } else {
            panel.classList.remove("is-active");
            panel.classList.add("hidden");
          }
        });
      }

      tabs.forEach(tab => {
        tab.addEventListener("click", () => activateChakra(tab.dataset.chakraTab));
        if (tab.classList.contains("chakra-circle")) {
          tab.addEventListener("keydown", (event) => {
            if (!["ArrowDown", "ArrowUp", "Home", "End"].includes(event.key)) return;
            event.preventDefault();
            const desktopTabs = tabs.filter(t => t.classList.contains("chakra-circle"));
            const index = desktopTabs.indexOf(tab);
            let nextIndex = index;
            if (event.key === "ArrowDown") nextIndex = (index + 1) % desktopTabs.length;
            if (event.key === "ArrowUp") nextIndex = (index - 1 + desktopTabs.length) % desktopTabs.length;
            if (event.key === "Home") nextIndex = 0;
            if (event.key === "End") nextIndex = desktopTabs.length - 1;
            const nextTab = desktopTabs[nextIndex];
            activateChakra(nextTab.dataset.chakraTab);
            nextTab.focus();
          });
        }
      });
    })();
  </script>

  <!-- SEZIONE PERCORSO SELECTOR -->
  <section id="percorso" class="border-t border-slate-200 bg-slate-50 px-5 py-10 md:py-16">
    <div class="mx-auto w-full max-w-6xl">
      <header class="max-w-3xl">
        <p class="text-xs font-semibold uppercase tracking-[0.22em] text-blue-700">
          Percorso personalizzato
        </p>
        <h1 class="mt-3 text-3xl font-semibold tracking-tight text-slate-950 md:text-5xl md:leading-[1.05]">
          Costruisci <span class="text-blue-700">il tuo percorso integrato</span>
        </h1>
        <p class="mt-4 text-base leading-7 text-slate-600">
          Parti dal bisogno che senti oggi. Scegli un programma: il percorso completo comparirà subito sotto, senza aprire altre finestre.
        </p>
      </header>

      <!-- PROGRAM SELECTOR -->
      <div class="mt-9 max-w-2xl rounded-2xl border border-slate-200 bg-slate-50 p-5 md:p-6">
        <label for="path-select" class="block text-lg font-semibold tracking-tight text-slate-950">
          Da dove vuoi iniziare?
        </label>
        <p class="mt-1 text-sm leading-6 text-slate-500">
          Scegli il bisogno più vicino alla tua situazione attuale.
        </p>
        <div class="relative mt-4">
          <select id="path-select" aria-controls="path-panel"
            class="w-full appearance-none rounded-xl border border-slate-300 bg-white py-3.5 pl-4 pr-12 text-sm font-semibold text-slate-900 shadow-sm outline-none transition focus:border-blue-500 focus:ring-4 focus:ring-blue-100">
            <option value="" selected disabled>Seleziona il tuo percorso…</option>
            <option value="cura">🩹 Stop al Dolore</option>
            <option value="prevenzione">🛡️ Prevenzione</option>
            <option value="performance">⚡ Performance</option>
            <option value="fisiologia">🌀 Postura e Fisiologia</option>
            <option value="benessere">🌱 Benessere</option>
            <option value="giardino">🌳 Il Giardino del Corpo</option>
          </select>
          <svg class="pointer-events-none absolute right-4 top-1/2 h-5 w-5 -translate-y-1/2 text-slate-400" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
            <path fill-rule="evenodd" d="M5.23 7.21a.75.75 0 0 1 1.06.02L10 11.168l3.71-3.938a.75.75 0 1 1 1.08 1.04l-4.25 4.5a.75.75 0 0 1-1.08 0l-4.25-4.5a.75.75 0 0 1 .02-1.06Z" clip-rule="evenodd" />
          </svg>
        </div>
      </div>

      <!-- The selected path is rendered here, in the normal page flow. -->
      <div id="path-panel" role="region" aria-live="polite"
        class="mt-7 hidden overflow-hidden rounded-[2rem] border border-slate-200 bg-white shadow-sm">
        <div id="path-panel-head" class="border-b border-red-100 bg-red-50 px-6 py-7 md:px-9 md:py-9">
          <p id="path-kicker" class="text-xs font-semibold uppercase tracking-[0.22em] text-red-700"></p>
          <h2 id="path-title" class="mt-3 text-2xl font-semibold tracking-tight text-slate-950 md:text-3xl"></h2>
          <p id="path-description" class="mt-3 max-w-3xl text-sm leading-6 text-slate-600 md:text-base md:leading-7"></p>
        </div>

        <div class="px-6 py-7 md:px-9 md:py-9">
          <!-- Only visible for Il Giardino del Corpo. -->
          <div id="garden-subtabs" class="mb-8 hidden" role="tablist" aria-label="Aree del Giardino del Corpo">
            <div class="inline-flex w-full rounded-2xl bg-violet-50 p-1.5 sm:w-auto">
              <button type="button" data-garden-key="potenziale" role="tab" aria-selected="true"
                class="pc-garden-tab flex-1 rounded-xl bg-violet-700 px-4 py-2.5 text-sm font-semibold text-white shadow-sm sm:flex-none">
                Potenziale umano
              </button>
              <button type="button" data-garden-key="ambiente" role="tab" aria-selected="false"
                class="pc-garden-tab flex-1 rounded-xl px-4 py-2.5 text-sm font-semibold text-violet-700 sm:flex-none">
                Corpo e ambiente
              </button>
            </div>
          </div>

          <div id="path-team" class="mb-9"></div>

          <h3 id="path-steps-title" class="text-lg font-semibold text-slate-950"></h3>
          <div id="path-steps" class="mt-7 space-y-8"></div>

          <div class="mt-9 flex flex-col gap-3 border-t border-slate-100 pt-7 sm:flex-row sm:items-center sm:justify-between">
            <p class="text-sm text-slate-500">Vuoi costruire questo percorso con il professionista giusto?</p>
            <div class="flex flex-col gap-2 sm:flex-row">
              <a id="path-whatsapp-link"
                href="https://wa.me/393792891488"
                target="_blank" rel="noopener noreferrer"
                class="inline-flex items-center justify-center rounded-xl bg-red-600 px-6 py-3.5 text-sm font-semibold text-white transition hover:bg-red-700">
                Inizia questo percorso →
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>

  <%= render "posturacorretta/footer" %>
</div>

<script>
(() => {
  const academyPaths = <%= raw @paths.to_json %>;
  const colorClasses = <%= raw @color_classes.to_json %>;
  const pathTeams = <%= raw @path_teams.to_json %>;
  const pathProfessionals = <%= raw @path_professionals.to_json %>;

  const initializePaths = () => {
    const root = document.getElementById("percorso");
    if (!root || root.dataset.pathsInitialized === "true") return;

    const pathSelect = root.querySelector("#path-select");
    const gardenTabs = Array.from(root.querySelectorAll(".pc-garden-tab"));
    const gardenSubtabs = root.querySelector("#garden-subtabs");
    const panel = root.querySelector("#path-panel");
    if (!pathSelect || !gardenSubtabs || !panel) return;

    root.dataset.pathsInitialized = "true";
    let activeGardenKey = "potenziale";

    const escapeHtml = (value) => String(value).replace(/[&<>'"]/g, char => ({
      "&": "&amp;", "<": "&lt;", ">": "&gt;", "'": "&#39;", "\"": "&quot;"
    }[char]));

    function setGardenTabState() {
      gardenTabs.forEach(tab => {
        const selected = tab.dataset.gardenKey === activeGardenKey;
        tab.setAttribute("aria-selected", selected ? "true" : "false");
        tab.className = selected
          ? "pc-garden-tab flex-1 rounded-xl bg-violet-700 px-4 py-2.5 text-sm font-semibold text-white shadow-sm sm:flex-none"
          : "pc-garden-tab flex-1 rounded-xl px-4 py-2.5 text-sm font-semibold text-violet-700 transition hover:bg-white sm:flex-none";
      });
    }

    function renderPath(pathKey) {
      const path = academyPaths[pathKey];
      const c = colorClasses[path.color];
      const head = root.querySelector("#path-panel-head");
      const team = pathTeams[pathKey];
      const people = pathProfessionals[pathKey] || [];

      head.className = `border-b ${c.border} ${c.soft} px-6 py-7 md:px-9 md:py-9`;
      const kicker = root.querySelector("#path-kicker");
      kicker.textContent = path.kicker;
      kicker.className = `text-xs font-semibold uppercase tracking-[0.22em] ${c.text}`;
      root.querySelector("#path-title").textContent = path.title;
      root.querySelector("#path-description").textContent = path.description;
      root.querySelector("#path-steps-title").textContent = path.stepsTitle;
      root.querySelector("#path-team").innerHTML = team ? `
        <section class="rounded-2xl border ${c.border} bg-slate-50 p-5 md:p-6">
          <div class="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
            <div>
              <p class="text-xs font-semibold uppercase tracking-[0.18em] ${c.text}">Team del percorso</p>
              <h3 class="mt-1 text-xl font-semibold tracking-tight text-slate-950">Professionisti che aderiscono</h3>
              <p class="mt-2 max-w-3xl text-sm leading-6 text-slate-600">Ogni percorso ha un iniziatore che tiene il filo, imposta il programma iniziale e puo aggiungere altri professionisti con il loro programma.</p>
            </div>
            <div class="flex shrink-0 gap-2">
              <span class="rounded-full bg-white px-3 py-1.5 text-xs font-semibold text-slate-600 ring-1 ring-slate-200">Standard</span>
              <span class="rounded-full ${c.soft} px-3 py-1.5 text-xs font-semibold ${c.text} ring-1 ${c.border}">Personalizzato</span>
            </div>
          </div>

          <div class="mt-5 grid gap-4 lg:grid-cols-[0.9fr_1.1fr]">
            <article class="rounded-xl border ${c.border} bg-white p-4">
              <p class="text-[10px] font-semibold uppercase tracking-[0.18em] ${c.text}">${escapeHtml(team.initiator.role)}</p>
              <h4 class="mt-1 text-base font-semibold text-slate-950">${escapeHtml(team.initiator.name)}</h4>
              <p class="mt-2 text-sm leading-6 text-slate-600">${escapeHtml(team.initiator.program)}</p>
              <div class="mt-3 flex flex-wrap gap-2">
                <span class="rounded-full ${c.soft} px-2.5 py-1 text-xs font-medium ${c.text}">${escapeHtml(team.initiator.mode)}</span>
                <span class="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-medium text-slate-600">coordina il percorso</span>
              </div>
            </article>

            <div class="grid gap-3 sm:grid-cols-2">
              ${team.professionals.map(pro => `
                <article class="rounded-xl border border-slate-200 bg-white p-4">
                  <p class="text-[10px] font-semibold uppercase tracking-[0.18em] text-slate-400">${escapeHtml(pro.area)}</p>
                  <h4 class="mt-1 text-sm font-semibold text-slate-950">${escapeHtml(pro.role)}</h4>
                  <p class="mt-2 text-xs leading-5 text-slate-600">${escapeHtml(pro.program)}</p>
                </article>
              `).join("")}
            </div>
          </div>

          ${people.length ? `
            <div class="mt-6 border-t border-slate-200 pt-5">
              <div class="flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
                <div>
                  <p class="text-xs font-semibold uppercase tracking-[0.18em] ${c.text}">A chi affidarti</p>
                  <h4 class="mt-1 text-lg font-semibold tracking-tight text-slate-950">Professionisti consigliati per questo ambito</h4>
                </div>
                <p class="text-sm text-slate-500">La scelta finale puo essere personalizzata in base al tuo caso.</p>
              </div>
              <div class="mt-4 grid gap-4 md:grid-cols-2 xl:grid-cols-3">
                ${people.map(person => `
                  <article class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
                    <div class="aspect-[16/9] bg-slate-100">
                      <img src="${escapeHtml(person.image)}" alt="${escapeHtml(person.name)}" class="h-full w-full object-cover">
                    </div>
                    <div class="p-4">
                      <h5 class="text-base font-semibold text-slate-950">${escapeHtml(person.name)}</h5>
                      <p class="mt-1 text-sm font-semibold ${c.text}">${escapeHtml(person.role)}</p>
                      <p class="mt-2 text-sm leading-6 text-slate-600">${escapeHtml(person.fit)}</p>
                    </div>
                  </article>
                `).join("")}
              </div>
            </div>
          ` : ""}
        </section>
      ` : "";

      root.querySelector("#path-steps").innerHTML = path.steps.map((step, index) => {
        const { label, title, description, tags = [], modules = [], appointments = [] } = step;
        return `
          <article class="relative pl-12 md:pl-14">
            <div class="absolute left-0 top-0 grid h-9 w-9 place-items-center rounded-full ${c.bg} text-sm font-semibold text-white">${index + 1}</div>
            <p class="text-xs font-semibold uppercase tracking-[0.18em] ${c.text}">${escapeHtml(label)}</p>
            <h4 class="mt-1 text-lg font-semibold tracking-tight text-slate-950">${escapeHtml(title)}</h4>
            ${description ? `<p class="mt-2 max-w-3xl text-sm leading-6 text-slate-600">${escapeHtml(description)}</p>` : ""}
            <div class="mt-3 flex flex-wrap gap-2">
              ${tags.map(tag => `<span class="rounded-full ${c.soft} px-2.5 py-1 text-xs font-medium ${c.text}">${escapeHtml(tag)}</span>`).join("")}
            </div>
            ${modules.length ? `
              <div class="mt-5 grid gap-3 md:grid-cols-2">
                ${modules.map(([number, moduleTitle, items]) => `
                  <div class="rounded-xl border ${c.border} p-4">
                    <p class="text-[10px] font-semibold uppercase tracking-[0.18em] ${c.text}">${escapeHtml(number)}</p>
                    <h5 class="mt-1 text-sm font-semibold text-slate-950">${escapeHtml(moduleTitle)}</h5>
                    ${items.length ? `<ul class="mt-2 space-y-1 text-xs leading-5 text-slate-600">${items.map(item => `<li>• ${escapeHtml(item)}</li>`).join("")}</ul>` : ""}
                  </div>
                `).join("")}
              </div>
            ` : ""}
            ${appointments.length ? `
              <div class="mt-5 grid gap-3 md:grid-cols-2">
                ${appointments.map(app => `
                  <div class="rounded-xl border border-slate-200 bg-slate-50 p-4">
                    <h5 class="text-sm font-semibold text-slate-950">${escapeHtml(app.name)}</h5>
                    <p class="mt-1.5 text-xs leading-5 text-slate-600">${escapeHtml(app.desc)}</p>
                    <p class="mt-3 text-[11px] font-semibold ${c.text}">👤 ${escapeHtml(app.prof)}</p>
                  </div>
                `).join("")}
              </div>
            ` : ""}
          </article>
        `;
      }).join("");

      const waLink = root.querySelector("#path-whatsapp-link");
      const message = `Ciao, vorrei iniziare il percorso “${path.kicker}” con PosturaCorretta.`;
      waLink.href = `https://wa.me/393792891488?text=${encodeURIComponent(message)}`;
      waLink.className = `inline-flex items-center justify-center rounded-xl px-6 py-3.5 text-sm font-semibold text-white transition ${c.bg} ${c.hover}`;
    }

    pathSelect.addEventListener("change", () => {
      const selectedKey = pathSelect.value;
      const isGarden = selectedKey === "giardino";
      const pathKey = isGarden ? activeGardenKey : selectedKey;
      gardenSubtabs.classList.toggle("hidden", !isGarden);
      if (isGarden) setGardenTabState();
      renderPath(pathKey);
      panel.classList.remove("hidden");
      panel.scrollIntoView({ behavior: "smooth", block: "start" });
    });

    gardenTabs.forEach(tab => {
      tab.addEventListener("click", () => {
        activeGardenKey = tab.dataset.gardenKey;
        setGardenTabState();
        renderPath(activeGardenKey);
      });
    });

  };

  initializePaths();
})();
</script>
HTML

File.write('app/views/posturacorretta/percorso.html.erb', content)
