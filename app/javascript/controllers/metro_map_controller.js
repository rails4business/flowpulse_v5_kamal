import { Controller } from "@hotwired/stimulus"
import { calculateMetroSchematicLayout, routeMetroConnection, routeMetroNetwork } from "metro_schematic_layout"

const SVG_NS = "http://www.w3.org/2000/svg"

export default class extends Controller {
  static targets = ["canvas", "stage", "detailsPanel", "title", "meta", "openLink", "openMetroLink", "editNodeLink", "empty", "fullscreenButton", "renderStatus", "editButton", "saveButton", "structureButton", "moveModeButton", "linePanel", "offerPanel", "exportPanel", "structurePanel", "nodeTab", "bridgeTab", "parentTab", "lineStationIds", "lineStationList", "offerLine", "offerStartId", "offerEndId", "offerStartButton", "offerEndButton", "discountPercent", "newNodeParentId", "newNodeParentButton", "bridgeSourceId", "bridgeTargetId", "bridgeSourceButton", "bridgeTargetButton", "moveNodeId", "moveParentId", "moveNodeButton", "moveParentButton", "legendPanel"]
  static values = { graph: Object, saveUrl: String }

  connect() {
    this.lineStationSelection = []
    this.moveBranch = true
    this.fullscreenHandler = () => this.updateFullscreenButton()
    document.addEventListener("fullscreenchange", this.fullscreenHandler)
    this.render()
  }

  disconnect() {
    document.removeEventListener("fullscreenchange", this.fullscreenHandler)
    if (this.keyHandler) document.removeEventListener("keydown", this.keyHandler)
    if (this.railUpdateFrame) cancelAnimationFrame(this.railUpdateFrame)
  }

  render() {
    const nodeElements = this.graphValue.elements.filter((element) => element.data.nodeId)
    const edgeElements = this.graphValue.elements.filter((element) => element.data.source && element.data.target)
    const nodes = new Map(nodeElements.map((element) => [element.data.id, element.data]))
    const layout = calculateMetroSchematicLayout({
      nodes: Array.from(nodes.values()),
      edges: edgeElements.map((element) => element.data),
      rootId: this.graphValue.root_id
    })
    nodeElements.forEach((element) => {
      if (Number.isFinite(element.data.savedX) && Number.isFinite(element.data.savedY)) {
        layout.positions.set(element.data.id, { ...layout.positions.get(element.data.id), x: element.data.savedX, y: element.data.savedY })
      }
    })
    this.positions = layout.positions
    this.edges = edgeElements.map((element) => element.data)
    this.nodes = nodes
    this.collapsedById = new Map(nodeElements.map((element) => [element.data.id, element.data.collapsed === true]))
    this.pendingPositions = new Map()
    layout.paths = routeMetroNetwork(this.positions, this.edges)
    layout.bounds = this.boundsFor(layout.positions)
    const grid = this.graphValue.grid ? this.gridGeometry(this.graphValue.grid, layout.positions) : null
    if (grid) layout.bounds = this.boundsIncluding(layout.bounds, grid.top - 40)

    this.svg = document.createElementNS(SVG_NS, "svg")
    this.svg.setAttribute("class", "size-full select-none")
    this.svg.setAttribute("role", "img")
    this.svg.setAttribute("aria-label", `Mappa metropolitana di ${this.graphValue.domain}`)
    this.svg.setAttribute("preserveAspectRatio", "xMidYMid meet")
    this.fullBounds = layout.bounds
    this.viewBox = { ...this.fullBounds }
    this.applyViewBox()
    if (grid) this.svg.append(this.drawGrid(grid))

    const rails = document.createElementNS(SVG_NS, "g")
    rails.setAttribute("aria-hidden", "true")
    edgeElements.forEach((element) => this.drawRail(rails, element.data, layout.paths.get(element.data.id)))
    this.svg.append(rails)

    this.lines = this.graphValue.lines || []
    this.lineTracks = document.createElementNS(SVG_NS, "g")
    this.lineTracks.setAttribute("aria-hidden", "true")
    this.svg.append(this.lineTracks)

    const stations = document.createElementNS(SVG_NS, "g")
    nodeElements.forEach((element) => this.drawStation(stations, element.data, layout.positions.get(element.data.id)))
    this.svg.append(stations)

    this.canvasTarget.replaceChildren(this.svg)
    this.installPanAndZoom()
    this.refreshVisibility()
    this.renderLegend()
    this.renderStatusTarget.textContent = `${nodeElements.length} stazioni · ${edgeElements.length} binari`
  }

  boundsFor(positions) {
    const values = Array.from(positions.values())
    const padding = 140
    const minX = Math.min(...values.map((position) => position.x)) - padding
    const minY = Math.min(...values.map((position) => position.y)) - padding
    const maxX = Math.max(...values.map((position) => position.x)) + padding
    const maxY = Math.max(...values.map((position) => position.y)) + padding
    return {
      x: minX,
      y: minY,
      width: Math.max(900, maxX - minX),
      height: Math.max(560, maxY - minY)
    }
  }

