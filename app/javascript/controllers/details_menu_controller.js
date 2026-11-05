import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { group: String }

  closePeers() {
    if (!this.element.open || !this.hasGroupValue) return

    document.querySelectorAll('[data-controller~="details-menu"]').forEach((element) => {
      if (element === this.element) return
      if (element.dataset.detailsMenuGroupValue !== this.groupValue) return

      element.open = false
    })
  }

  closeOutside(event) {
    if (this.element.open && !this.element.contains(event.target)) {
      this.element.open = false
    }
  }

  closeOnEscape(event) {
    if (event.key !== "Escape" || !this.element.open) return

    this.element.open = false
    this.element.querySelector("summary")?.focus()
  }
}
