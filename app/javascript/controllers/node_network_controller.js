import { Controller } from "@hotwired/stimulus"
import cytoscape from "cytoscape"
import { buildRadialSupportTree, calculateRadialSectorLayout } from "radial_sector_layout"

export default class extends Controller {
  static targets = ["stage", "canvas", "orbitOverlay", "drawer", "panelButton", "breadcrumb", "title", "type", "description", "domains", "relation", "empty", "search", "openLink", "addLink", "deleteLink", "fullscreenButton", "modeButton", "centerModeLink", "depthRange", "depthLabel", "nodeLimitNotice", "expandNodesButton"]
  static values = { graph: Object, selected: String, mode: { type: String, default: "brand" }, automaticCenter: Boolean, fixedCenter: Boolean }

  connect() {
    this.drawerOpen = true
    this.visibleDepth = this.automaticCenterValue ? 2 : 3
    this.visibleNodeLimit = 40
    this.fullscreenChangeHandler = () => this.updateFullscreenButton()
    document.addEventListener("fullscreenchange", this.fullscreenChangeHandler)

    this.cy = cytoscape({
      container: this.canvasTarget,
      elements: this.graphValue.elements,
      layout: this.layoutOptions(),
      minZoom: 0.25,
      maxZoom: 2,
      wheelSensitivity: 0.18,
      style: this.styles()
    })

    this.cy.on("tap", "node", (event) => this.select(event.target.data("canonicalId") || event.target.id(), true))
    this.orbitViewportHandler = () => this.scheduleOrbitRender()
    this.cy.on("pan zoom resize", this.orbitViewportHandler)
    this.applyMode(this.modeValue, false)
    this.updateDepthControls()
    const initialId = this.automaticCenterValue && !this.fixedCenterValue
      ? this.automaticCenterId()
      : this.selectedValue || this.graphValue.elements.find((element) => element.data.kind === "node")?.data.id
    this.select(initialId, false)
    window.requestAnimationFrame(() => {
      this.cy.resize()
      const selected = this.cy.$("node.selected")
      this.fitWithZoomLimit(selected.length ? this.contextFor(selected) : this.cy.elements(), 72)
    })
  }

  disconnect() {
    document.removeEventListener("fullscreenchange", this.fullscreenChangeHandler)
    if (this.depthLabelTimer) window.clearTimeout(this.depthLabelTimer)
    this.cy?.off("pan zoom resize", this.orbitViewportHandler)
    if (this.orbitFrame) window.cancelAnimationFrame(this.orbitFrame)
    this.cy?.destroy()
  }

  showAll() {
    const visible = this.cy.elements().not(".mode-hidden")
    visible.removeClass("faded selected incoming outgoing")
    this.cy.fit(visible, 48)
    this.clearDetails()

    const url = new URL(window.location.href)
    url.searchParams.delete("node")
    history.replaceState({}, "", url)
  }

  changeMode(event) {
    this.applyMode(event.currentTarget.dataset.mode, true)
  }

  applyMode(mode, updateUrl) {
    this.modeValue = mode

    this.cy.nodes().forEach((node) => {
      const modes = node.data("modes") || []
      node.toggleClass("mode-hidden", !modes.includes(mode))
    })
    this.cy.edges().forEach((edge) => {
      edge.toggleClass("mode-hidden", edge.source().hasClass("mode-hidden") || edge.target().hasClass("mode-hidden"))
    })

    this.modeButtonTargets.forEach((button) => {
      const active = button.dataset.mode === mode
      button.setAttribute("aria-pressed", active.toString())
      button.style.backgroundColor = active ? "#2563eb" : "transparent"
      button.style.color = active ? "#ffffff" : "#475569"
    })

    const selected = this.cy.$("node.selected").not(".mode-hidden")
    const visible = this.cy.elements().not(".mode-hidden")
    visible.removeClass("faded")
    if (selected.length) {
      this.arrangeRadial(selected.first(), false)
    } else {
      this.cy.layout(this.layoutOptions()).run()
      this.cy.fit(visible, 60)
    }
    if (!selected.length) this.clearDetails()

    if (updateUrl) {
      const url = new URL(window.location.href)
      url.searchParams.set("vista", mode)
      history.replaceState({}, "", url)
    }
  }

  recenter() {
    const selected = this.cy.$("node.selected")
    if (selected.length) this.cy.animate({ center: { eles: selected }, zoom: 1.05 }, { duration: 250 })
  }

  zoomIn() {
    this.cy.animate({ zoom: Math.min(this.cy.zoom() * 1.2, this.cy.maxZoom()), center: { eles: this.cy.$("node.selected") } }, { duration: 160 })
  }

  zoomOut() {
    this.cy.animate({ zoom: Math.max(this.cy.zoom() / 1.2, this.cy.minZoom()) }, { duration: 160 })
  }

  setDepthFromRange(event) {
    const value = Number(event.currentTarget.value)
    this.visibleDepth = value === 6 ? Number.POSITIVE_INFINITY : value
    this.visibleNodeLimit = 40
    this.updateDepthControls()
    this.showDepthLabel()
    const selected = this.cy.$("node.selected")
    if (selected.length) this.arrangeRadial(selected.first(), true)
  }

