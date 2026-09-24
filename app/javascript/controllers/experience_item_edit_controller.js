import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "form", "heading", "title", "descriptionRow", "description", "processRow", "process", "sessionContextRow", "calendar", "service", "visibility", "datesRow", "startsAt", "endsAt", "statusRow", "status"]

  open(event) {
    const item = event.target.closest("[data-edit-kind]")
    if (!item || this.element.dataset.experienceEditActiveValue !== "true") return

    event.preventDefault()
    event.stopPropagation()

    const kind = item.dataset.editKind
    const root = {
      experience: "data_experience",
      session: "data_session",
      slot: "data_slot",
      commitment: "data_commitment"
    }[kind]

    this.formTarget.action = item.dataset.editUrl
    this.headingTarget.textContent = `Modifica ${this.labelFor(kind)}`
    this.titleTarget.name = `${root}[title]`
    this.titleTarget.value = item.dataset.editTitle || ""

    this.descriptionRowTarget.classList.toggle("hidden", kind !== "experience")
    this.descriptionTarget.name = `${root}[description]`
    this.descriptionTarget.value = item.dataset.editDescription || ""

    this.processRowTarget.classList.toggle("hidden", kind !== "experience")
    this.processTarget.name = `${root}[brand_process_id]`
    this.processTarget.value = item.dataset.editProcessId || ""

    this.sessionContextRowTarget.classList.toggle("hidden", kind !== "session")
    this.calendarTarget.name = `${root}[professional_calendar_id]`
    this.calendarTarget.value = item.dataset.editCalendarId || ""
    this.serviceTarget.name = `${root}[service_id]`
    this.serviceTarget.value = item.dataset.editServiceId || ""
    this.visibilityTarget.name = `${root}[visibility]`
    this.visibilityTarget.value = item.dataset.editVisibility || "private"

    this.datesRowTarget.classList.toggle("hidden", kind === "experience")
    this.startsAtTarget.name = `${root}[starts_at]`
    this.startsAtTarget.value = item.dataset.editStartsAt || ""
    this.endsAtTarget.name = `${root}[ends_at]`
    this.endsAtTarget.value = item.dataset.editEndsAt || ""

    this.statusRowTarget.classList.toggle("hidden", kind !== "commitment")
    this.statusTarget.name = `${root}[status]`
    this.statusTarget.value = item.dataset.editStatus || "planned"

    this.dialogTarget.showModal()
    this.titleTarget.focus()
  }

  close() {
    this.dialogTarget.close()
  }

  closeFromBackdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  labelFor(kind) {
    return { experience: "Esperienza", session: "Sessione", slot: "Slot", commitment: "Commitment" }[kind]
  }
}