  // Tabella sessioni × slot: le righe sono fasce attorno alla y di ogni slot, le colonne arrivano
  // fino all'ultima stazione che cade dentro le fasce.
  gridGeometry(grid, positions) {
    const step = Number(grid.column_step)
    const firstX = Number(grid.first_x)
    const ys = grid.rows.map((row) => Number(row.y))
    const bands = grid.rows.map((row, index) => {
      const y = ys[index]
      const top = index === 0 ? y - step * 0.56 : (ys[index - 1] + y) / 2
      const bottom = index === ys.length - 1 ? y + step * 0.56 : (y + ys[index + 1]) / 2
      return { label: row.label, top, bottom }
    })
    const left = firstX - step / 2
    const top = bands[0].top - 130
    const bottom = bands.at(-1).bottom
    const xs = Array.from(positions.values()).filter((position) => position.y >= top && position.y <= bottom && position.x >= left).map((position) => position.x)
    const columns = Math.max(1, Math.round((Math.max(firstX, ...xs) - firstX) / step) + 1)
    return { label: grid.column_label || "Sessione", firstX, step, left, right: left + columns * step, top, bottom, bands, columns }
  }

  drawGrid(grid) {
    const group = document.createElementNS(SVG_NS, "g")
    group.setAttribute("aria-hidden", "true")
    group.setAttribute("pointer-events", "none")
    const element = (name, attributes, text) => {
      const node = document.createElementNS(SVG_NS, name)
      Object.entries(attributes).forEach(([key, value]) => node.setAttribute(key, value))
      if (text) node.textContent = text
      group.append(node)
    }

    grid.bands.forEach((band, index) => {
      element("rect", { x: grid.left, y: band.top, width: grid.right - grid.left, height: band.bottom - band.top, fill: index % 2 ? "#f1f5f9" : "#ffffff", opacity: "0.75" })
      element("text", { x: grid.left + 10, y: band.top + 18, fill: "#64748b", "font-size": "13", "font-weight": "800" }, band.label)
    })
    for (let column = 0; column <= grid.columns; column++) {
      const x = grid.left + column * grid.step
      element("line", { x1: x, y1: grid.top, x2: x, y2: grid.bottom, stroke: "#e2e8f0", "stroke-width": "1.5" })
      if (column < grid.columns) {
        element("text", { x: x + grid.step / 2, y: grid.top + 22, fill: "#475569", "font-size": "13", "font-weight": "800", "text-anchor": "middle" }, `${grid.label} ${column + 1}`)
      }
    }
    element("line", { x1: grid.left, y1: grid.top + 34, x2: grid.right, y2: grid.top + 34, stroke: "#cbd5e1", "stroke-width": "1.5" })
    return group
  }

  boundsIncluding(bounds, minY) {
    if (minY >= bounds.y) return bounds
    return { ...bounds, y: minY, height: bounds.height + (bounds.y - minY) }
  }

  drawRail(container, edge, points) {
    if (!points?.length) return
    const rail = document.createElementNS(SVG_NS, "polyline")
    rail.dataset.edgeId = edge.id
    rail.setAttribute("points", points.map((point) => `${point.x},${point.y}`).join(" "))
    rail.setAttribute("fill", "none")
    rail.setAttribute("stroke", edge.kind === "bridge" ? "#94a3b8" : "#cbd5e1")
    rail.setAttribute("stroke-width", edge.kind === "bridge" ? "4" : "6")
    rail.setAttribute("stroke-linecap", "round")
    rail.setAttribute("stroke-linejoin", "round")
    rail.setAttribute("opacity", edge.kind === "bridge" ? "0.9" : "1")
    if (edge.kind === "bridge") rail.setAttribute("stroke-dasharray", "11 9")
    container.append(rail)
  }

  drawStation(container, node, position) {
    if (!position) return
    const group = document.createElementNS(SVG_NS, "g")
    group.setAttribute("transform", `translate(${position.x} ${position.y})`)
    group.setAttribute("tabindex", "0")
    group.setAttribute("role", "button")
    group.setAttribute("aria-label", node.label)
    group.dataset.stationId = node.id
    group.style.cursor = "pointer"
    group.addEventListener("click", () => this.activateStation(node, group))
    group.addEventListener("pointerdown", (event) => this.startStationDrag(event, node, group))
    group.addEventListener("keydown", (event) => {
      if (event.key === "Enter" || event.key === " ") {
        event.preventDefault()
        this.activateStation(node, group)
      }
    })

    const marker = node.terminal ? this.drawTerminalMarker(node) : this.drawStandardMarker(node)

    const label = document.createElementNS(SVG_NS, "text")
    label.setAttribute("x", "0")
    label.setAttribute("y", node.root ? "42" : "32")
    label.setAttribute("text-anchor", "middle")
    label.setAttribute("fill", "#172033")
    label.setAttribute("font-size", node.root ? "13" : "11")
    label.setAttribute("font-weight", node.root ? "800" : "700")
    this.labelLines(node.label).forEach((line, index) => {
      const tspan = document.createElementNS(SVG_NS, "tspan")
      tspan.setAttribute("x", "0")
      tspan.setAttribute("dy", index === 0 ? "0" : "13")
      tspan.textContent = line
      label.append(tspan)
    })

    group.append(marker, label)
    if (this.hasOutgoingConnections(node.id)) group.append(this.drawCollapseControl(node))
    container.append(group)
  }

