import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    requestAnimationFrame(() => requestAnimationFrame(() => this.alignSelectedItem()))
  }

  alignSelectedItem() {
    const selected = this.element.querySelector('[aria-current="step"]')
    if (!selected) return

    const containerRect = this.element.getBoundingClientRect()
    const selectedRect = selected.getBoundingClientRect()
    const topInside = selectedRect.top - containerRect.top
    const bottomInside = selectedRect.bottom - containerRect.top
    const leftInside = selectedRect.left - containerRect.left
    const rightInside = selectedRect.right - containerRect.left
    const padding = 16

    if (this.element.scrollHeight > this.element.clientHeight && topInside < padding) {
      this.element.scrollBy({ top: topInside - padding, behavior: "auto" })
    } else if (this.element.scrollHeight > this.element.clientHeight && bottomInside > this.element.clientHeight - padding) {
      this.element.scrollBy({ top: bottomInside - this.element.clientHeight + padding, behavior: "auto" })
    }

    if (this.element.scrollWidth > this.element.clientWidth && leftInside < padding) {
      this.element.scrollBy({ left: leftInside - padding, behavior: "auto" })
    } else if (this.element.scrollWidth > this.element.clientWidth && rightInside > this.element.clientWidth - padding) {
      this.element.scrollBy({ left: rightInside - this.element.clientWidth + padding, behavior: "auto" })
    }
  }
}
