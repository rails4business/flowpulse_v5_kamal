import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output", "pricing", "rate", "fixed", "value"]
  static values = { startedAt: String }

  connect() {
    this.render()
    this.interval = window.setInterval(() => this.render(), 1000)
  }

  disconnect() {
    window.clearInterval(this.interval)
  }

  render() {
    const startedAt = new Date(this.startedAtValue).getTime()
    const elapsedSeconds = Math.max(0, Math.floor((Date.now() - startedAt) / 1000))
    const hours = Math.floor(elapsedSeconds / 3600)
    const minutes = Math.floor((elapsedSeconds % 3600) / 60)
    const seconds = elapsedSeconds % 60
    const formattedDuration = [hours, minutes, seconds].map(value => String(value).padStart(2, "0")).join(":")
    this.outputTargets.forEach(output => { output.textContent = formattedDuration })
    this.elapsedSeconds = elapsedSeconds
    this.calculateValue()
  }

  calculateValue() {
    if (!this.hasValueTarget || !this.hasPricingTarget) return

    let amount = null
    if (this.pricingTarget.value === "hourly" && this.hasRateTarget && this.rateTarget.value !== "") {
      amount = (this.elapsedSeconds || 0) / 3600 * Number(this.rateTarget.value)
    } else if (this.pricingTarget.value === "fixed" && this.hasFixedTarget && this.fixedTarget.value !== "") {
      amount = Number(this.fixedTarget.value)
    }
    this.valueTarget.textContent = amount === null ? "—" : new Intl.NumberFormat("it-IT", { style: "currency", currency: "EUR" }).format(amount)
  }
}