  drawCollapseControl(node) {
    const control = document.createElementNS(SVG_NS, "g")
    control.classList.add("station-collapse-control")
    control.setAttribute("transform", "translate(21 -21)")
    control.setAttribute("role", "button")
    control.setAttribute("aria-label", `Mostra o nascondi ciò che segue ${node.label}`)
    control.style.cursor = "pointer"
    control.style.display = this.editMode ? "block" : "none"
    control.addEventListener("pointerdown", (event) => {
      event.preventDefault()
      event.stopPropagation()
    })
    control.addEventListener("click", (event) => {
      event.preventDefault()
      event.stopPropagation()
      this.toggleCollapsed(node)
    })

    const circle = document.createElementNS(SVG_NS, "circle")
    circle.setAttribute("r", "11")
    circle.setAttribute("fill", "#ffffff")
    circle.setAttribute("stroke", "#475569")
    circle.setAttribute("stroke-width", "2")

    const symbol = document.createElementNS(SVG_NS, "text")
    symbol.classList.add("station-collapse-symbol")
    symbol.setAttribute("x", "0")
    symbol.setAttribute("y", "4")
    symbol.setAttribute("text-anchor", "middle")
    symbol.setAttribute("font-size", "14")
    symbol.setAttribute("font-weight", "900")
    symbol.setAttribute("fill", "#334155")
    symbol.textContent = this.collapsedById.get(node.id) ? "+" : "−"

    control.append(circle, symbol)
    return control
  }

  drawStandardMarker(node) {
    if (!node.root && node.viewType === "course_lesson") return this.drawDiamondMarker(node)
    if (!node.root && node.viewType === "assessment") return this.drawHexagonMarker(node)
    if (!node.root && node.viewType === "methodology") return this.drawSquareMarker(node)
    if (!node.root && node.viewType === "course") return this.drawCourseMarker(node)
    if (!node.root && node.laneContainer && node.viewType !== "course") return this.drawContainerMarker(node)

    const marker = document.createElementNS(SVG_NS, "g")
    const halo = document.createElementNS(SVG_NS, "circle")
    halo.classList.add("station-outline")
    halo.setAttribute("r", node.root ? "24" : "16")
    halo.setAttribute("fill", "#ffffff")
    halo.setAttribute("stroke", "#e2e8f0")
    halo.setAttribute("stroke-width", node.root ? "7" : "5")

    const dot = document.createElementNS(SVG_NS, "circle")
    dot.setAttribute("r", node.root ? "15" : "10")
    dot.setAttribute("fill", node.color)
    dot.setAttribute("stroke", node.color)
    dot.setAttribute("stroke-width", "2")
    marker.append(halo, dot)
    return marker
  }

  drawCourseMarker(node) {
    const marker = document.createElementNS(SVG_NS, "g")
    const halo = document.createElementNS(SVG_NS, "circle")
    halo.classList.add("station-outline")
    halo.setAttribute("r", "20")
    halo.setAttribute("fill", "#ffffff")
    halo.setAttribute("stroke", "#e2e8f0")
    halo.setAttribute("stroke-width", "5")

    const ring = document.createElementNS(SVG_NS, "circle")
    ring.setAttribute("r", "13")
    ring.setAttribute("fill", "#ffffff")
    ring.setAttribute("stroke", node.color)
    ring.setAttribute("stroke-width", "6")

    const centre = document.createElementNS(SVG_NS, "circle")
    centre.setAttribute("r", "3")
    centre.setAttribute("fill", node.color)
    marker.append(halo, ring, centre)
    return marker
  }

  drawDiamondMarker(node) {
    const marker = document.createElementNS(SVG_NS, "g")
    marker.append(
      this.markerPolygon("0,-19 19,0 0,19 -19,0", "#ffffff", "#e2e8f0", 5, true),
      this.markerPolygon("0,-12 12,0 0,12 -12,0", node.color, node.color, 2)
    )
    return marker
  }

  drawHexagonMarker(node) {
    const marker = document.createElementNS(SVG_NS, "g")
    marker.append(
      this.markerPolygon("-17,-10 0,-20 17,-10 17,10 0,20 -17,10", "#ffffff", "#e2e8f0", 5, true),
      this.markerPolygon("-11,-7 0,-13 11,-7 11,7 0,13 -11,7", node.color, node.color, 2)
    )
    return marker
  }

  drawSquareMarker(node) {
    const marker = document.createElementNS(SVG_NS, "g")
    marker.append(
      this.markerRect(-19, -19, 38, 38, 9, "#ffffff", "#e2e8f0", 5, true),
      this.markerRect(-12, -12, 24, 24, 6, node.color, node.color, 2)
    )
    return marker
  }

  drawContainerMarker(node) {
    const marker = document.createElementNS(SVG_NS, "g")
    marker.append(
      this.markerRect(-25, -16, 50, 32, 16, "#ffffff", "#e2e8f0", 5, true),
      this.markerRect(-19, -10, 38, 20, 10, node.color, node.color, 2)
    )
    return marker
  }

  markerPolygon(points, fill, stroke, width, outline = false) {
    const polygon = document.createElementNS(SVG_NS, "polygon")
    if (outline) polygon.classList.add("station-outline")
    polygon.setAttribute("points", points)
    polygon.setAttribute("fill", fill)
    polygon.setAttribute("stroke", stroke)
    polygon.setAttribute("stroke-width", width)
    polygon.setAttribute("stroke-linejoin", "round")
    return polygon
  }

