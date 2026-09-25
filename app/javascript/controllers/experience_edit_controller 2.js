import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["control", "button"]
  static values = { active: { type: Boolean, default: false } }

  connect() {
    this.activeValue = new URL(window.location.href).searchParams.get("modifica") === "1"
    this.render()
  }

  toggle() {
    this.activeValue = !this.activeValue
    this.render()

    const url = new URL(window.location.href)
    if (this.activeValue) {
      url.searchParams.set("modifica", "1")
    } else {
      url.searchParams.delete("modifica")
    }
    window.history.replaceState({}, "", url)
  }

  render() {
    this.controlTargets.forEach((element) => element.classList.toggle("hidden", !this.activeValue))
    this.buttonTarget.textContent = this.activeValue ? "Fine modifica" : "Modifica"
    this.buttonTarget.setAttribute("aria-pressed", this.activeValue)
  }
}
