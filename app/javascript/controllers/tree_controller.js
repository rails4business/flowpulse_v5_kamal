import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "cancelMoveButton",
    "editButton",
    "folderDrop",
    "moveLine",
    "moveLineSvg",
    "moveHandle",
    "moveMessage",
    "orderHandle",
    "sidebarBackdrop",
    "sidebarToggle",
    "treeAction",
    "sidebar"
  ]

  connect() {
    this.storageKey = this.element.dataset.treeStorageKey || "flow-tree-open-nodes"
    this.roleAssignmentId = this.element.dataset.treeRoleAssignmentId
    this.sidebarStorageKey = `${this.storageKey}:sidebar-width`
    this.editing = this.editingParamEnabled()
    this.sidebarOpen = false
    this.resizeSidebar = this.resizeSidebar.bind(this)
    this.stopResizeSidebar = this.stopResizeSidebar.bind(this)

    try {
      this.restore()
    } catch (error) {
      console.warn("[TreeController] Failed to restore open nodes state from localStorage:", error)
    }

    try {
      this.restoreSidebarWidth()
    } catch (error) {
      console.warn("[TreeController] Failed to restore sidebar width from localStorage:", error)
    }

    this.applyEditingState()
    this.applySidebarState()
  }

  disconnect() {
    this.stopResizeSidebar()
  }

  toggleEditing() {
    this.editing = !this.editing
    if (!this.editing) {
      this.cancelFolderMove()
      this.closeSidebar()
    }
    this.updateEditingParam()
    this.applyEditingState()
  }

  toggleSidebar() {
    this.sidebarOpen = !this.sidebarOpen
    this.applySidebarState()
  }

  openSidebar() {
    this.sidebarOpen = true
    this.applySidebarState()
  }

  closeSidebar(event) {
    event?.preventDefault()
    event?.stopPropagation()

    this.sidebarOpen = false
    this.applySidebarState()
  }

  selectFolderMove(event) {
    event.preventDefault()
    event.stopPropagation()

    const nodeId = event.currentTarget.dataset.nodeId
    const nodeTitle = event.currentTarget.dataset.nodeTitle || "nodo"
    if (!this.editing || !nodeId) return

    if (this.selectedMoveNodeId === nodeId) {
      this.cancelFolderMove()
      return
    }

    this.selectedMoveNodeId = nodeId
    this.selectedMoveNodeTitle = nodeTitle
    this.selectedMoveSource = event.currentTarget.closest(".tree-item")
    this.element.dataset.treeMovingNodeId = nodeId
    this.openSidebar()
    this.updateFolderMoveState()
  }

  async chooseMoveFolder(event) {
    if (!this.selectedMoveNodeId) return

    event.preventDefault()
    event.stopPropagation()

    const parentId = event.currentTarget.dataset.treeFolderDropId
    if (!parentId || parentId === this.selectedMoveNodeId || this.savingFolderMove) return

    this.savingFolderMove = true
    event.currentTarget.classList.add("tree-folder-drop-target")
    this.updateMoveLine(event.currentTarget)

    try {
      const response = await this.moveNode(this.selectedMoveNodeId, {
        parentId: parentId,
        position: "last"
      })

      if (response.ok) {
        window.location.assign(this.treeUrl(parentId))
      } else {
        window.location.reload()
      }
    } catch (_error) {
      window.location.reload()
    } finally {
      this.savingFolderMove = false
    }
  }

  cancelFolderMove(event) {
    event?.preventDefault()
    event?.stopPropagation()

    this.selectedMoveNodeId = null
    this.selectedMoveNodeTitle = null
    this.selectedMoveSource = null
    delete this.element.dataset.treeMovingNodeId
    this.updateFolderMoveState()
  }

  previewMoveFolder(event) {
    if (!this.selectedMoveNodeId) return

    const target = event.currentTarget
    if (target.dataset.treeFolderDropId === this.selectedMoveNodeId) {
      this.hideMoveLine()
      return
    }

    this.updateMoveLine(target)
  }

  clearMovePreview() {
    if (!this.savingFolderMove) this.hideMoveLine()
  }

  startResizeSidebar(event) {
    if (!this.hasSidebarTarget) return

    event.preventDefault()
    this.resizingSidebar = true
    document.body.style.cursor = "col-resize"
    document.body.style.userSelect = "none"
    window.addEventListener("pointermove", this.resizeSidebar)
    window.addEventListener("pointerup", this.stopResizeSidebar)
  }

  resizeSidebar(event) {
    if (!this.resizingSidebar) return

    const rect = this.sidebarTarget.getBoundingClientRect()
    const maxWidth = Math.min(640, window.innerWidth * 0.55)
    const width = this.clamp(event.clientX - rect.left, 240, maxWidth)

    this.setSidebarWidth(width)
  }

  stopResizeSidebar() {
    if (this.resizingSidebar) {
      localStorage.setItem(this.sidebarStorageKey, `${Math.round(this.currentSidebarWidth())}`)
    }

    this.resizingSidebar = false
    document.body.style.cursor = ""
    document.body.style.userSelect = ""
    window.removeEventListener("pointermove", this.resizeSidebar)
    window.removeEventListener("pointerup", this.stopResizeSidebar)
  }

  toggle(event) {
    const details = event.currentTarget.closest("details")
    if (!details) return

    setTimeout(() => {
      this.save()
    }, 0)
  }

  save() {
    const openIds = Array.from(this.element.querySelectorAll("details[data-node-id][open]"))
      .map((details) => details.dataset.nodeId)

    localStorage.setItem(this.storageKey, JSON.stringify(openIds))
  }

  restore() {
    const raw = localStorage.getItem(this.storageKey)
    if (!raw) return

    const openIds = JSON.parse(raw)

    this.element.querySelectorAll("details[data-node-id]").forEach((details) => {
      details.open = openIds.includes(details.dataset.nodeId)
    })
  }

  restoreSidebarWidth() {
    if (!this.hasSidebarTarget) return

    const width = Number.parseInt(localStorage.getItem(this.sidebarStorageKey), 10)
    if (!Number.isNaN(width)) this.setSidebarWidth(this.clamp(width, 240, 640))
  }

  applyEditingState() {
    this.element.dataset.treeEditing = this.editing ? "true" : "false"

    if (this.hasEditButtonTarget) {
      this.editButtonTarget.textContent = this.editing ? "Fine modifica" : "Modifica"
      this.editButtonTarget.setAttribute("aria-pressed", this.editing)
    }

    this.treeActionTargets.forEach((action) => {
      action.classList.toggle("hidden", !this.editing)
    })

    this.orderHandleTargets.forEach((handle) => {
      handle.classList.toggle("hidden", !this.editing)
    })

    this.moveHandleTargets.forEach((handle) => {
      handle.draggable = false
      handle.classList.toggle("hidden", !this.editing)
      handle.setAttribute("aria-disabled", !this.editing)
      handle.tabIndex = this.editing ? 0 : -1
    })

    this.updateFolderMoveState()

    window.dispatchEvent(new CustomEvent("tree:editing-changed", {
      detail: { enabled: this.editing }
    }))

    requestAnimationFrame(() => {
      window.dispatchEvent(new CustomEvent("tree:editing-changed", {
        detail: { enabled: this.editing }
      }))
    })
  }

  applySidebarState() {
    this.element.dataset.treeSidebarOpen = this.sidebarOpen ? "true" : "false"

    if (this.hasSidebarToggleTarget) {
      this.sidebarToggleTarget.textContent = this.sidebarOpen ? "×" : "☰"
      this.sidebarToggleTarget.setAttribute("aria-expanded", this.sidebarOpen)
      this.sidebarToggleTarget.setAttribute(
        "aria-label",
        this.sidebarOpen ? "Chiudi menu" : "Apri menu"
      )
    }
  }

  setSidebarWidth(width) {
    this.sidebarTarget.style.flexBasis = `${width}px`
    this.sidebarTarget.style.width = `${width}px`
  }

  currentSidebarWidth() {
    return this.sidebarTarget.getBoundingClientRect().width
  }

  clamp(value, min, max) {
    return Math.max(min, Math.min(value, max))
  }

  editingParamEnabled() {
    return new URL(window.location.href).searchParams.get("editing") === "order"
  }

  updateEditingParam() {
    const url = new URL(window.location.href)

    if (this.editing) {
      url.searchParams.set("editing", "order")
    } else {
      url.searchParams.delete("editing")
    }

    window.history.replaceState({}, "", url)
  }

  moveNode(nodeId, { parentId, position }) {
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

  updateFolderMoveState() {
    this.moveHandleTargets.forEach((handle) => {
      const selected = handle.dataset.nodeId === this.selectedMoveNodeId
      handle.classList.toggle("tree-move-handle-selected", selected)
      handle.closest(".tree-item")?.classList.toggle("tree-card-moving", selected)
      handle.textContent = selected ? "Selezionato" : "Sposta"
    })

    this.folderDropTargets.forEach((target) => {
      const isCurrentNode = target.dataset.treeFolderDropId === this.selectedMoveNodeId
      target.classList.remove("tree-folder-drop-target")
      target.classList.toggle("tree-folder-pick-target", Boolean(this.selectedMoveNodeId) && !isCurrentNode)
      target.classList.toggle("tree-folder-invalid-target", Boolean(this.selectedMoveNodeId) && isCurrentNode)
    })

    if (this.hasMoveMessageTarget) {
      this.moveMessageTarget.textContent = this.selectedMoveNodeId
        ? `Sposta "${this.selectedMoveNodeTitle}" in...`
        : ""
      this.moveMessageTarget.classList.toggle("hidden", !this.selectedMoveNodeId)
    }

    if (this.hasCancelMoveButtonTarget) {
      this.cancelMoveButtonTarget.classList.toggle("hidden", !this.selectedMoveNodeId)
    }

    if (!this.selectedMoveNodeId) this.hideMoveLine()
  }

  treeUrl(nodeId) {
    return `/creator_world/role_assignments/${this.roleAssignmentId}/nodes/${nodeId}/tree?editing=order&tab=node`
  }

  moveUrl(nodeId) {
    return `/creator_world/role_assignments/${this.roleAssignmentId}/nodes/${nodeId}/move`
  }

  updateMoveLine(target) {
    if (!this.hasMoveLineSvgTarget || !this.hasMoveLineTarget || !this.selectedMoveSource) return

    const sourceRect = this.selectedMoveSource.getBoundingClientRect()
    const targetRect = target.getBoundingClientRect()
    const containerRect = this.element.getBoundingClientRect()
    const startX = sourceRect.left - containerRect.left + 8
    const startY = sourceRect.top - containerRect.top + sourceRect.height / 2
    const endX = targetRect.right - containerRect.left - 8
    const endY = targetRect.top - containerRect.top + targetRect.height / 2

    this.moveLineSvgTarget.setAttribute("viewBox", `0 0 ${containerRect.width} ${containerRect.height}`)
    this.moveLineTarget.setAttribute("x1", startX)
    this.moveLineTarget.setAttribute("y1", startY)
    this.moveLineTarget.setAttribute("x2", endX)
    this.moveLineTarget.setAttribute("y2", endY)
    this.moveLineSvgTarget.classList.remove("hidden")
  }

  hideMoveLine() {
    if (this.hasMoveLineSvgTarget) this.moveLineSvgTarget.classList.add("hidden")
  }
}
