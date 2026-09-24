import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["editButton", "editControl", "readValue"]
  static values = { storageKey: String, editing: { type: Boolean, default: false } }

  connect() {
    this.restore()
    this.editingValue = localStorage.getItem(this.editingStorageKey) === "true"
    this.applyEditing()
  }

  toggleEdit(event) {
    event.preventDefault()
    this.editingValue = !this.editingValue
    localStorage.setItem(this.editingStorageKey, this.editingValue)
    this.applyEditing()
  }

  remember() {
    requestAnimationFrame(() => {
      const openNodes = Array.from(this.element.querySelectorAll("details[data-experience-tree-node-id][open]"))
        .map((node) => node.dataset.experienceTreeNodeId)
      localStorage.setItem(this.storageKeyValue, JSON.stringify(openNodes))
    })
  }

  restore() {
    const saved = localStorage.getItem(this.storageKeyValue)
    if (!saved) return

    const openNodes = JSON.parse(saved)
    this.element.querySelectorAll("details[data-experience-tree-node-id]").forEach((node) => {
      node.open = openNodes.includes(node.dataset.experienceTreeNodeId)
    })
  }

  applyEditing() {
    this.editControlTargets.forEach((element) => element.classList.toggle("hidden", !this.editingValue))
    this.readValueTargets.forEach((element) => element.classList.toggle("hidden", this.editingValue))
    this.editButtonTarget.textContent = this.editingValue ? "Fine modifica" : "Modifica"
    this.editButtonTarget.setAttribute("aria-pressed", this.editingValue)
  }

  get editingStorageKey() {
    return `${this.storageKeyValue}:editing`
  }
}
