import { Controller } from "@hotwired/stimulus"

// Scrive nel foglio la data e l'ora del momento in cui si stampa o si salva il PDF.
export default class extends Controller {
  static targets = ["date"]

  connect() {
    this.update = this.update.bind(this)
    this.preparePrint = this.preparePrint.bind(this)
    this.restorePrint = this.restorePrint.bind(this)
    window.addEventListener("beforeprint", this.preparePrint)
    window.addEventListener("afterprint", this.restorePrint)
  }

  disconnect() {
    window.removeEventListener("beforeprint", this.preparePrint)
    window.removeEventListener("afterprint", this.restorePrint)
    this.restorePrint()
  }

  print() {
    this.update()
    this.preparePrint()
    window.print()
  }

  preparePrint() {
    this.update()
    if (this.placeholder) return

    this.placeholder = document.createComment("print-sheet-placeholder")
    this.element.before(this.placeholder)
    document.body.append(this.element)
    document.body.classList.add("pc-printing-sheet")
    this.element.classList.add("is-print-target")
  }

  restorePrint() {
    if (!this.placeholder) return

    this.placeholder.replaceWith(this.element)
    this.placeholder = null
    this.element.classList.remove("is-print-target")
    document.body.classList.remove("pc-printing-sheet")
  }

  update() {
    const now = new Date()
    const date = now.toLocaleDateString("it-IT", { day: "numeric", month: "long", year: "numeric" })
    const time = now.toLocaleTimeString("it-IT", { hour: "2-digit", minute: "2-digit" })
    this.dateTarget.textContent = `${date}, ore ${time}`
  }
}