  expandNodeLimit() {
    this.visibleNodeLimit += 20
    const selected = this.cy.$("node.selected")
    if (selected.length) this.arrangeRadial(selected.first(), true)
  }

  updateDepthControls() {
    const rangeValue = Number.isFinite(this.visibleDepth) ? this.visibleDepth : 6
    const label = rangeValue === 6 ? "Tutti i livelli" : `${rangeValue} ${rangeValue === 1 ? "livello" : "livelli"}`
    this.depthRangeTarget.value = rangeValue
    this.depthRangeTarget.setAttribute("aria-valuetext", label)
    this.depthLabelTarget.textContent = rangeValue === 6 ? "Tutti" : rangeValue
  }

  showDepthLabel() {
    if (this.depthLabelTimer) window.clearTimeout(this.depthLabelTimer)
    this.depthLabelTarget.classList.remove("opacity-0")
    this.depthLabelTimer = window.setTimeout(() => {
      this.depthLabelTarget.classList.add("opacity-0")
    }, 900)
  }

  fitWithZoomLimit(elements, padding) {
    const viewport = this.viewportFor(elements, padding)
    this.cy.viewport(viewport)
  }

  viewportFor(elements, padding) {
    const bounds = elements.boundingBox()
    const drawerWidth = this.drawerOpen ? this.drawerTarget.getBoundingClientRect().width : 0
    const availableWidth = Math.max(1, this.cy.width() - drawerWidth)
    const availableHeight = Math.max(1, this.cy.height())
    const widthZoom = (availableWidth - padding * 2) / Math.max(1, bounds.w)
    const heightZoom = (availableHeight - padding * 2) / Math.max(1, bounds.h)
    const sparseAllLimit = !this.automaticCenterValue && elements.nodes().length <= 6 ? 0.9 : this.cy.maxZoom()
    const zoom = Math.max(this.cy.minZoom(), Math.min(widthZoom, heightZoom, sparseAllLimit, this.cy.maxZoom()))

    return {
      zoom,
      pan: {
        x: drawerWidth + availableWidth / 2 - bounds.x1 * zoom - bounds.w * zoom / 2,
        y: availableHeight / 2 - bounds.y1 * zoom - bounds.h * zoom / 2
      }
    }
  }

  async toggleFullscreen() {
    if (document.fullscreenElement === this.stageTarget) {
      await document.exitFullscreen()
    } else {
      await this.stageTarget.requestFullscreen()
    }
  }

  updateFullscreenButton() {
    const active = document.fullscreenElement === this.stageTarget
    this.stageTarget.style.height = "100vh"
    this.fullscreenButtonTarget.textContent = active ? "↙" : "⛶"
    this.fullscreenButtonTarget.setAttribute("aria-label", active ? "Esci dallo schermo intero" : "Visualizza a schermo intero")
    this.fullscreenButtonTarget.title = active ? "Esci dallo schermo intero" : "Schermo intero"
    window.setTimeout(() => {
      this.cy?.resize()
      const selected = this.cy?.$("node.selected")
      this.fitWithZoomLimit(selected?.length ? this.contextFor(selected) : this.cy.elements(), 72)
    }, 0)
  }

  search(event) {
    if (event.type === "keydown" && event.key !== "Enter") return

    const query = this.searchTarget.value.trim().toLocaleLowerCase("it")
    if (!query) return

    const match = this.cy.nodes().filter((node) => {
      const label = node.data("label").toLocaleLowerCase("it")
      const slug = node.data("slug").toLocaleLowerCase("it")
      return !node.hasClass("mode-hidden") && (label === query || slug === query || label.includes(query))
    }).first()

    if (match.length) {
      this.select(match.id(), true)
      this.searchTarget.value = ""
      this.searchTarget.blur()
    }
  }

  closeDetails() {
    this.drawerOpen = false
    this.drawerTarget.style.transform = "translateX(calc(-100% - 2rem))"
    this.panelButtonTarget.setAttribute("aria-expanded", "false")
    this.reframeCurrentView()
  }

  togglePanel() {
    this.drawerOpen = !this.drawerOpen
    this.drawerTarget.style.transform = this.drawerOpen ? "translateX(0)" : "translateX(calc(-100% - 2rem))"
    this.panelButtonTarget.setAttribute("aria-expanded", this.drawerOpen.toString())
    this.reframeCurrentView()
  }

  reframeCurrentView() {
    const selected = this.cy.$("node.selected")
    const elements = selected.length ? this.contextFor(selected) : this.cy.elements().not(".mode-hidden")
    this.cy.animate(this.viewportFor(elements, 80), { duration: 220, easing: "ease-in-out-cubic" })
  }