  markerRect(x, y, width, height, radius, fill, stroke, strokeWidth, outline = false) {
    const rect = document.createElementNS(SVG_NS, "rect")
    if (outline) rect.classList.add("station-outline")
    rect.setAttribute("x", x)
    rect.setAttribute("y", y)
    rect.setAttribute("width", width)
    rect.setAttribute("height", height)
    rect.setAttribute("rx", radius)
    rect.setAttribute("fill", fill)
    rect.setAttribute("stroke", stroke)
    rect.setAttribute("stroke-width", strokeWidth)
    return rect
  }

  drawTerminalMarker(node) {
    const marker = document.createElementNS(SVG_NS, "g")
    const background = document.createElementNS(SVG_NS, "path")
    background.classList.add("station-outline")
    background.setAttribute("d", "M 0 -17 A 17 17 0 0 0 0 17 Z")
    background.setAttribute("fill", "#ffffff")
    background.setAttribute("stroke", "#cbd5e1")
    background.setAttribute("stroke-width", "5")

    const terminal = document.createElementNS(SVG_NS, "path")
    terminal.setAttribute("d", "M 0 -13 A 13 13 0 0 0 0 13 M 0 -17 V 17")
    terminal.setAttribute("fill", "none")
    terminal.setAttribute("stroke", node.color)
    terminal.setAttribute("stroke-width", "5")
    terminal.setAttribute("stroke-linecap", "round")
    marker.append(background, terminal)
    return marker
  }

  labelLines(label) {
    const words = label.split(/\s+/)
    const lines = []
    words.forEach((word) => {
      const current = lines.at(-1)
      if (!current || `${current} ${word}`.length > 24) lines.push(word)
      else lines[lines.length - 1] = `${current} ${word}`
    })
    if (lines.length <= 3) return lines
    return [...lines.slice(0, 2), `${lines.slice(2).join(" ").slice(0, 21)}…`]
  }

  // Lo zoom avviene solo con i pulsanti o con i tasti + − 0: rotella e trackpad non lo modificano.
  installPanAndZoom() {
    this.keyHandler ||= (event) => {
      if (event.target instanceof Element && event.target.closest("input, textarea, select, [contenteditable]")) return
      if (event.metaKey || event.ctrlKey || event.altKey) return
      const actions = { "+": () => this.zoomIn(), "=": () => this.zoomIn(), "-": () => this.zoomOut(), "0": () => this.fit() }
      if (!actions[event.key]) return
      event.preventDefault()
      actions[event.key]()
    }
    document.removeEventListener("keydown", this.keyHandler)
    document.addEventListener("keydown", this.keyHandler)
    this.svg.addEventListener("pointerdown", (event) => {
      if (event.target.closest("g[role='button']")) return
      this.dragStart = { x: event.clientX, y: event.clientY, viewBox: { ...this.viewBox } }
      this.svg.setPointerCapture(event.pointerId)
    })
    this.svg.addEventListener("pointermove", (event) => {
      if (this.stationDrag) {
        const point = this.svgPoint(event)
        const dx = point.x - this.stationDrag.point.x
        const dy = point.y - this.stationDrag.point.y
        this.stationDrag.initialPositions.forEach((initial, id) => {
          const next = { ...this.positions.get(id), x: initial.x + dx, y: initial.y + dy }
          this.positions.set(id, next)
          this.svg.querySelector(`[data-station-id="${id}"]`)?.setAttribute("transform", `translate(${next.x} ${next.y})`)
          const movedNode = this.nodes.get(id)
          this.pendingPositions.set(id, {
            node_id: movedNode.nodeId,
            x: next.x,
            y: next.y,
            collapsed: this.collapsedById.get(id) === true
          })
        })
        this.scheduleRailUpdate()
        return
      }
      if (!this.dragStart) return
      const scaleX = this.viewBox.width / this.svg.clientWidth
      const scaleY = this.viewBox.height / this.svg.clientHeight
      this.viewBox.x = this.dragStart.viewBox.x - (event.clientX - this.dragStart.x) * scaleX
      this.viewBox.y = this.dragStart.viewBox.y - (event.clientY - this.dragStart.y) * scaleY
      this.applyViewBox()
    })
    this.svg.addEventListener("pointerup", () => {
      if (this.stationDrag) this.updateRails()
      this.dragStart = null
      this.stationDrag = null
    })
    this.svg.addEventListener("pointercancel", () => { this.dragStart = null; this.stationDrag = null })
  }

  startStationDrag(event, node, group) {
    if (!this.editMode) return
    event.preventDefault()
    event.stopPropagation()
    const point = this.svgPoint(event)
    const affectedIds = this.moveBranch ? this.downstreamIds(node.id, true) : [node.id]
    const initialPositions = new Map(affectedIds.map((id) => [id, { ...this.positions.get(id) }]))
    this.stationDrag = { node, group, point, initialPositions }
    this.svg.setPointerCapture(event.pointerId)
  }

  svgPoint(event) {
    const point = this.svg.createSVGPoint()
    point.x = event.clientX
    point.y = event.clientY
    return point.matrixTransform(this.svg.getScreenCTM().inverse())
  }

  updateRails(fast = false) {
    const paths = fast
      ? new Map(this.edges.map((edge) => [edge.id, routeMetroConnection(this.positions.get(edge.source), this.positions.get(edge.target))]))
      : routeMetroNetwork(this.positions, this.edges)
    this.edges.forEach((edge) => {
      const rail = this.svg.querySelector(`[data-edge-id="${edge.id}"]`)
      if (!rail) return
      const points = paths.get(edge.id) || []
      rail.setAttribute("points", points.map((point) => `${point.x},${point.y}`).join(" "))
    })
    this.drawLineTracks()
  }

