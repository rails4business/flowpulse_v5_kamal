import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "arrow", "button"]

  toggle() {
    const hidden = this.panelTarget.classList.toggle("hidden")
    this.arrowTarget.classList.toggle("rotate-90", !hidden)
    this.buttonTarget.setAttribute("aria-expanded", !hidden)
  }
}