  select(id, updateUrl) {
    const selected = this.cy.getElementById(id)
    if (!selected.length || selected.data("kind") !== "node" || selected.hasClass("mode-hidden")) return

    const neighborhood = this.contextFor(selected)
    this.updateDomainMembership(selected)
    const directNodes = selected.neighborhood("node").not(".mode-hidden")
    this.cy.elements().addClass("context-hidden").removeClass("faded selected incoming outgoing secondary")
    neighborhood.removeClass("context-hidden")
    selected.addClass("selected")
    neighborhood.nodes().not(selected).not(directNodes).addClass("secondary")

    selected.incomers("node").addClass("incoming")
    selected.outgoers("node").addClass("outgoing")
    selected.connectedEdges().removeClass("faded")

    this.renderDetails(selected)
    this.renderBreadcrumb(selected)
    this.updateCenterModeLink(selected)
    this.drawerOpen = true
    this.drawerTarget.style.transform = "translateX(0)"
    this.panelButtonTarget.setAttribute("aria-expanded", "true")
    this.arrangeRadial(selected, true)

    if (updateUrl) {
      const url = new URL(window.location.href)
      url.searchParams.set("node", selected.data("slug"))
      history.replaceState({}, "", url)
    }
  }

  renderBreadcrumb(selected) {
    if (!this.hasBreadcrumbTarget) return

    const path = [selected]
    const visited = new Set([selected.id()])
    let current = selected
    while (current.length) {
      const parentEdge = current.connectedEdges().intersection(this.hierarchyEdges())
        .filter((edge) => edge.target().id() === current.id())
        .sort((a, b) => this.compareNodes(a.source(), b.source())).first()
      if (!parentEdge.length) break
      const parent = parentEdge.source()
      if (visited.has(parent.id())) break
      visited.add(parent.id())
      path.unshift(parent)
      current = parent
    }

    this.breadcrumbTarget.replaceChildren()
    path.forEach((node, index) => {
      const stationWrapper = document.createElement("span")
      stationWrapper.className = "relative w-28 shrink-0"
      if (index < path.length - 1) {
        const rail = document.createElement("span")
        rail.className = "absolute left-1/2 top-2 h-1 w-full bg-slate-300"
        rail.setAttribute("aria-hidden", "true")
        stationWrapper.append(rail)
      }

      const station = document.createElement("button")
      const active = index === path.length - 1
      station.type = "button"
      station.className = "group relative z-10 flex w-full flex-col items-center gap-1 text-center"
      station.disabled = active
      station.title = active ? node.data("label") : `Torna a ${node.data("label")}`
      station.setAttribute("aria-current", active ? "page" : "false")
      station.addEventListener("click", () => this.select(node.id(), true))

      const dot = document.createElement("span")
      dot.className = active
        ? "size-5 rounded-full border-4 border-violet-200 bg-violet-700 shadow-sm"
        : "size-5 rounded-full border-4 border-slate-200 bg-white transition group-hover:border-blue-200 group-hover:bg-blue-600"
      const label = document.createElement("span")
      label.className = active
        ? "max-w-32 truncate text-[9px] font-black text-violet-800"
        : "max-w-32 truncate text-[9px] font-bold text-slate-500 group-hover:text-blue-700"
      label.textContent = node.data("label")
      station.append(dot, label)
      stationWrapper.append(station)
      this.breadcrumbTarget.append(stationWrapper)
    })
    this.breadcrumbTarget.scrollLeft = this.breadcrumbTarget.scrollWidth
  }

  updateDomainMembership(selected) {
    this.cy.nodes().removeClass("external-domain")
    if (!this.automaticCenterValue) {
      return
    }

    const focusDomain = selected.data("domainKey")
    this.cy.nodes().forEach((node) => {
      const nodeDomain = node.data("domainKey")
      if (focusDomain && node.id() !== selected.id() && nodeDomain !== focusDomain) {
        node.addClass("external-domain")
      }
    })
  }

  renderDetails(node) {
    const data = node.data()
    this.emptyTarget.hidden = true
    this.titleTarget.textContent = data.label
    this.typeTarget.textContent = data.nodeTypeLabel
    this.descriptionTarget.textContent = data.description || "Nessuna descrizione inserita."
    this.domainsTarget.replaceChildren()

    if (data.domains.length) {
      data.domains.forEach((domain) => {
        const item = document.createElement("li")
        item.textContent = domain
        this.domainsTarget.append(item)
      })
    } else {
      const item = document.createElement("li")
      item.textContent = "Nessun dominio associato"
      item.className = "text-slate-400"
      this.domainsTarget.append(item)
    }

    const incoming = node.incomers("node").length
    const outgoing = node.outgoers("node").length
    this.relationTarget.textContent = `${incoming} ingressi · ${outgoing} uscite`
    this.openLinkTarget.href = data.url
    this.addLinkTarget.hidden = !data.canManage || !data.newChildUrl
    this.addLinkTarget.href = data.newChildUrl || "#"
    this.deleteLinkTarget.hidden = !data.canDelete
    this.deleteLinkTarget.href = data.deleteUrl || "#"
    this.deleteLinkTarget.dataset.turboConfirm = `Eliminare definitivamente il Node “${data.label}”? Questa operazione non può essere annullata.`
  }