  scheduleRailUpdate() {
    if (this.railUpdateFrame) return
    this.railUpdateFrame = requestAnimationFrame(() => {
      this.railUpdateFrame = null
      this.updateRails(true)
    })
  }

  hasOutgoingConnections(nodeId) {
    return this.edges.some((edge) => edge.source === nodeId)
  }

  downstreamIds(nodeId, includeRoot = false) {
    const visited = new Set([nodeId])
    const result = includeRoot ? [nodeId] : []
    const queue = this.edges.filter((edge) => edge.source === nodeId).map((edge) => edge.target)
    while (queue.length) {
      const id = queue.shift()
      if (visited.has(id)) continue
      visited.add(id)
      result.push(id)
      this.edges.filter((edge) => edge.source === id).forEach((edge) => queue.push(edge.target))
    }
    return result
  }

  toggleCollapsed(node) {
    this.collapsedById.set(node.id, !this.collapsedById.get(node.id))
    const position = this.positions.get(node.id)
    this.pendingPositions.set(node.id, {
      node_id: node.nodeId,
      x: position.x,
      y: position.y,
      collapsed: this.collapsedById.get(node.id)
    })
    this.refreshVisibility()
  }

  refreshVisibility() {
    if (!this.svg) return
    const hidden = new Set()
    this.collapsedById.forEach((collapsed, id) => {
      if (!collapsed || hidden.has(id)) return
      this.downstreamIds(id).forEach((descendantId) => hidden.add(descendantId))
    })

    this.nodes.forEach((_node, id) => {
      const station = this.svg.querySelector(`[data-station-id="${id}"]`)
      if (station) station.style.display = hidden.has(id) ? "none" : "block"
      const symbol = station?.querySelector(".station-collapse-symbol")
      if (symbol) symbol.textContent = this.collapsedById.get(id) ? "+" : "−"
    })
    this.edges.forEach((edge) => {
      const rail = this.svg.querySelector(`[data-edge-id="${edge.id}"]`)
      if (rail) rail.style.display = hidden.has(edge.source) || hidden.has(edge.target) ? "none" : "block"
    })
    this.hiddenIds = hidden
    this.drawLineTracks()
  }

  // Ogni linea è un tracciato colorato che attraversa le sue stazioni nell'ordine della linea;
  // le linee che condividono stazioni sono sfalsate per non sovrapporsi.
  drawLineTracks() {
    if (!this.lineTracks) return
    const spacing = 7
    this.lineTracks.replaceChildren(...this.lines.flatMap((line, index) => {
      const offset = (index - (this.lines.length - 1) / 2) * spacing
      const stationIds = line.stationIds.filter((id) => this.positions.has(id) && !this.hiddenIds?.has(id))
      const track = this.trackElement(stationIds, line.color, 9, offset)
      if (!track) return []
      track.dataset.lineSlug = line.slug
      const elements = [track]
      const offer = this.focusedOffer?.line === line.slug ? line.offers.find((item) => item.slug === this.focusedOffer.slug) : null
      if (offer && Number.isInteger(offer.startIndex) && Number.isInteger(offer.endIndex)) {
        const offerIds = line.stationIds.slice(offer.startIndex, offer.endIndex + 1).filter((id) => this.positions.has(id) && !this.hiddenIds?.has(id))
        const highlight = this.trackElement(offerIds, "#f59e0b", 17, offset)
        if (highlight) {
          highlight.setAttribute("opacity", "0.55")
          elements.unshift(highlight)
        }
      }
      return elements
    }))
    this.applyFocus()
  }

  trackElement(stationIds, color, width, offset) {
    if (stationIds.length < 2) return null
    const points = stationIds.slice(1).reduce((all, id, index) => {
      const segment = routeMetroConnection(this.positions.get(stationIds[index]), this.positions.get(id)) || []
      return all.concat(all.length ? segment.slice(1) : segment)
    }, [])
    const track = document.createElementNS(SVG_NS, "polyline")
    track.setAttribute("points", points.map((point) => `${point.x + offset},${point.y + offset}`).join(" "))
    track.setAttribute("fill", "none")
    track.setAttribute("stroke", color)
    track.setAttribute("stroke-width", String(width))
    track.setAttribute("stroke-linecap", "round")
    track.setAttribute("stroke-linejoin", "round")
    return track
  }

  renderLegend() {
    if (!this.hasLegendPanelTarget) return
    this.legendPanelTarget.hidden = this.lines.length === 0
    const title = document.createElement("div")
    title.className = "flex items-center justify-between gap-2"
    title.innerHTML = '<p class="text-[10px] font-black uppercase tracking-[.14em] text-slate-500">Linee</p>'
    if (this.focusedLine) {
      const reset = document.createElement("button")
      reset.type = "button"
      reset.className = "text-[11px] font-black text-blue-700"
      reset.textContent = "Mostra tutte"
      reset.addEventListener("click", () => this.focusLine(null))
      title.append(reset)
    }

    const rows = this.lines.map((line) => {
      const row = document.createElement("div")
      const button = document.createElement("button")
      button.type = "button"
      button.className = `flex w-full items-center gap-2 rounded-lg px-2 py-1.5 text-left text-xs font-black ${this.focusedLine === line.slug ? "bg-slate-100" : "hover:bg-slate-50"}`
      button.innerHTML = `<span class="h-2 w-6 shrink-0 rounded-full" style="background:${line.color}"></span><span class="min-w-0 flex-1 truncate"></span><span class="text-[10px] text-slate-400">${line.stationIds.length}</span>`
      button.querySelector(".truncate").textContent = line.status === "published" ? line.title : `${line.title} (bozza)`
      button.addEventListener("click", () => this.focusLine(this.focusedLine === line.slug ? null : line.slug))
      row.append(button)
      if (this.focusedLine === line.slug) row.append(this.offerList(line))
      return row
    })
    this.legendPanelTarget.replaceChildren(title, ...rows)
  }

