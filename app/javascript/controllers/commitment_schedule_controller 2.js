import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["date", "time", "duration", "startsAt", "endsAt", "endPreview"]

  connect() {
    this.sync()
  }

  sync() {
    if (!this.dateTarget.value || !this.timeTarget.value) return

    const start = new Date(`${this.dateTarget.value}T${this.timeTarget.value}`)
    const duration = Number(this.durationTarget.value || 60)
    const finish = new Date(start.getTime() + duration * 60 * 1000)

    this.startsAtTarget.value = this.toLocalInputValue(start)
    this.endsAtTarget.value = this.toLocalInputValue(finish)
    this.endPreviewTarget.textContent = new Intl.DateTimeFormat("it-IT", {
      day: "2-digit", month: "short", hour: "2-digit", minute: "2-digit"
    }).format(finish).replace(",", " ·")
  }

  toLocalInputValue(value) {
    const pad = (number) => String(number).padStart(2, "0")
    return `${value.getFullYear()}-${pad(value.getMonth() + 1)}-${pad(value.getDate())}T${pad(value.getHours())}:${pad(value.getMinutes())}`
  }
}