  updateCenterModeLink(node) {
    if (!this.hasCenterModeLinkTarget) return

    const url = new URL(this.centerModeLinkTarget.href, window.location.origin)
    url.searchParams.set("node", node.data("slug"))
    this.centerModeLinkTarget.href = `${url.pathname}${url.search}`
  }

  clearDetails() {
    this.emptyTarget.hidden = false
    this.titleTarget.textContent = "Tutta la rete"
    this.typeTarget.textContent = "FlowPulse"
    this.descriptionTarget.textContent = "Seleziona un Node per vedere domini e collegamenti diretti."
    this.domainsTarget.replaceChildren()
    this.relationTarget.textContent = ""
    this.addLinkTarget.hidden = true
    this.deleteLinkTarget.hidden = true
    this.drawerOpen = false
    this.drawerTarget.style.transform = "translateX(calc(-100% - 2rem))"
    this.panelButtonTarget.setAttribute("aria-expanded", "false")
  }

  layoutOptions(focusNode = null) {
    return {
      name: "breadthfirst",
      directed: true,
      spacingFactor: 1.25,
      padding: 48,
      animate: false
    }
  }

  arrangeRadial(selected, animate) {
    if (!selected?.length) return

    this.clearBridgeAliases()
    const fullContext = this.rawContextFor(selected)
    let neighborhood = this.limitContextFor(selected, fullContext)
    neighborhood = this.addBridgeAliases(selected, neighborhood)
    const positions = this.radialPositions(selected, neighborhood.nodes())
    if (this.radialExcludedIds?.size) {
      const layoutNodes = neighborhood.nodes().filter((node) => !this.radialExcludedIds.has(node.id()))
      const layoutEdges = neighborhood.edges().filter((edge) => (
        layoutNodes.contains(edge.source()) && layoutNodes.contains(edge.target())
      ))
      neighborhood = layoutNodes.union(layoutEdges)
    }
    this.cy.elements().addClass("context-hidden")
    neighborhood.removeClass("context-hidden")
    selected.removeClass("context-hidden").addClass("selected")
    if (Number.isFinite(this.visibleDepth)) {
      this.currentRingRadii = this.currentRingRadii.filter(([ring]) => ring <= this.visibleDepth)
    }
    const layout = neighborhood.layout({
      name: "preset",
      positions: (node) => positions[node.id()] || { x: 0, y: 0 },
      animate,
      animationDuration: animate ? 420 : 0,
      animationEasing: "ease-in-out-cubic",
      fit: false,
      padding: 80
    })

    layout.one("layoutstop", () => {
      const viewport = this.viewportFor(neighborhood, 80)
      this.cy.animate(
        viewport,
        {
          duration: animate ? 260 : 0,
          easing: "ease-in-out-cubic"
        }
      )
      this.scheduleOrbitRender()
    })
    layout.run()
  }

  clearBridgeAliases() {
    this.cy.edges().removeClass("alias-replaced")
    const aliases = this.cy.elements("[layoutAlias]")
    if (aliases.length) this.cy.remove(aliases)
  }

  addBridgeAliases(selected, neighborhood) {
    if (!this.automaticCenterValue) return neighborhood

    const visibleNodes = neighborhood.nodes()
    const hierarchyEdges = neighborhood.edges().intersection(this.hierarchyEdges())
    let reachable = selected
    let frontier = selected
    while (frontier.length) {
      frontier = frontier.connectedEdges().intersection(hierarchyEdges).connectedNodes()
        .intersection(visibleNodes).not(reachable)
      reachable = reachable.union(frontier)
    }

    let result = neighborhood
    this.contextualEdgesFor(selected).forEach((edge) => {
      const canonical = edge.connectedNodes().not(selected).intersection(visibleNodes).first()
      if (!canonical.length || !reachable.contains(canonical)) return

      const aliasId = `layout-alias-${selected.id()}-${canonical.id()}`
      const aliasEdgeId = `layout-alias-edge-${edge.id()}`
      const alias = this.cy.add({
        group: "nodes",
        data: {
          ...canonical.data(),
          id: aliasId,
          canonicalId: canonical.id(),
          layoutAlias: true
        },
        classes: "bridge-alias"
      })
      const sourceId = edge.source().id() === selected.id() ? selected.id() : aliasId
      const targetId = edge.target().id() === selected.id() ? selected.id() : aliasId
      const aliasEdge = this.cy.add({
        group: "edges",
        data: {
          ...edge.data(),
          id: aliasEdgeId,
          source: sourceId,
          target: targetId,
          layoutAlias: true
        }
      })
      edge.addClass("alias-replaced")
      result = result.not(edge).union(alias).union(aliasEdge)
    })
    return result
  }

