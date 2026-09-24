import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    const requested = new URL(window.location.href).searchParams.get("vista")
    this.activate(requested === "lista" ? "list" : "day")
  }

  select(event) {
    const selected = event.currentTarget.dataset.experiencePlannedKindParam

    this.activate(selected)

    const url = new URL(window.location.href)
    url.searchParams.set("vista", selected === "list" ? "lista" : "giorni")
    window.history.replaceState({}, "", url)
  }

  activate(selected) {
    this.tabTargets.forEach((tab) => {
      const active = tab.dataset.experiencePlannedKindParam === selected
      tab.classList.toggle("border-blue-600", active)
      tab.classList.toggle("text-blue-700", active)
      tab.classList.toggle("border-transparent", !active)
      tab.classList.toggle("text-gray-500", !active)
      tab.setAttribute("aria-selected", active)
    })
    this.panelTargets.forEach((panel) => panel.classList.toggle("hidden", panel.dataset.experiencePlannedKindParam !== selected))
  }
}
