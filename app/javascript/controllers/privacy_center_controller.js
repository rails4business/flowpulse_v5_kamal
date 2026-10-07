import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["banner", "dialog", "category"]
  static values = { config: Object }

  connect() {
    this.storageKey = `flowpulse_privacy_preferences:${window.location.hostname}`
    this.preferences = this.readPreferences()
    this.enableListener = (event) => {
      const button = event.target.closest("[data-privacy-enable]")
      if (button) this.enable({ currentTarget: button })
    }
    document.addEventListener("click", this.enableListener)
    this.applyPreferences()
    if (!this.preferences.savedAt && this.configValue.prompt) this.bannerTarget.hidden = false
  }

  disconnect() { document.removeEventListener("click", this.enableListener) }

  acceptAll() {
    Object.entries(this.configValue.categories).forEach(([key, category]) => {
      this.preferences[key] = key === "necessary" || category.enabled === true
    })
    this.persistAndApply()
  }

  necessaryOnly() {
    Object.keys(this.configValue.categories).forEach((key) => { this.preferences[key] = key === "necessary" })
    this.persistAndApply()
  }

  open() {
    this.categoryTargets.forEach((input) => { input.checked = this.preferences[input.value] === true })
    this.dialogTarget.showModal()
  }

  close() { this.dialogTarget.close() }
  stop(event) { event.stopPropagation() }

  save() {
    this.categoryTargets.forEach((input) => { this.preferences[input.value] = input.checked })
    this.preferences.necessary = true
    this.dialogTarget.close()
    this.persistAndApply()
  }

  enable(event) {
    const category = event.currentTarget.dataset.privacyEnable
    if (!category) return
    this.preferences[category] = true
    this.persistAndApply()
  }

  readPreferences() {
    const defaults = { necessary: true }
    try {
      const stored = JSON.parse(window.localStorage.getItem(this.storageKey) || "null")
      if (!stored || stored.version !== this.configValue.version) return defaults
      const age = Date.now() - new Date(stored.savedAt).getTime()
      return age <= 180 * 24 * 60 * 60 * 1000 ? stored : defaults
    } catch (_) {
      return defaults
    }
  }

  persistAndApply() {
    this.preferences.version = this.configValue.version
    this.preferences.savedAt = new Date().toISOString()
    window.localStorage.setItem(this.storageKey, JSON.stringify(this.preferences))
    this.bannerTarget.hidden = true
    this.applyPreferences()
  }

  async applyPreferences() {
    document.querySelectorAll("[data-privacy-placeholder]").forEach((element) => {
      element.hidden = this.preferences[element.dataset.privacyPlaceholder] === true
    })
    document.querySelectorAll("[data-privacy-content]").forEach((element) => {
      element.hidden = this.preferences[element.dataset.privacyContent] !== true
    })
    document.querySelectorAll("[data-privacy-embed-src]").forEach((element) => {
      const allowed = this.preferences[element.dataset.privacyCategory] === true
      if (allowed && element.src !== element.dataset.privacyEmbedSrc) element.src = element.dataset.privacyEmbedSrc
      if (!allowed && element.getAttribute("src")) element.removeAttribute("src")
    })

    await this.loadAllowedResources()
    window.dispatchEvent(new CustomEvent("privacy:changed", { detail: { ...this.preferences } }))
  }

  async loadAllowedResources() {
    const resources = [...document.querySelectorAll("[data-privacy-category][data-privacy-src], [data-privacy-category][data-privacy-href]")]
      .filter((resource) => this.preferences[resource.dataset.privacyCategory] === true && resource.dataset.privacyLoaded !== "true")

    await Promise.all(resources.map((resource) => new Promise((resolve) => {
      const loaded = resource.dataset.privacySrc ? document.createElement("script") : document.createElement("link")
      if (resource.dataset.privacySrc) loaded.src = resource.dataset.privacySrc
      else { loaded.rel = "stylesheet"; loaded.href = resource.dataset.privacyHref }
      loaded.onload = resolve
      loaded.onerror = resolve
      resource.dataset.privacyLoaded = "true"
      document.head.appendChild(loaded)
    })))
  }
}