  radialPositions(selected, nodes) {
    const focusId = selected.id()
    const hierarchyEdges = this.hierarchyEdges()
    const contextualEdges = this.automaticCenterValue ? this.contextualEdgesFor(selected) : this.cy.collection()
    const nodesById = new Map(nodes.map((node) => [node.id(), node]))
    const compareForLayout = (a, b) => {
      const aPosition = a.data("position")
      const bPosition = b.data("position")
      if (Number.isFinite(aPosition) || Number.isFinite(bPosition)) {
        const positionDifference = (Number.isFinite(aPosition) ? aPosition : Number.MAX_SAFE_INTEGER) -
          (Number.isFinite(bPosition) ? bPosition : Number.MAX_SAFE_INTEGER)
        if (positionDifference !== 0) return positionDifference
      }
      const domainDifference = (a.data("domainKey") || "~").localeCompare(b.data("domainKey") || "~", "it")
      return domainDifference || this.compareNodes(a, b)
    }
    const edgeData = (edge) => ({ id: edge.id(), source: edge.source().id(), target: edge.target().id() })
    const nodeIds = nodes.map((node) => node.id())
    const tree = buildRadialSupportTree({
      focusId,
      nodeIds,
      hierarchyEdges: hierarchyEdges.map(edgeData),
      contextualEdges: contextualEdges.map(edgeData),
      directedHierarchy: this.automaticCenterValue,
      terminalRootParents: this.automaticCenterValue,
      compareNodeIds: (a, b) => compareForLayout(nodesById.get(a), nodesById.get(b))
    })
    const { childrenById, depthById, ringNodeIds, supportEdgeByChild, supportEdgeIds, excludedNodeIds } = tree
    this.radialExcludedIds = new Set(excludedNodeIds)
    const layoutNodeIds = nodeIds.filter((nodeId) => !this.radialExcludedIds.has(nodeId))
    const layoutNodes = nodes.filter((node) => !this.radialExcludedIds.has(node.id()))
    const contextualEdgeIds = new Set(contextualEdges.map((edge) => edge.id()))
    this.cy.nodes().removeClass("first-ring-reference")
    ;(childrenById.get(focusId) || []).forEach((childId) => {
      const supportEdge = supportEdgeByChild.get(childId)
      if (!supportEdge) return
      const isContextual = contextualEdgeIds.has(supportEdge.id)
      const isDirectParent = supportEdge.target === focusId
      if (isContextual || isDirectParent) nodesById.get(childId)?.addClass("first-ring-reference")
    })
    const visibleEdges = this.cy.edges().filter((edge) => (
      layoutNodes.contains(edge.source()) && layoutNodes.contains(edge.target())
    ))
    const supportEdges = this.cy.edges().filter((edge) => supportEdgeIds.has(edge.id()))
    this.cy.edges().removeClass("cross-link layout-support")
    supportEdges.addClass("layout-support")
    visibleEdges.not(supportEdges).addClass("cross-link")
    const continuationById = {}
    this.cy.nodes().removeClass("course-chapter")
    childrenById.forEach((childIds, parentId) => {
      const courseChildren = childIds.filter((childId) => nodesById.get(childId)?.data("viewType") === "course")
      if (courseChildren.length === 1) continuationById[parentId] = courseChildren[0]
      if (nodesById.get(parentId)?.data("viewType") === "course") {
        childIds.filter((childId) => childId !== courseChildren[0]).forEach((childId) => {
          nodesById.get(childId)?.addClass("course-chapter")
        })
      }
    })

    const dimensionsFor = (ring) => {
      if (ring === 0) return { width: 210, height: 70 }
      if (ring === 1) return { width: 184, height: 62 }
      return { width: 166, height: 56 }
    }
    const nodeDimensionsById = {}
    const groupById = {}
    layoutNodes.forEach((node) => {
      const ring = depthById.get(node.id()) || 0
      const fallback = dimensionsFor(ring)
      const externalPadding = node.hasClass("external-domain") ? 12 : 0
      nodeDimensionsById[node.id()] = {
        width: (Number.parseFloat(node.style("width")) || fallback.width) + externalPadding,
        height: (Number.parseFloat(node.style("height")) || fallback.height) + externalPadding
      }
      groupById[node.id()] = node.data("domainKey") || null
    })
    const rootDirections = {}
    ;(childrenById.get(focusId) || []).forEach((childId) => {
      const connectingEdge = supportEdgeByChild.get(childId)
      rootDirections[childId] = connectingEdge && connectingEdge.source === focusId
        ? "outgoing"
        : "incoming"
    })
    const result = calculateRadialSectorLayout({
      focusId,
      nodeIds: layoutNodeIds,
      childrenById,
      depthById,
      ringNodeIds,
      rootDirections,
      continuationById,
      dimensionsByRing: dimensionsFor,
      nodeDimensionsById,
      groupById
    })
    const { positions, radii } = result
    this.radialDiagnostics = result.diagnostics
    if (new URL(window.location.href).searchParams.get("layout_debug") === "1") {
      console.debug("FlowPulse radial layout", result.diagnostics)
    }
    this.currentRingRadii = [...radii.entries()].filter(([ring]) => ring > 0)
    return positions
  }

