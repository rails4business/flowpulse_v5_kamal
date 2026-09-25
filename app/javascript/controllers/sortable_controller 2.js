import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  connect() {
    this.roleAssignmentId = this.element.dataset.roleAssignmentId
    this.changeEditing = this.changeEditing.bind(this)
    window.addEventListener("tree:editing-changed", this.changeEditing)

    this.sortable = Sortable.create(this.element, {
      group: "nodes",
      animation: 150,
      draggable: ".tree-item",
      handle: "[data-sortable-handle]",
      filter: "[data-tree-move-handle]",
      preventOnFilter: false,
      fallbackOnBody: false,
      fallbackClass: "sortable-node-fallback",
      emptyInsertThreshold: 24,
      disabled: true,
      ghostClass: "sortable-node-ghost",
      chosenClass: "sortable-node-chosen",
      dragClass: "sortable-node-drag",
      onMove: this.onMove.bind(this),
      onAdd: this.persist.bind(this),
      onUpdate: this.persist.bind(this),
      onEnd: this.onEnd.bind(this)
    })

    requestAnimationFrame(() => this.syncEditing())
    setTimeout(() => this.syncEditing(), 0)
  }

  disconnect() {
    window.removeEventListener("tree:editing-changed", this.changeEditing)
    this.sortable?.destroy()
  }

  get editingEnabled() {
    return this.element.closest("[data-tree-editing='true']") !== null || this.editingParamEnabled()
  }

  changeEditing(event) {
    this.sortable.option("disabled", !event.detail.enabled)
  }

  syncEditing() {
    this.sortable?.option("disabled", !this.editingEnabled)
  }

  editingParamEnabled() {
    return new URL(window.location.href).searchParams.get("editing") === "order"
  }

  onMove(event) {
    const nodeId = event.dragged?.dataset.nodeId
    if (!nodeId) return true
    if (!event.to?.matches("[data-controller~='sortable']")) return false

    return !event.to.closest(`[data-node-id="${nodeId}"]`)
  }

  onEnd(event) {
    this.cleanupDragState(event)
  }

  async persist(event) {
    const item = event.item
    const nodeId = item.dataset.nodeId
    const parentId = event.to.dataset.parentId || ""
    const position = (event.newDraggableIndex ?? event.newIndex) + 1

    if (!nodeId) return
    if (this.saving) return

    this.saving = true
    this.sortable.option("disabled", true)

    try {
      const response = await this.moveNode(nodeId, parentId, position)

      if (response.ok) {
        const treeNodeId = parentId || nodeId
        window.location.assign(this.treeUrl(treeNodeId))
      } else {
        window.location.reload()
      }
    } catch (_error) {
      window.location.reload()
    } finally {
      this.saving = false
    }
  }

  moveNode(nodeId, parentId, position) {
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
    const controller = new AbortController()
    const timeout = window.setTimeout(() => controller.abort(), 8000)

    return fetch(this.moveUrl(nodeId), {
        method: "PATCH",
        credentials: "same-origin",
        signal: controller.signal,
        headers: {
          ...(csrfToken ? { "X-CSRF-Token": csrfToken } : {}),
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: JSON.stringify({
          parent_id: parentId,
          position: position
        })
      }).finally(() => window.clearTimeout(timeout))
  }

  treeUrl(nodeId) {
    return `/creator_world/role_assignments/${this.roleAssignmentId}/nodes/${nodeId}/tree?editing=order&tab=node`
  }

  moveUrl(nodeId) {
    return `/creator_world/role_assignments/${this.roleAssignmentId}/nodes/${nodeId}/move`
  }

  revert(event) {
    event.from.insertBefore(event.item, event.from.children[event.oldIndex] || null)
  }

  cleanupDragState(event) {
    event.item.classList.remove(
      "sortable-node-chosen",
      "sortable-node-ghost",
      "sortable-node-drag",
      "sortable-node-fallback"
    )

    document.querySelectorAll(".sortable-node-chosen, .sortable-node-ghost, .sortable-node-drag").forEach((element) => {
      element.classList.remove("sortable-node-chosen", "sortable-node-ghost", "sortable-node-drag")
    })

    document.querySelectorAll(".sortable-node-fallback").forEach((element) => {
      if (element !== event.item) element.remove()
    })
  }
}
