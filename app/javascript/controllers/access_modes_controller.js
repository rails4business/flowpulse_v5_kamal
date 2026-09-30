import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["option"]

  change(event) {
    const selected = event.currentTarget
    if (!selected.checked) return

    if (selected.value === "free") {
      this.optionTargets.forEach((option) => {
        if (option.value !== "free") option.checked = false
      })
    } else {
      const free = this.optionTargets.find((option) => option.value === "free")
      if (free) free.checked = false
    }
  }
}
