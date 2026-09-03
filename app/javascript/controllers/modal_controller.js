import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { dialogId: String }

  connect() {
    if (this.element.tagName === "DIALOG") {
      this.element.addEventListener("click", this.handleBackdropClick)
    }
  }

  disconnect() {
    if (this.element.tagName === "DIALOG") {
      this.element.removeEventListener("click", this.handleBackdropClick)
    }
  }

  handleBackdropClick = (event) => {
    if (event.target === this.element) {
      this.close(event)
    }
  }

  backdropClose(event) {
    if (event.target === this.element) {
      this.close(event)
    }
  }

  open(event) {
    event?.preventDefault()
    const dialog = this.dialog
    if (dialog && !dialog.open) dialog.showModal()
  }

  close(event) {
    event?.preventDefault()
    const dialog = this.dialog
    if (dialog?.open) dialog.close()
  }

  get dialog() {
    if (this.element.tagName === "DIALOG") return this.element
    if (this.hasDialogIdValue && this.dialogIdValue) {
      return document.getElementById(this.dialogIdValue)
    }
    return this.element.closest("dialog")
  }
}
