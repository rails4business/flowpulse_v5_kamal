import { Controller } from "@hotwired/stimulus"

// Schede di una scheda stampabile: mostra un pannello alla volta. Tutti i pannelli restano nella pagina,
// così le regole di stampa possono mostrarli uno dopo l'altro.
export default class extends Controller {
  static targets = ["tab", "panel"]

  select(event) {
    this.show(event.currentTarget.dataset.key)
  }

  show(key) {
    this.tabTargets.forEach((tab) => {
      const selected = tab.dataset.key === key
      tab.setAttribute("aria-selected", selected)
      tab.tabIndex = selected ? 0 : -1
    })
    this.panelTargets.forEach((panel) => { panel.hidden = panel.dataset.key !== key })
  }
}
