import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas", "connections", "domainSelect", "status", "viewport"]
  static values = { nodes: Array, relations: Array, selected: String, open: String }

  connect() {
    this.nodesById = new Map(this.nodesValue.map((node) => [Number(node.id), node]))
    this.nodesBySlug = new Map(this.nodesValue.map((node) => [node.slug, node]))
    this.hierarchyChildren = this.buildRelationMap("source", "target", "Gerarchia")
    this.outgoing = this.buildRelationMap("source", "target")
    this.incoming = this.buildRelationMap("target", "source")
    this.selectedNode = this.nodesBySlug.get(this.selectedValue) || this.nodesValue[0]
    this.boundDrawConnections = this.drawConnections.bind(this)
    window.addEventListener("resize", this.boundDrawConnections)
    this.reset()
  }

  disconnect() {
    window.removeEventListener("resize", this.boundDrawConnections)
  }

  reset() {
    if (!this.selectedNode) return

    const requested = this.openValue.split(",")
      .map((slug) => this.nodesBySlug.get(slug.trim()))
      .filter((node) => node?.lane_container)
    const selectedContainer = this.containerFor(this.selectedNode)
    if (selectedContainer && !requested.some((node) => Number(node.id) === Number(selectedContainer.id))) requested.push(selectedContainer)
    const containers = requested.length > 0 ? requested : [selectedContainer].filter(Boolean)

    this.columns = this.uniqueNodes(containers).map((container) => this.columnFor(container))
    this.render()
    this.syncUrl(this.selectedNode)
  }

  changeDomain(event) {
    const query = new URLSearchParams()
    query.set("vista", new URLSearchParams(window.location.search).get("vista") || "brand")
    window.location.assign(`/flowpulse/rete/globale/corsie/${encodeURIComponent(event.currentTarget.value)}?${query}`)
  }

  selectNode(event) {
    const node = this.nodesById.get(Number(event.currentTarget.dataset.nodeId))
    const columnIndex = Number(event.currentTarget.dataset.columnIndex)
    const relationKind = event.currentTarget.dataset.relationKind
    if (!node) return

    this.selectedNode = node
    const target = this.rightContainerFor(node, this.columns[columnIndex]?.containerId, relationKind)
    this.columns = this.columns.slice(0, columnIndex + 1)
    if (target) {
      const column = this.columnFor(target.container, target.focus)
      column.connectionFromPrevious = { sourceId: Number(node.id), targetId: Number(target.focus.id), kind: target.kind }
      this.columns.push(column)
    }
    this.render()
    this.syncUrl(target?.focus || node)
    if (target) this.scrollToEnd()
  }

  expandLeft(event) {
    event.stopPropagation()
    const node = this.nodesById.get(Number(event.currentTarget.dataset.nodeId))
    const columnIndex = Number(event.currentTarget.dataset.columnIndex)
    const target = this.leftContainerFor(node, this.columns[columnIndex]?.containerId)
    if (!target) return

    this.selectedNode = node
    const retained = this.columns.slice(columnIndex)
    if (retained[0]) retained[0].connectionFromPrevious = { sourceId: Number(target.focus.id), targetId: Number(node.id), kind: target.kind }
    this.columns = this.dedupeColumns([this.columnFor(target.container, target.focus), ...retained])
    this.render()
    this.syncUrl(node)
    this.viewportTarget.scrollTo({ left: 0, behavior: "smooth" })
  }

  closeColumn(event) {
    const columnIndex = Number(event.currentTarget.dataset.columnIndex)
    if (columnIndex <= 0) return

    this.columns = this.columns.slice(0, columnIndex)
    const previous = this.columns[this.columns.length - 1]
    const focused = this.nodesById.get(previous.focusId) || this.nodesById.get(previous.containerId)
    this.selectedNode = focused
    this.render()
    this.syncUrl(focused)
  }

  openNode(event) {
    event.stopPropagation()
  }

  buildRelationMap(sourceKey, targetKey, kind = null) {
    const map = new Map()
    this.relationsValue.forEach((relation) => {
      if (kind && relation.kind !== kind) return
      const source = Number(relation[sourceKey])
      const target = Number(relation[targetKey])
      const entries = map.get(source) || []
      if (!entries.some((entry) => entry.id === target && entry.kind === relation.kind)) entries.push({ id: target, kind: relation.kind })
      map.set(source, entries)
    })
    return map
  }

  columnFor(container, focus = container) {
    return {
      containerId: Number(container.id),
      focusId: Number(focus?.id || container.id),
      title: container.domains[0] || container.title,
      entries: this.entriesForContainer(container)
    }
  }

  entriesForContainer(container) {
    const entries = [{ id: Number(container.id), kind: "Dominio", depth: 0 }]
    const visit = (nodeId, depth, visited) => {
      if (visited.has(nodeId)) return
      visited.add(nodeId)
      this.relatedEntries(this.hierarchyChildren, nodeId).forEach((entry) => {
        const child = this.nodesById.get(entry.id)
        if (!child) return
        entries.push({ ...entry, depth })
        if (!child.lane_container) visit(Number(child.id), depth + 1, visited)
      })
    }
    visit(Number(container.id), 1, new Set())
    this.relatedEntries(this.outgoing, Number(container.id))
      .filter((entry) => entry.kind === "Ponte" && !entries.some((candidate) => Number(candidate.id) === Number(entry.id)))
      .forEach((entry) => entries.push({ ...entry, depth: 1 }))
    return entries
  }

  containerFor(node) {
    let current = node
    const visited = new Set()
    while (current && !visited.has(Number(current.id))) {
      if (current.lane_container) return current
      visited.add(Number(current.id))
      current = this.nodesById.get(Number(current.parent_id))
    }
    return null
  }

  rightContainerFor(node, currentContainerId, preferredKind = null) {
    if (node.lane_container && Number(node.id) !== Number(currentContainerId)) return { container: node, focus: node, kind: preferredKind || "Gerarchia" }
    for (const entry of this.relatedEntries(this.outgoing, Number(node.id))) {
      const targetNode = this.nodesById.get(entry.id)
      let container = this.containerFor(targetNode)
      if (entry.kind === "Ponte") {
        const domainContainer = this.nodesById.get(Number(targetNode?.domain_owner_id))
        if (domainContainer?.lane_container && Number(domainContainer.id) !== Number(currentContainerId)) container = domainContainer
      }
      if (container && Number(container.id) !== Number(currentContainerId)) return { container, focus: targetNode, kind: entry.kind }
    }
    return null
  }

  leftContainerFor(node, currentContainerId) {
    for (const candidate of [node, this.nodesById.get(Number(currentContainerId))].filter(Boolean)) {
      for (const entry of this.relatedEntries(this.incoming, Number(candidate.id))) {
        const sourceNode = this.nodesById.get(entry.id)
        const container = this.containerFor(sourceNode)
        if (container && Number(container.id) !== Number(currentContainerId)) return { container, focus: sourceNode, kind: entry.kind }
      }
    }
    return null
  }

  relatedEntries(map, nodeId) {
    return (map.get(Number(nodeId)) || []).filter((entry) => this.nodesById.has(entry.id)).sort((left, right) => {
      const a = this.nodesById.get(left.id)
      const b = this.nodesById.get(right.id)
      return (Number(a.position) - Number(b.position)) || a.title.localeCompare(b.title, "it")
    })
  }

  render() {
    this.ensureConnections()
    this.canvasTarget.replaceChildren(...this.columns.map((column, index) => this.renderColumn(column, index)))
    const visibleCount = this.columns.reduce((total, column) => total + column.entries.length, 0)
    this.statusTarget.textContent = `${this.columns.length} ${this.columns.length === 1 ? "corsia" : "corsie"} · ${visibleCount} ${visibleCount === 1 ? "Node visibile" : "Node visibili"}`
    requestAnimationFrame(() => this.drawConnections())
  }

  renderColumn(column, columnIndex) {
    const section = document.createElement("section")
    section.dataset.columnIndex = columnIndex
    section.className = "node-lanes-column w-[min(78vw,260px)] shrink-0 border-r border-slate-200 bg-white sm:w-[260px]"
    const heading = document.createElement("div")
    heading.className = "sticky top-0 z-10 flex h-7 items-center justify-center border-b border-slate-200 bg-white/95 px-7 backdrop-blur"
    const title = document.createElement("h2")
    title.className = "truncate text-center text-[10px] font-bold text-slate-700"
    title.textContent = column.title
    heading.append(title)
    if (columnIndex > 0) {
      const close = document.createElement("button")
      close.type = "button"
      close.className = "absolute right-1.5 grid size-5 place-items-center text-xs text-slate-400 hover:text-slate-800"
      close.dataset.action = "node-lanes#closeColumn"
      close.dataset.columnIndex = columnIndex
      close.setAttribute("aria-label", `Chiudi la corsia ${column.title} e le successive`)
      close.textContent = "×"
      heading.append(close)
    }
    section.append(heading)

    const list = document.createElement("div")
    list.className = "flex flex-col items-center gap-6 px-5 py-6"
    column.entries.forEach((entry, index) => list.append(this.renderCard(entry, columnIndex, column, index)))
    section.append(list)
    return section
  }

  renderCard(entry, columnIndex, column, entryIndex) {
    const node = this.nodesById.get(entry.id)
    const owner = this.nodesById.get(column.containerId)
    const external = node.domain_owner_id && Number(node.domain_owner_id) !== Number(owner?.domain_owner_id || column.containerId)
    const selected = Number(entry.id) === Number(column.focusId)
    const wrapper = document.createElement("article")
    wrapper.dataset.laneNodeId = node.id
    wrapper.className = `group relative w-full max-w-[190px] border bg-white transition-colors hover:bg-slate-50 ${entryIndex > 0 ? "node-lanes-card--vertical" : ""} ${external ? "border-2 border-dashed" : ""} ${selected ? "ring-2 ring-blue-200 ring-offset-2" : ""}`
    wrapper.style.borderColor = node.color || "#94A3B8"
    wrapper.style.backgroundColor = `${node.color || "#64748B"}0D`

    const main = document.createElement("button")
    main.type = "button"
    main.className = "block min-h-14 w-full px-3 py-2.5 text-center"
    main.dataset.action = "node-lanes#selectNode"
    main.dataset.nodeId = node.id
    main.dataset.columnIndex = columnIndex
    main.dataset.relationKind = entry.kind
    const relation = document.createElement("span")
    relation.className = `mb-1 block text-[8px] font-bold uppercase tracking-[.08em] ${entry.kind === "Ponte" ? "text-violet-600" : "text-slate-400"}`
    relation.textContent = entry.kind === "Ponte" ? "Ponte" : (node.lane_container && entryIndex > 0 ? "Apri corsia" : "")
    const title = document.createElement("strong")
    title.className = "block text-[11px] leading-4 text-slate-700"
    title.textContent = node.title
    main.append(relation, title)
    if (node.domains.length > 0) {
      const domain = document.createElement("span")
      domain.className = "mt-1 block truncate text-[8px] font-semibold text-slate-400"
      domain.textContent = node.domains.join(", ")
      main.append(domain)
    }

    const leftTarget = this.leftContainerFor(node, column.containerId)
    if (leftTarget) {
      const left = document.createElement("button")
      left.type = "button"
      left.className = "absolute -left-2.5 -top-2.5 z-10 grid size-5 place-items-center border border-slate-300 bg-white text-[9px] font-black text-slate-500 opacity-0 hover:border-blue-400 hover:text-blue-700 group-hover:opacity-100"
      left.dataset.action = "node-lanes#expandLeft"
      left.dataset.nodeId = node.id
      left.dataset.columnIndex = columnIndex
      left.setAttribute("aria-label", `Mostra la corsia precedente a ${node.title}`)
      left.textContent = "←"
      wrapper.append(left)
    }

    const open = document.createElement("a")
    open.href = node.url
    open.className = "absolute -right-2.5 -top-2.5 z-10 grid size-5 place-items-center border border-slate-300 bg-white text-[8px] font-black text-blue-600 opacity-0 hover:border-blue-400 group-hover:opacity-100"
    open.dataset.action = "click->node-lanes#openNode"
    open.setAttribute("aria-label", `Apri ${node.title}`)
    open.textContent = "↗"
    wrapper.append(main, open)
    return wrapper
  }

  ensureConnections() {
    for (let index = 1; index < this.columns.length; index += 1) {
      if (this.columns[index].connectionFromPrevious) continue
      this.columns[index].connectionFromPrevious = this.inferConnection(this.columns[index - 1], this.columns[index])
    }
  }

  inferConnection(leftColumn, rightColumn) {
    const leftIds = new Set(leftColumn.entries.map((entry) => Number(entry.id)))
    const rightIds = new Set(rightColumn.entries.map((entry) => Number(entry.id)))
    if (leftIds.has(Number(rightColumn.containerId))) {
      return { sourceId: Number(rightColumn.containerId), targetId: Number(rightColumn.containerId), kind: "Gerarchia" }
    }
    const relations = this.relationsValue.filter((relation) => leftIds.has(Number(relation.source)) && rightIds.has(Number(relation.target)))
    const preferred = relations.find((relation) => Number(relation.target) === Number(rightColumn.focusId)) || relations[0]
    if (!preferred) return null
    return { sourceId: Number(preferred.source), targetId: Number(preferred.target), kind: preferred.kind }
  }

  drawConnections() {
    if (!this.hasConnectionsTarget || !this.hasViewportTarget) return

    const svg = this.connectionsTarget
    const viewportRect = this.viewportTarget.getBoundingClientRect()
    svg.replaceChildren(this.connectionDefinitions())
    svg.setAttribute("viewBox", `0 0 ${Math.max(1, viewportRect.width)} ${Math.max(1, viewportRect.height)}`)

    this.columns.forEach((column, index) => {
      if (index === 0 || !column.connectionFromPrevious) return
      const connection = column.connectionFromPrevious
      const source = this.cardElement(index - 1, connection.sourceId)
      const target = this.cardElement(index, connection.targetId)
      if (!source || !target) return

      const sourceRect = source.getBoundingClientRect()
      const targetRect = target.getBoundingClientRect()
      const startX = sourceRect.right - viewportRect.left
      const startY = sourceRect.top + (sourceRect.height / 2) - viewportRect.top
      const endX = targetRect.left - viewportRect.left
      const endY = targetRect.top + (targetRect.height / 2) - viewportRect.top
      const bend = Math.max(24, Math.abs(endX - startX) * 0.42)
      const path = document.createElementNS("http://www.w3.org/2000/svg", "path")
      path.setAttribute("d", `M ${startX} ${startY} C ${startX + bend} ${startY}, ${endX - bend} ${endY}, ${endX} ${endY}`)
      path.setAttribute("fill", "none")
      path.setAttribute("stroke", connection.kind === "Ponte" ? "#7c3aed" : "#94a3b8")
      path.setAttribute("stroke-width", "1.75")
      path.setAttribute("stroke-linecap", "round")
      path.setAttribute("marker-end", connection.kind === "Ponte" ? "url(#lane-arrow-bridge)" : "url(#lane-arrow-hierarchy)")
      if (connection.kind === "Ponte") path.setAttribute("stroke-dasharray", "5 4")
      svg.append(path)
    })
  }

  connectionDefinitions() {
    const wrapper = document.createElementNS("http://www.w3.org/2000/svg", "defs")
    ;[["lane-arrow-hierarchy", "#94a3b8"], ["lane-arrow-bridge", "#7c3aed"]].forEach(([id, color]) => {
      const marker = document.createElementNS("http://www.w3.org/2000/svg", "marker")
      marker.setAttribute("id", id)
      marker.setAttribute("viewBox", "0 0 8 8")
      marker.setAttribute("refX", "7")
      marker.setAttribute("refY", "4")
      marker.setAttribute("markerWidth", "5")
      marker.setAttribute("markerHeight", "5")
      marker.setAttribute("orient", "auto-start-reverse")
      const arrow = document.createElementNS("http://www.w3.org/2000/svg", "path")
      arrow.setAttribute("d", "M 0 0 L 8 4 L 0 8 z")
      arrow.setAttribute("fill", color)
      marker.append(arrow)
      wrapper.append(marker)
    })
    return wrapper
  }

  cardElement(columnIndex, nodeId) {
    return this.canvasTarget.querySelector(`[data-column-index="${columnIndex}"] [data-lane-node-id="${nodeId}"]`)
  }

  syncUrl(focusedNode) {
    if (!focusedNode) return
    const query = new URLSearchParams(window.location.search)
    query.set("vista", query.get("vista") || "brand")
    const slugs = this.columns.map((column) => this.nodesById.get(column.containerId)?.slug).filter(Boolean)
    if (slugs.length > 0) query.set("corsie", slugs.join(","))
    else query.delete("corsie")
    window.history.replaceState({}, "", `/flowpulse/rete/globale/corsie/${encodeURIComponent(focusedNode.slug)}?${query}`)
  }

  uniqueNodes(nodes) {
    const seen = new Set()
    return nodes.filter((node) => !seen.has(Number(node.id)) && seen.add(Number(node.id)))
  }

  dedupeColumns(columns) {
    const seen = new Set()
    return columns.filter((column) => !seen.has(column.containerId) && seen.add(column.containerId))
  }

  scrollToEnd() {
    requestAnimationFrame(() => this.viewportTarget.scrollTo({ left: this.viewportTarget.scrollWidth, behavior: "smooth" }))
  }
}