  scheduleOrbitRender() {
    if (this.orbitFrame) return
    this.orbitFrame = window.requestAnimationFrame(() => {
      this.orbitFrame = null
      this.renderOrbitLayers()
    })
  }

  renderOrbitLayers() {
    if (!this.hasOrbitOverlayTarget) return

    const selected = this.cy.$("node.selected").first()
    const rings = this.currentRingRadii || []
    this.orbitOverlayTarget.replaceChildren()
    const namespace = "http://www.w3.org/2000/svg"
    if (!this.automaticCenterValue) this.renderDomainFences(namespace)
    if (!selected.length || !rings.length) return

    const center = selected.renderedPosition()
    const zoom = this.cy.zoom()
    rings.forEach(([level, radius]) => {
      const circle = document.createElementNS(namespace, "circle")
      circle.setAttribute("cx", center.x)
      circle.setAttribute("cy", center.y)
      circle.setAttribute("r", radius * zoom)
      circle.setAttribute("fill", "none")
      circle.setAttribute("stroke", level === 1 ? "#93c5fd" : "#cbd5e1")
      circle.setAttribute("stroke-width", level === 1 ? "1.5" : "1")
      circle.setAttribute("stroke-dasharray", level === 1 ? "6 6" : "3 7")
      circle.setAttribute("opacity", level === 1 ? "0.65" : "0.5")
      this.orbitOverlayTarget.append(circle)
    })
  }

  renderDomainFences(namespace) {
    const groups = new Map()
    this.cy.nodes().not(".mode-hidden").not(".context-hidden").forEach((node) => {
      const key = node.data("domainKey")
      if (!key) return
      if (!groups.has(key)) groups.set(key, [])
      groups.get(key).push(node)
    })

    groups.forEach((nodes) => {
      if (nodes.length < 2) return

      const padding = 14
      const points = nodes.flatMap((node) => {
        const box = node.renderedBoundingBox({ includeLabels: true, includeOverlays: false })
        return [
          { x: box.x1 - padding, y: box.y1 - padding },
          { x: box.x2 + padding, y: box.y1 - padding },
          { x: box.x2 + padding, y: box.y2 + padding },
          { x: box.x1 - padding, y: box.y2 + padding }
        ]
      })
      const hull = this.convexHull(points)
      if (hull.length < 3) return

      const color = nodes[0].data("domainColor") || "#64748B"
      const path = document.createElementNS(namespace, "path")
      path.setAttribute("d", `${hull.map((point, index) => `${index ? "L" : "M"} ${point.x} ${point.y}`).join(" ")} Z`)
      path.setAttribute("fill", color)
      path.setAttribute("fill-opacity", "0.045")
      path.setAttribute("stroke", color)
      path.setAttribute("stroke-width", "1.5")
      path.setAttribute("stroke-linejoin", "round")
      path.setAttribute("opacity", "0.68")
      this.orbitOverlayTarget.append(path)

      const top = hull.reduce((best, point) => point.y < best.y ? point : best, hull[0])
      const label = document.createElementNS(namespace, "text")
      label.setAttribute("x", top.x)
      label.setAttribute("y", top.y - 8)
      label.setAttribute("fill", color)
      label.setAttribute("font-size", "11")
      label.setAttribute("font-weight", "800")
      label.setAttribute("paint-order", "stroke")
      label.setAttribute("stroke", "#ffffff")
      label.setAttribute("stroke-width", "4")
      label.setAttribute("stroke-linejoin", "round")
      label.textContent = nodes[0].data("domainLabel")
      this.orbitOverlayTarget.append(label)
    })
  }

  convexHull(points) {
    const sorted = [...points].sort((a, b) => a.x - b.x || a.y - b.y)
    const cross = (origin, a, b) => (a.x - origin.x) * (b.y - origin.y) - (a.y - origin.y) * (b.x - origin.x)
    const half = (items) => {
      const result = []
      items.forEach((point) => {
        while (result.length >= 2 && cross(result[result.length - 2], result[result.length - 1], point) <= 0) result.pop()
        result.push(point)
      })
      return result
    }
    const lower = half(sorted)
    const upper = half([...sorted].reverse())
    lower.pop()
    upper.pop()
    return lower.concat(upper)
  }

  contextFor(selected) {
    return this.limitContextFor(selected, this.rawContextFor(selected))
  }