  offerList(line) {
    const list = document.createElement("div")
    list.className = "mb-1 ml-8 mt-1 space-y-1.5"
    if (!line.offers.length) {
      list.innerHTML = '<p class="text-[11px] text-slate-400">Nessuna offerta su questa linea.</p>'
      return list
    }
    const total = Math.max(1, line.stationIds.length)
    line.offers.forEach((offer) => {
      const active = this.focusedOffer?.slug === offer.slug
      const item = document.createElement("button")
      item.type = "button"
      item.className = `block w-full rounded-lg border p-2 text-left ${active ? "border-amber-400 bg-amber-50" : "border-slate-200 hover:bg-slate-50"}`
      const left = (offer.startIndex ?? 0) / total * 100
      const width = ((offer.endIndex ?? 0) - (offer.startIndex ?? 0) + 1) / total * 100
      item.innerHTML = `
        <span class="flex items-center justify-between gap-2 text-[11px] font-black"><span class="offer-title truncate"></span><span class="shrink-0 text-[9px] uppercase tracking-wider text-slate-400">${offer.status === "published" ? "pubblicata" : "bozza"}</span></span>
        <span class="relative mt-1.5 block h-1.5 rounded-full bg-slate-200"><span class="absolute inset-y-0 rounded-full bg-amber-500" style="left:${left}%;width:${width}%"></span></span>
        <span class="offer-meta mt-1 block text-[10px] leading-4 text-slate-500"></span>`
      item.querySelector(".offer-title").textContent = offer.title
      const meta = [`Stazioni ${(offer.startIndex ?? 0) + 1}–${(offer.endIndex ?? 0) + 1}`]
      if (offer.includes.length) meta.push(`comprende ${offer.includes.join(", ")}`)
      if (offer.previousPurchaseMode === "credit") meta.push("credito sul precedente")
      if (offer.previousPurchaseMode === "discount") meta.push(`sconto ${offer.discountPercent ?? 0}%`)
      item.querySelector(".offer-meta").textContent = meta.join(" · ")
      item.addEventListener("click", () => this.focusOffer(line.slug, active ? null : offer.slug))
      list.append(item)
    })
    return list
  }

  focusLine(slug) {
    this.focusedLine = slug
    this.focusedOffer = null
    this.renderLegend()
    this.drawLineTracks()
  }

  focusOffer(lineSlug, offerSlug) {
    this.focusedOffer = offerSlug ? { line: lineSlug, slug: offerSlug } : null
    this.renderLegend()
    this.drawLineTracks()
  }

  // Con una linea selezionata restano in evidenza solo il suo tracciato e le sue stazioni;
  // con un'offerta selezionata si attenuano anche le stazioni della linea fuori dalla tratta.
  applyFocus() {
    const line = this.lines.find((item) => item.slug === this.focusedLine)
    const lineIds = new Set(line?.stationIds || [])
    const offer = line && this.focusedOffer ? line.offers.find((item) => item.slug === this.focusedOffer.slug) : null
    const offerIds = new Set(offer ? line.stationIds.slice(offer.startIndex, offer.endIndex + 1) : [])
    this.nodes.forEach((_node, id) => {
      const station = this.svg.querySelector(`[data-station-id="${id}"]`)
      if (!station) return
      let opacity = 1
      if (line && !lineIds.has(id)) opacity = 0.12
      else if (offer && !offerIds.has(id)) opacity = 0.4
      station.setAttribute("opacity", String(opacity))
    })
    this.edges.forEach((edge) => {
      this.svg.querySelector(`[data-edge-id="${edge.id}"]`)?.setAttribute("opacity", line ? "0.15" : (edge.kind === "bridge" ? "0.9" : "1"))
    })
    this.lineTracks.querySelectorAll("[data-line-slug]").forEach((track) => {
      track.setAttribute("opacity", !line || track.dataset.lineSlug === line.slug ? "0.9" : "0.1")
    })
  }

  toggleEdit() {
    this.editMode = !this.editMode
    this.editButtonTarget.textContent = this.editMode ? "Esci dalla modifica" : "Modifica"
    this.saveButtonTarget.hidden = !this.editMode
    this.structureButtonTarget.hidden = !this.editMode
    this.moveModeButtonTarget.hidden = !this.editMode
    if (!this.editMode) this.structurePanelTarget.hidden = true
    this.renderStatusTarget.textContent = this.editMode
      ? "Trascina un Node con ciò che segue; usa +/− per mostrare o nascondere la prosecuzione"
      : `${this.nodes.size} stazioni · ${this.edges.length} binari`
    this.editNodeLinkTarget.hidden = !this.editMode || !this.selectedNode
    this.svg.querySelectorAll(".station-collapse-control").forEach((control) => {
      control.style.display = this.editMode ? "block" : "none"
    })
  }

