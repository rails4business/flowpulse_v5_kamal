import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.textValue)
      this.element.textContent = "Copiato"
      window.setTimeout(() => { this.element.textContent = "Copia il link" }, 1600)
    } catch (_error) {
      const input = this.element.closest("article")?.querySelector("input[readonly]")
      input?.focus()
      input?.select()
    }
  }
}
