import { Controller } from "@hotwired/stimulus"

// Shared behaviour for PosturaCorretta indexes on small screens.
// The markup can stay specific to each page; opening, closing and accessibility
// are deliberately kept in one place.
export default class extends Controller {
  static targets = ["toggle", "panel", "backdrop", "close"]

  connect() {
    this.previouslyFocusedElement = null
    this.bodyOverflow = null
    this.handleResize = this.syncForViewport.bind(this)
    window.addEventListener("resize", this.handleResize)
    this.syncForViewport()
  }

  disconnect() {
    window.removeEventListener("resize", this.handleResize)
    this.restoreDocumentScroll()
  }

  open() {
    if (window.matchMedia("(min-width: 1024px)").matches) return

    this.previouslyFocusedElement = document.activeElement
    this.bodyOverflow = document.body.style.overflow
    document.body.style.overflow = "hidden"

    this.backdropTarget.classList.remove("hidden", "opacity-0")
    this.backdropTarget.classList.add("opacity-100")
    this.panelTarget.classList.remove("-translate-x-full")
    this.panelTarget.classList.add("translate-x-0")
    this.panelTarget.setAttribute("aria-hidden", "false")
    this.toggleTarget.setAttribute("aria-expanded", "true")

    if (this.hasCloseTarget) window.setTimeout(() => this.closeTarget.focus(), 0)
  }

  close() {
    if (!this.hasPanelTarget) return

    const desktop = this.isDesktop()
    this.panelTarget.classList.remove("translate-x-0")
    this.panelTarget.classList.toggle("-translate-x-full", !desktop)
    this.panelTarget.setAttribute("aria-hidden", desktop ? "false" : "true")

    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove("opacity-100")
      this.backdropTarget.classList.add("opacity-0", "hidden")
    }

    if (this.hasToggleTarget) this.toggleTarget.setAttribute("aria-expanded", "false")
    this.restoreDocumentScroll()
  }

  closeFromNavigation() {
    this.close()
  }

  keydown(event) {
    if (event.key !== "Escape" || !this.isOpen()) return

    this.close()
    this.previouslyFocusedElement?.focus()
  }

  isOpen() {
    return this.hasPanelTarget && this.panelTarget.classList.contains("translate-x-0")
  }

  syncForViewport() {
    this.close()
  }

  isDesktop() {
    return window.matchMedia("(min-width: 1024px)").matches
  }

  restoreDocumentScroll() {
    if (this.bodyOverflow === null) return

    document.body.style.overflow = this.bodyOverflow
    this.bodyOverflow = null
  }
}
