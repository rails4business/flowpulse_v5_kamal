import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    resetToTop: Boolean,
    positionSelectedAtTop: Boolean
  }

  connect() {
    this.handlePageRestore = () => this.scheduleAlignment()
    window.addEventListener("pageshow", this.handlePageRestore)
    document.addEventListener("turbo:render", this.handlePageRestore)

    this.scheduleAlignment()
  }

  scheduleAlignment() {
    this.alignAfterRender()
    window.clearTimeout(this.alignmentTimer)
    this.alignmentTimer = window.setTimeout(() => this.alignAfterRender(), 200)
  }

  disconnect() {
    window.clearTimeout(this.alignmentTimer)
    window.removeEventListener("pageshow", this.handlePageRestore)
    document.removeEventListener("turbo:render", this.handlePageRestore)
  }

  alignAfterRender() {
    requestAnimationFrame(() => requestAnimationFrame(() => {
      if (this.resetToTopValue) {
        this.element.scrollTo({ top: 0, left: 0, behavior: "auto" })
      } else {
        this.alignSelectedItem()
      }
    }))
  }

  resetToTop(event) {
    if (event?.target?.closest("a") == null) return

    this.element.scrollTo({ top: 0, left: 0, behavior: "auto" })
  }

  alignSelectedItem() {
    const selected = this.element.querySelector('[data-scroll-selected-target="item"], [aria-current="step"], [aria-current="page"]')
    if (!selected) return

    const containerRect = this.element.getBoundingClientRect()
    const selectedRect = selected.getBoundingClientRect()
    const topInside = selectedRect.top - containerRect.top
    const bottomInside = selectedRect.bottom - containerRect.top
    const leftInside = selectedRect.left - containerRect.left
    const rightInside = selectedRect.right - containerRect.left
    const padding = 16

    if (this.positionSelectedAtTopValue && this.element.scrollHeight > this.element.clientHeight) {
      this.element.scrollBy({ top: topInside - padding, behavior: "auto" })
    } else if (this.element.scrollHeight > this.element.clientHeight && topInside < padding) {
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
