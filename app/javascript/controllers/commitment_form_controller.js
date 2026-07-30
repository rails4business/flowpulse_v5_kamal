import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "pricingType", "hourlyFields", "fixedFields"]

  open() {
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  pricingChanged() {
    const hourly = this.pricingTypeTarget.value === "hourly"
    const fixed = this.pricingTypeTarget.value === "fixed"
    this.hourlyFieldsTarget.hidden = !hourly
    this.fixedFieldsTarget.hidden = !fixed
  }
}
