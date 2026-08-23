import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel", "subTab", "subPanel", "breadcrumb"]
  static values = {
    activeTab: { type: String, default: "project" },
    tabNames: {
      type: Object,
      default: {
        project: "Project / Lettura generale",
        genera: "GeneraImpresa — COSA?",
        rails4b: "Rails4B — COME?",
        impegno: "1Impegno — CHI E QUANDO?",
        dash: "DASH — GARANZIA"
      }
    },
    subLabels: {
      type: Object,
      default: {
        "genera-visione": "Idea e risultato",
        "genera-previsioni": "Previsioni",
        "genera-piano": "Piano",
        "genera-validazione": "Tester e vendite",
        "rails4b-costruire": "Cosa costruire",
        "rails4b-lavoro": "Lavoro",
        "rails4b-test": "Test",
        "impegno-persone": "Persone e ruoli",
        "impegno-tempo": "Tempo",
        "impegno-abilita": "Abilità",
        "dash-impegni": "Impegni",
        "dash-vincolo": "Vincolo",
        "dash-volatilita": "Volatilità",
        "dash-pagamenti": "Pagamenti"
      }
    }
  }

  connect() {
    this.activeSub = {
      genera: "visione",
      rails4b: "costruire",
      impegno: "persone",
      dash: "impegni"
    }
    this.switchTab(this.activeTabValue)
  }

  changeTab(event) {
    const tab = event.currentTarget.dataset.tab
    this.switchTab(tab)
  }

  changeSubTab(event) {
    const tab = event.currentTarget.closest("[data-subtabs]").dataset.subtabs
    const sub = event.currentTarget.dataset.sub
    this.switchSubTab(tab, sub)
  }

  switchTab(tab) {
    this.activeTabValue = tab

    // Update main panels
    this.panelTargets.forEach(panel => {
      panel.classList.toggle("hidden", panel.id !== `tab-${tab}`)
    })

    // Update main tabs UI
    this.tabTargets.forEach(btn => {
      const isSelected = btn.dataset.tab === tab
      btn.classList.toggle("border-slate-900", isSelected)
      btn.classList.toggle("text-slate-900", isSelected)
      btn.classList.toggle("border-transparent", !isSelected)
      btn.classList.toggle("text-slate-400", !isSelected)
    })

    if (tab === "project") {
      if (this.hasBreadcrumbTarget) {
        this.breadcrumbTarget.textContent = this.tabNamesValue.project
      }
      return
    }

    this.switchSubTab(tab, this.activeSub[tab])
  }

  switchSubTab(tab, sub) {
    this.activeSub[tab] = sub

    // Hide all subpanels for this tab
    const subpanels = this.element.querySelectorAll(`[data-subpanel^="${tab}-"]`)
    subpanels.forEach(panel => panel.classList.add("hidden"))

    // Show active subpanel
    const targetPanel = this.element.querySelector(`[data-subpanel="${tab}-${sub}"]`)
    if (targetPanel) {
      targetPanel.classList.remove("hidden")
    }

    // Update subtab buttons UI
    const subtabs = this.element.querySelectorAll(`[data-subtabs="${tab}"] [data-sub]`)
    subtabs.forEach(btn => {
      const isSelected = btn.dataset.sub === sub
      btn.classList.toggle("bg-slate-900", isSelected)
      btn.classList.toggle("text-white", isSelected)
      btn.classList.toggle("bg-white", !isSelected)
      btn.classList.toggle("text-slate-500", !isSelected)
      btn.classList.toggle("border", !isSelected)
      btn.classList.toggle("border-slate-200", !isSelected)
    })

    if (this.hasBreadcrumbTarget) {
      const mainLabel = this.tabNamesValue[tab] || tab
      const subKey = `${tab}-${sub}`
      const subLabel = this.subLabelsValue[subKey] || sub
      this.breadcrumbTarget.textContent = `${mainLabel}  /  ${subLabel}`
    }
  }
}