  toggleMoveMode() {
    this.moveBranch = !this.moveBranch
    this.moveModeButtonTarget.textContent = this.moveBranch ? "Node + figli" : "Solo Node"
    this.moveModeButtonTarget.classList.toggle("bg-violet-50", !this.moveBranch)
    this.moveModeButtonTarget.classList.toggle("border-violet-300", !this.moveBranch)
    this.renderStatusTarget.textContent = this.moveBranch
      ? "Trascinamento: il Node sposta anche tutti i suoi discendenti"
      : "Trascinamento: si muove soltanto il Node selezionato"
  }

  async savePositions() {
    const token = document.querySelector("meta[name='csrf-token']")?.content
    const response = await fetch(this.saveUrlValue, {
      method: "PATCH",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": token, Accept: "application/json" },
      body: JSON.stringify({ positions: Array.from(this.pendingPositions.values()) })
    })
    if (!response.ok) {
      this.renderStatusTarget.textContent = "Impossibile salvare le posizioni"
      return
    }
    this.pendingPositions.clear()
    this.renderStatusTarget.textContent = "Posizioni salvate per questa mappa"
  }

  changeDomain(event) {
    if (event.currentTarget.value) window.location.assign(event.currentTarget.value)
  }

  zoomIn() { this.zoom(0.8) }
  zoomOut() { this.zoom(1.25) }

  zoom(factor) {
    if (!this.svg) return
    const width = Math.max(240, Math.min(this.fullBounds.width * 2, this.viewBox.width * factor))
    const height = width * (this.viewBox.height / this.viewBox.width)
    this.viewBox.x += (this.viewBox.width - width) / 2
    this.viewBox.y += (this.viewBox.height - height) / 2
    this.viewBox.width = width
    this.viewBox.height = height
    this.applyViewBox()
  }

  fit() {
    this.viewBox = { ...this.fullBounds }
    this.applyViewBox()
  }

  applyViewBox() {
    this.svg?.setAttribute("viewBox", `${this.viewBox.x} ${this.viewBox.y} ${this.viewBox.width} ${this.viewBox.height}`)
  }

  async toggleFullscreen() {
    if (document.fullscreenElement === this.stageTarget) await document.exitFullscreen()
    else await this.stageTarget.requestFullscreen()
  }

  updateFullscreenButton() {
    const active = document.fullscreenElement === this.stageTarget
    this.fullscreenButtonTarget.textContent = active ? "↙" : "⛶"
    this.fullscreenButtonTarget.title = active ? "Esci dallo schermo intero" : "Schermo intero"
  }

  activateStation(node, group) {
    if (this.selectionMode === "line") {
      if (!node.internal || this.lineStationSelection.some((selected) => selected.nodeId === node.nodeId)) return
      this.lineStationSelection.push(node)
      this.updateLineSelection()
      this.select(node, group)
      return
    }
    if (this.selectionMode === "offer-start" || this.selectionMode === "offer-end") {
      if (!this.offerStationIds?.includes(node.nodeId)) {
        this.renderStatusTarget.textContent = "Questa stazione non appartiene alla linea selezionata"
        return
      }
      const start = this.selectionMode === "offer-start"
      const input = start ? this.offerStartIdTarget : this.offerEndIdTarget
      const button = start ? this.offerStartButtonTarget : this.offerEndButtonTarget
      input.value = node.nodeId
      button.textContent = `${start ? "Inizio" : "Fine"}: ${node.label}`
      this.selectionMode = null
      this.select(node, group)
      return
    }
    if (["new-node-parent", "bridge-source", "bridge-target", "move-node", "move-parent"].includes(this.selectionMode)) {
      if (!node.internal && this.selectionMode !== "bridge-target") {
        this.renderStatusTarget.textContent = "Per questa operazione seleziona una stazione interna al dominio"
        return
      }
      const targets = {
        "new-node-parent": [this.newNodeParentIdTarget, this.newNodeParentButtonTarget, "Genitore"],
        "bridge-source": [this.bridgeSourceIdTarget, this.bridgeSourceButtonTarget, "Origine"],
        "bridge-target": [this.bridgeTargetIdTarget, this.bridgeTargetButtonTarget, "Destinazione"],
        "move-node": [this.moveNodeIdTarget, this.moveNodeButtonTarget, "Node"],
        "move-parent": [this.moveParentIdTarget, this.moveParentButtonTarget, "Genitore"]
      }
      const [input, button, label] = targets[this.selectionMode]
      input.value = node.nodeId
      button.textContent = `${label}: ${node.label}`
      const completedMode = this.selectionMode
      this.selectionMode = null
      this.select(node, group)
      this.structurePanelTarget.hidden = false
      if (completedMode === "bridge-source") this.startStructureSelection("bridge-target", "Ora seleziona la destinazione del ponte")
      if (completedMode === "move-node") this.startStructureSelection("move-parent", "Ora seleziona il nuovo genitore")
      return
    }
    if (this.editMode) {
      this.select(node, group)
      return
    }

    const destination = node.terminal ? node.metroUrl : node.editUrl
    if (destination) window.location.assign(destination)
    else this.select(node, group)
  }

  openLinePanel() {
    this.closePanels()
    this.linePanelTarget.hidden = false
    this.selectionMode = "line"
    this.renderStatusTarget.textContent = "Clicca le stazioni nell’ordine della nuova linea"
  }

