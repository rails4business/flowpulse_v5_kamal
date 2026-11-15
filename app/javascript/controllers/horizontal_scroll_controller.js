import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["track"]
  static values = { centerSelected: Boolean }

  connect() {
    if (!this.centerSelectedValue) return

    const selected = this.trackTarget.querySelector("[aria-current='step']")
    if (!selected) return

    const track = this.trackTarget.getBoundingClientRect()
    const station = selected.getBoundingClientRect()
    this.trackTarget.scrollLeft += station.left - track.left - (track.width - station.width) / 2
  }

  previous() { this.scroll(-1) }
  next() { this.scroll(1) }

  scroll(direction) {
    this.trackTarget.scrollBy({ left: direction * Math.max(280, this.trackTarget.clientWidth * 0.72), behavior: "smooth" })
  }
}
