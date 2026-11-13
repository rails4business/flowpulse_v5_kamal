import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["track"]

  previous() { this.scroll(-1) }
  next() { this.scroll(1) }

  scroll(direction) {
    this.trackTarget.scrollBy({ left: direction * Math.max(280, this.trackTarget.clientWidth * 0.72), behavior: "smooth" })
  }
}