  openOfferPanel() {
    this.closePanels()
    this.offerPanelTarget.hidden = false
    this.renderStatusTarget.textContent = "Scegli una linea, poi seleziona inizio e fine"
  }

  toggleExportPanel() {
    const shouldOpen = this.exportPanelTarget.hidden
    this.closePanels()
    this.exportPanelTarget.hidden = !shouldOpen
  }

  closePanels() {
    this.linePanelTarget.hidden = true
    this.offerPanelTarget.hidden = true
    this.exportPanelTarget.hidden = true
    this.structurePanelTarget.hidden = true
    this.selectionMode = null
    if (this.nodes) this.renderStatusTarget.textContent = `${this.nodes.size} stazioni · ${this.edges.length} binari`
  }

  openStructurePanel() {
    this.closePanels()
    this.structurePanelTarget.hidden = false
  }

  showStructureTab(event) {
    const selected = event.currentTarget.dataset.structureTab
    this.nodeTabTarget.hidden = selected !== "node"
    this.bridgeTabTarget.hidden = selected !== "bridge"
    this.parentTabTarget.hidden = selected !== "parent"
    this.structurePanelTarget.querySelectorAll("[data-structure-tab]").forEach((button) => {
      const active = button.dataset.structureTab === selected
      button.classList.toggle("bg-white", active)
      button.classList.toggle("text-slate-900", active)
      button.classList.toggle("shadow-sm", active)
      button.classList.toggle("text-slate-500", !active)
    })
  }

  selectNewNodeParent() { this.startStructureSelection("new-node-parent", "Clicca sulla mappa il genitore del nuovo Node") }
  selectBridgeSource() { this.startStructureSelection("bridge-source", "Seleziona l’origine del ponte") }
  selectBridgeTarget() { this.startStructureSelection("bridge-target", "Seleziona la destinazione del ponte") }
  selectMoveNode() { this.startStructureSelection("move-node", "Seleziona il Node da spostare") }
  selectMoveParent() { this.startStructureSelection("move-parent", "Seleziona il nuovo genitore") }

  startStructureSelection(mode, message) {
    this.selectionMode = mode
    this.structurePanelTarget.hidden = true
    this.renderStatusTarget.textContent = message
  }

  undoLineStation() {
    this.lineStationSelection.pop()
    this.updateLineSelection()
  }

  resetLineStations() {
    this.lineStationSelection = []
    this.updateLineSelection()
  }

  updateLineSelection() {
    this.lineStationIdsTarget.value = this.lineStationSelection.map((node) => node.nodeId).join(",")
    if (!this.lineStationSelection.length) {
      this.lineStationListTarget.innerHTML = '<li class="text-slate-400">Clicca almeno due stazioni sulla mappa.</li>'
      return
    }
    this.lineStationListTarget.replaceChildren(...this.lineStationSelection.map((node, index) => {
      const item = document.createElement("li")
      item.textContent = `${index + 1}. ${node.label}`
      return item
    }))
  }

  offerLineChanged() {
    const option = this.offerLineTarget.selectedOptions[0]
    this.offerStationIds = (option?.dataset.stationIds || "").split(",").filter(Boolean).map(Number)
    this.offerStartIdTarget.value = ""
    this.offerEndIdTarget.value = ""
    this.offerStartButtonTarget.textContent = "1. Seleziona inizio"
    this.offerEndButtonTarget.textContent = "2. Seleziona fine"
  }

  selectOfferStart() {
    if (!this.ensureOfferLine()) return
    this.selectionMode = "offer-start"
    this.renderStatusTarget.textContent = "Clicca la stazione iniziale dell’offerta"
  }

  selectOfferEnd() {
    if (!this.ensureOfferLine()) return
    this.selectionMode = "offer-end"
    this.renderStatusTarget.textContent = "Clicca la stazione finale dell’offerta"
  }

  ensureOfferLine() {
    if (this.offerLineTarget.value && this.offerStationIds?.length) return true
    this.renderStatusTarget.textContent = "Prima scegli una linea"
    return false
  }

  purchaseModeChanged(event) {
    this.discountPercentTarget.disabled = event.currentTarget.value !== "discount"
    if (this.discountPercentTarget.disabled) this.discountPercentTarget.value = ""
  }

  select(node, group) {
    this.selectedNode = node
    this.detailsPanelTarget.hidden = false
    this.svg.querySelectorAll(".station-outline").forEach((outline) => outline.setAttribute("stroke", "#e2e8f0"))
    group.querySelector(".station-outline")?.setAttribute("stroke", "#0f172a")
    this.emptyTarget.hidden = true
    this.titleTarget.textContent = node.label
    const location = node.internal ? this.graphValue.domain : (node.destinationDomain || node.domains?.join(", ") || "Altro dominio")
    const type = node.terminal ? "Uscita verso un altro progetto" : (node.nodeType === "professional" ? "Professional" : "Project")
    this.metaTarget.textContent = `${type} · ${location}`
    this.openLinkTarget.href = node.url
    this.openLinkTarget.hidden = false
    this.openMetroLinkTarget.href = node.metroUrl || "#"
    this.openMetroLinkTarget.hidden = !node.metroUrl
    this.editNodeLinkTarget.href = node.editUrl
    this.editNodeLinkTarget.hidden = !this.editMode
  }
}
