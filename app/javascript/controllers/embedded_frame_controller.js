import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["frame"]

  connect() {
    this.receiveMessage = this.receiveMessage.bind(this)
    window.addEventListener("message", this.receiveMessage)
  }

  disconnect() {
    window.removeEventListener("message", this.receiveMessage)
  }

  receiveMessage(event) {
    if (event.origin !== window.location.origin) return
    if (event.source !== this.frameTarget.contentWindow) return
    if (event.data?.type !== "posturacorretta-map-height") return

    const height = Number(event.data.height)
    if (!Number.isFinite(height) || height < 320) return

    this.frameTarget.style.height = `${Math.ceil(height)}px`
  }
}