  limitContextFor(selected, context) {
    const contextNodes = context.nodes().not(".mode-hidden")
    const contextEdges = context.edges().not(".mode-hidden")
    const visibleIds = new Set([selected.id()])
    const queue = [{ node: selected, depth: 0 }]

    while (queue.length && visibleIds.size < this.visibleNodeLimit) {
      const { node, depth } = queue.shift()
      if (depth >= this.visibleDepth) continue

      const neighbors = node.connectedEdges().intersection(contextEdges).connectedNodes()
        .intersection(contextNodes)
        .filter((neighbor) => !visibleIds.has(neighbor.id()))
        .sort((a, b) => this.compareNodes(a, b))

      neighbors.forEach((neighbor) => {
        if (visibleIds.size >= this.visibleNodeLimit) return
        visibleIds.add(neighbor.id())
        queue.push({ node: neighbor, depth: depth + 1 })
      })
    }

    const visibleNodes = contextNodes.filter((node) => visibleIds.has(node.id()))
    const visibleEdges = contextEdges.filter((edge) => (
      visibleIds.has(edge.source().id()) && visibleIds.has(edge.target().id())
    ))
    const omitted = contextNodes.length - visibleNodes.length
    if (this.hasNodeLimitNoticeTarget) {
      this.nodeLimitNoticeTarget.hidden = omitted <= 0
      this.nodeLimitNoticeTarget.textContent = omitted > 0 ? `+ ${omitted} Node non visibili` : ""
      this.expandNodesButtonTarget.hidden = omitted <= 0 || visibleNodes.length < this.visibleNodeLimit
    }
    return visibleNodes.union(visibleEdges)
  }

  rawContextFor(selected) {
    if (this.automaticCenterValue) return this.automaticContextFor(selected)

    let nodes = selected
    let frontier = selected
    const hierarchyEdges = this.hierarchyEdges()

    while (frontier.length) {
      frontier = frontier.connectedEdges().intersection(hierarchyEdges).connectedNodes().not(".mode-hidden").not(nodes)
      nodes = nodes.union(frontier)
    }

    const contextualEdges = this.modeValue === "professional"
      ? selected.connectedEdges("edge[kind = 'professional-owner']").not(".mode-hidden")
      : this.cy.collection()
    nodes = nodes.union(contextualEdges.connectedNodes())
    const edges = hierarchyEdges.filter((edge) => (
      nodes.contains(edge.source()) && nodes.contains(edge.target())
    )).union(contextualEdges)
    return nodes.union(edges).not(".mode-hidden")
  }

  automaticContextFor(selected) {
    const hierarchyEdges = this.hierarchyEdges()
    let nodes = selected
    let descendants = selected
    let hierarchyDepth = 0
    const stopAtBrandBoundary = selected.data("hasDomain") === true

    while (descendants.length) {
      const outgoingEdges = descendants.connectedEdges().intersection(hierarchyEdges)
        .filter((edge) => descendants.contains(edge.source()))
      const children = outgoingEdges.targets().not(".mode-hidden").not(nodes)
      const visibleChildren = stopAtBrandBoundary && hierarchyDepth > 0
        ? children.filter((node) => node.data("hasDomain") !== true)
        : children
      nodes = nodes.union(visibleChildren)
      descendants = stopAtBrandBoundary
        ? visibleChildren.filter((node) => node.data("hasDomain") !== true)
        : visibleChildren
      hierarchyDepth += 1
    }

    // The immediate hierarchy parent explains where the centered node comes
    // from. Keep it on the first ring without walking further up the ancestry.
    const incomingHierarchyEdges = selected.connectedEdges().intersection(hierarchyEdges)
      .filter((edge) => edge.target().id() === selected.id())
    nodes = nodes.union(incomingHierarchyEdges.sources().not(".mode-hidden"))

    const siteNodes = nodes
    const contextualEdges = this.contextualEdgesFor(selected)
    nodes = nodes.union(contextualEdges.connectedNodes())
    const edges = hierarchyEdges.filter((edge) => (
      siteNodes.contains(edge.source()) &&
      siteNodes.contains(edge.target())
    )).union(incomingHierarchyEdges).union(contextualEdges)
    return nodes.union(edges).not(".mode-hidden")
  }

  hierarchyEdges() {
    return this.cy.edges("edge[kind = 'hierarchy'], edge[kind = 'ecosystem']").not(".mode-hidden")
  }

  contextualEdgesFor(selected) {
    const selector = this.modeValue === "professional"
      ? "edge[kind = 'bridge'], edge[kind = 'professional-owner']"
      : "edge[kind = 'bridge']"
    return selected.connectedEdges(selector).not(".mode-hidden").not(".alias-replaced").filter((edge) => {
      if (edge.data("kind") !== "bridge") return true

      const visibility = edge.data("bridgeVisibility") || "both"
      if (visibility === "source") return edge.source().id() === selected.id()
      if (visibility === "target") return edge.target().id() === selected.id()
      return true
    })
  }

  automaticCenterId() {
    const nodes = this.cy.nodes().not(".mode-hidden")
    const edges = this.hierarchyEdges()
    let best = null

    nodes.forEach((candidate) => {
      const distances = new Map([[candidate.id(), 0]])
      const queue = [candidate]
      while (queue.length) {
        const current = queue.shift()
        current.connectedEdges().intersection(edges).connectedNodes().not(".mode-hidden").forEach((neighbor) => {
          if (distances.has(neighbor.id())) return
          distances.set(neighbor.id(), distances.get(current.id()) + 1)
          queue.push(neighbor)
        })
      }

      const distanceSum = [...distances.values()].reduce((sum, value) => sum + value, 0)
      const reachable = distances.size - 1
      const score = distanceSum ? (reachable * reachable) / distanceSum : 0
      const degree = candidate.connectedEdges().intersection(edges).length
      const result = { node: candidate, score, degree }
      if (!best || result.score > best.score || (result.score === best.score && result.degree > best.degree) ||
          (result.score === best.score && result.degree === best.degree && this.compareNodes(result.node, best.node) < 0)) {
        best = result
      }
    })

    return best?.node.id()
  }

