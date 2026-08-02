import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { dialogId: String }

  open() {
    document.getElementById(this.dialogIdValue)?.showModal()
  }

  close() {
    document.getElementById(this.dialogIdValue)?.close()
  }
}
