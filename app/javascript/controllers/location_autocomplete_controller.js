import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["country", "input", "results", "status", "clear", "latitude", "longitude", "locationRef"]
  static values = { url: String }

  connect() {
    this.timer = null
    this.abortController = null
    this.activeIndex = -1
  }

  disconnect() {
    window.clearTimeout(this.timer)
    this.abortController?.abort()
  }

  search() {
    this.clearSelection()
    this.clearTarget.hidden = this.inputTarget.value.length === 0
    window.clearTimeout(this.timer)
    const query = this.inputTarget.value.trim()
    if (query.length < 3) {
      this.statusTarget.textContent = query.length ? "Scrivi almeno tre caratteri." : "Scrivi una località e scegli un suggerimento."
      return this.close()
    }

    this.statusTarget.textContent = "Attendo che tu finisca di scrivere…"
    this.timer = window.setTimeout(() => this.fetchResults(query), 400)
  }

  countryChanged() {
    this.inputTarget.value = ""
    this.clearSelection()
    this.close()
    this.statusTarget.textContent = "Paese aggiornato. Ora scrivi la località."
    this.inputTarget.focus()
  }

  clear() {
    this.inputTarget.value = ""
    this.clearSelection()
    this.clearTarget.hidden = true
    this.close()
    this.statusTarget.textContent = "Scrivi una località e scegli un suggerimento."
    this.inputTarget.focus()
  }

  keydown(event) {
    const options = Array.from(this.resultsTarget.querySelectorAll("button"))
    if (!options.length) return

    if (event.key === "ArrowDown") this.activeIndex = Math.min(this.activeIndex + 1, options.length - 1)
    else if (event.key === "ArrowUp") this.activeIndex = Math.max(this.activeIndex - 1, 0)
    else if (event.key === "Enter" && this.activeIndex >= 0) { event.preventDefault(); options[this.activeIndex].click(); return }
    else if (event.key === "Escape") { this.close(); return }
    else return

    event.preventDefault()
    options[this.activeIndex].focus()
  }

  select(event) {
    const location = JSON.parse(event.currentTarget.dataset.location)
    this.inputTarget.value = location.label
    this.countryTarget.value = location.country_code || this.countryTarget.value
    this.latitudeTarget.value = location.latitude
    this.longitudeTarget.value = location.longitude
    this.locationRefTarget.value = location.location_ref || ""
    this.close()
    this.statusTarget.textContent = `Località selezionata: ${location.label}`
    this.element.classList.add("is-selected")
    this.clearTarget.hidden = false
    this.inputTarget.focus()
  }

  async fetchResults(query) {
    this.abortController?.abort()
    this.abortController = new AbortController()
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("q", query)
    url.searchParams.set("country_code", this.countryTarget.value)
    this.statusTarget.textContent = "Cerco le località…"

    try {
      const response = await fetch(url, { headers: { Accept: "application/json" }, signal: this.abortController.signal })
      if (!response.ok) return this.showError()
      this.render(await response.json())
    } catch (error) {
      if (error.name !== "AbortError") this.showError()
    }
  }

  render(locations) {
    this.resultsTarget.replaceChildren()
    this.activeIndex = -1
    locations.forEach((location) => {
      const button = document.createElement("button")
      button.type = "button"
      button.role = "option"
      button.textContent = location.label
      button.dataset.location = JSON.stringify(location)
      button.addEventListener("click", (event) => this.select(event))
      this.resultsTarget.append(button)
    })
    this.resultsTarget.hidden = locations.length === 0
    this.inputTarget.setAttribute("aria-expanded", String(locations.length > 0))
    this.statusTarget.textContent = locations.length ? "Scegli una località dall’elenco." : "Nessuna località trovata. Prova con un nome più ampio."
  }

  clearSelection() {
    this.latitudeTarget.value = ""
    this.longitudeTarget.value = ""
    this.locationRefTarget.value = ""
    this.element.classList.remove("is-selected")
  }

  close() {
    this.resultsTarget.hidden = true
    this.resultsTarget.replaceChildren()
    this.inputTarget.setAttribute("aria-expanded", "false")
    this.activeIndex = -1
  }

  showError() {
    this.close()
    this.statusTarget.textContent = "La ricerca non è disponibile in questo momento. Puoi comunque scrivere la località."
  }
}
