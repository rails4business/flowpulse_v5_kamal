import { Controller } from "@hotwired/stimulus"

// Scrive nel foglio la data e l'ora del momento in cui si stampa o si salva il PDF.
export default class extends Controller {
  static targets = ["date"]

  connect() {
    this.update = this.update.bind(this)
    window.addEventListener("beforeprint", this.update)
  }

  disconnect() {
    window.removeEventListener("beforeprint", this.update)
  }

  print() {
    this.update()
    window.print()
  }

  update() {
    const now = new Date()
    const date = now.toLocaleDateString("it-IT", { day: "numeric", month: "long", year: "numeric" })
    const time = now.toLocaleTimeString("it-IT", { hour: "2-digit", minute: "2-digit" })
    this.dateTarget.textContent = `${date}, ore ${time}`
  }
}
