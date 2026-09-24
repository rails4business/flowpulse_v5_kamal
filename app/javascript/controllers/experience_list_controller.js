import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  select(event) {
    const selected = event.currentTarget.dataset.experienceListKindParam

    this.tabTargets.forEach((tab) => {
      const active = tab.dataset.experienceListKindParam === selected
      tab.classList.toggle("border-blue-600", active)
      tab.classList.toggle("text-blue-700", active)
      tab.classList.toggle("border-transparent", !active)
      tab.classList.toggle("text-gray-500", !active)
      tab.setAttribute("aria-selected", active)
    })
    this.panelTargets.forEach((panel) => panel.classList.toggle("hidden", panel.dataset.experienceListKindParam !== selected))
  }
}
