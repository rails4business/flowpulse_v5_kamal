import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "tab", "panel", "title", "description"]

  open(event) {
    const trigger = event.currentTarget
    const kind = trigger.dataset.experienceAddKindParam
    const url = trigger.dataset.experienceAddUrlParam
    const context = trigger.dataset.experienceAddContextParam

    this.activate(kind || "session", url, {
      startsAt: trigger.dataset.experienceAddStartsAtParam,
      endsAt: trigger.dataset.experienceAddEndsAtParam
    })
    this.titleTarget.textContent = `Nuov${kind === "session" ? "a" : "o"} ${this.kindLabel(kind || "session")}`
    this.descriptionTarget.textContent = context || "Direttamente nell’esperienza."
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  closeFromBackdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  select(event) {
    this.activate(event.currentTarget.dataset.experienceAddKindParam)
  }

  activate(selected, url = null, defaults = {}) {
    this.tabTargets.forEach((tab) => {
      const active = tab.dataset.experienceAddKindParam === selected
      tab.classList.toggle("border-blue-600", active)
      tab.classList.toggle("text-blue-700", active)
      tab.classList.toggle("border-transparent", !active)
      tab.classList.toggle("text-slate-500", !active)
      tab.setAttribute("aria-selected", active)
    })
    this.panelTargets.forEach((panel) => panel.classList.toggle("hidden", panel.dataset.experienceAddKindParam !== selected))

    const form = this.panelTargets.find((panel) => panel.dataset.experienceAddKindParam === selected)?.querySelector("form")
    if (form) {
      form.action = url || form.dataset.experienceAddDefaultUrl
      const startsAt = form.querySelector("[name$='[starts_at]']")
      const endsAt = form.querySelector("[name$='[ends_at]']")
      if (startsAt) startsAt.value = defaults.startsAt || ""
      if (endsAt) endsAt.value = defaults.endsAt || ""
    }
  }

  kindLabel(kind) {
    return { session: "Sessione", slot: "Slot", commitment: "Impegno" }[kind]
  }
}
