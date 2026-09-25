import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "hidden", "results", "clearBtn"]

  connect() {
    this.toggleClearButton()
  }

  onInput() {
    const query = this.inputTarget.value.toLowerCase().trim()
    const items = this.resultsTarget.querySelectorAll("[data-title]")
    let count = 0

    items.forEach(item => {
      const title = item.dataset.title.toLowerCase()
      if (title.includes(query)) {
        item.classList.remove("hidden")
        count++
      } else {
        item.classList.add("hidden")
      }
    })

    if (count > 0) {
      this.resultsTarget.classList.remove("hidden")
    } else {
      this.resultsTarget.classList.add("hidden")
    }

    this.toggleClearButton()
  }

  showResults() {
    this.onInput()
  }

  onBlur() {
    // Timeout to allow the mousedown event on results to fire
    setTimeout(() => {
      if (this.hasResultsTarget) {
        this.resultsTarget.classList.add("hidden")
      }
      if (this.hasInputTarget && this.inputTarget.value.trim() === "") {
        this.hiddenTarget.value = ""
        this.toggleClearButton()
      }
    }, 200)
  }

  select(event) {
    const id = event.currentTarget.dataset.id
    const title = event.currentTarget.dataset.title
    const value = event.currentTarget.dataset.value || title

    this.hiddenTarget.value = id
    this.inputTarget.value = value
    this.resultsTarget.classList.add("hidden")
    this.toggleClearButton()

    this.dispatch("selected", { detail: { id, title, value, hasProfile: event.currentTarget.dataset.hasProfile === "true" } })
  }

  clear() {
    this.hiddenTarget.value = ""
    this.inputTarget.value = ""
    this.resultsTarget.classList.add("hidden")
    this.toggleClearButton()
    this.inputTarget.focus()
  }

  toggleClearButton() {
    if (!this.hasClearBtnTarget) return

    if (this.inputTarget.value.length > 0) {
      this.clearBtnTarget.classList.remove("hidden")
    } else {
      this.clearBtnTarget.classList.add("hidden")
    }
  }
}