  compareNodes(a, b) {
    const positionDifference = (a.data("position") || Number.MAX_SAFE_INTEGER) - (b.data("position") || Number.MAX_SAFE_INTEGER)
    if (positionDifference !== 0) return positionDifference
    const labelDifference = a.data("label").localeCompare(b.data("label"), "it")
    return labelDifference || a.id().localeCompare(b.id())
  }

  styles() {
    return [
      {
        selector: "node[kind = 'node']",
        style: {
          "background-color": "#ffffff",
          "border-color": "#2563eb",
          "border-style": "solid",
          "border-width": 2,
          "color": "#172033",
          "font-size": 12,
          "font-weight": 700,
          "label": "data(label)",
          "shape": "round-rectangle",
          "text-halign": "center",
          "text-valign": "center",
          "text-wrap": "wrap",
          "text-max-width": 150,
          "width": 184,
          "height": 62,
          "underlay-opacity": 0
        }
      },
      {
        selector: "node[hasDomain]",
        style: { "background-color": "#eef5ff", "border-width": 2 }
      },
      {
        selector: "node[hasMapColor]",
        style: {
          "background-color": "data(mapBackground)",
          "border-color": "data(mapColor)",
          "color": "data(mapTextColor)"
        }
      },
      {
        selector: "edge",
        style: {
          "curve-style": "bezier",
          "line-color": "#a8b4c5",
          "target-arrow-color": "#a8b4c5",
          "target-arrow-shape": "triangle",
          "arrow-scale": 0.8,
          "width": 3
        }
      },
      {
        selector: "edge[kind = 'bridge']",
        style: {
          "curve-style": "unbundled-bezier",
          "control-point-distances": 34,
          "control-point-weights": 0.5,
          "line-style": "dashed",
          "line-color": "#7c3aed",
          "target-arrow-color": "#7c3aed"
        }
      },
      {
        selector: "edge[kind = 'ecosystem']",
        style: { "line-color": "#2563eb", "target-arrow-color": "#2563eb", "width": 4 }
      },
      {
        selector: "edge[kind = 'professional-owner']",
        style: { "curve-style": "bezier", "line-style": "dotted", "line-color": "#0f9f6e", "target-arrow-color": "#0f9f6e", "width": 3 }
      },
      {
        selector: "edge.cross-link",
        style: {
          "curve-style": "unbundled-bezier",
          "control-point-distances": 46,
          "control-point-weights": 0.5,
          "line-style": "dashed",
          "opacity": 0.58,
          "width": 2
        }
      },
      {
        selector: ".selected",
        style: { "background-color": "#2563eb", "border-color": "#1d4ed8", "border-width": 5, "color": "#ffffff", "width": 210, "height": 70 }
      },
      {
        selector: "node.selected[hasMapColor]",
        style: { "background-color": "data(mapColor)", "border-color": "data(mapColor)", "color": "data(mapSelectedTextColor)" }
      },
      {
        selector: "node.external-domain",
        style: {
          "border-style": "dashed",
          "border-width": 5,
          "underlay-color": "#ffffff",
          "underlay-opacity": 0.9,
          "underlay-padding": 6
        }
      },
      {
        selector: "node.bridge-alias",
        style: {
          "border-style": "dashed",
          "border-width": 3,
          "underlay-color": "#ffffff",
          "underlay-opacity": 0.92,
          "underlay-padding": 4
        }
      },
      {
        selector: "node.first-ring-reference",
        style: {
          "font-size": 10,
          "text-max-width": 126,
          "width": 156,
          "height": 52
        }
      },
      {
        selector: "node.course-chapter",
        style: {
          "font-size": 10,
          "text-max-width": 126,
          "width": 156,
          "height": 52
        }
      },
      {
        selector: ".incoming",
        style: { "background-color": "#f1f5f9", "border-color": "#64748b" }
      },
      {
        selector: ".outgoing",
        style: { "background-color": "#ecfdf5", "border-color": "#159669" }
      },
      {
        selector: ".secondary",
        style: { "font-size": 11, "width": 166, "height": 56, "opacity": 0.82 }
      },
      {
        selector: "node[hasMapColor]",
        style: {
          "background-color": "data(mapBackground)",
          "border-color": "data(mapColor)",
          "color": "data(mapTextColor)"
        }
      },
      {
        selector: "node.selected[hasMapColor]",
        style: { "background-color": "data(mapColor)", "border-color": "data(mapColor)", "color": "data(mapSelectedTextColor)" }
      },
      { selector: ".faded", style: { "opacity": 0.12 } },
      { selector: ".context-hidden", style: { "display": "none" } },
      { selector: ".mode-hidden", style: { "display": "none" } }
    ]
  }
}
