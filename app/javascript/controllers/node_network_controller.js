import { Controller } from "@hotwired/stimulus"
import cytoscape from "cytoscape"

export default class extends Controller {
  static targets = ["stage", "canvas", "orbitOverlay", "drawer", "panelButton", "title", "current", "type", "description", "domains", "relation", "empty", "search", "openLink", "addLink", "deleteLink", "fullscreenButton", "modeButton", "centerModeLink"]
  static values = { graph: Object, selected: String, mode: { type: String, default: "brand" }, automaticCenter: Boolean, fixedCenter: Boolean }

  connect() {
    this.drawerOpen = true
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

    this.cy.on("tap", "node", (event) => this.select(event.target.id(), true))
    this.orbitViewportHandler = () => this.scheduleOrbitRender()
    this.cy.on("pan zoom resize", this.orbitViewportHandler)
    this.applyMode(this.modeValue, false)
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
    const directNodes = selected.neighborhood("node").not(".mode-hidden")
    this.cy.elements().addClass("context-hidden").removeClass("faded selected incoming outgoing secondary")
    neighborhood.removeClass("context-hidden")
    selected.addClass("selected")
    neighborhood.nodes().not(selected).not(directNodes).addClass("secondary")

    selected.incomers("node").addClass("incoming")
    selected.outgoers("node").addClass("outgoing")
    selected.connectedEdges().removeClass("faded")

    this.renderDetails(selected)
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

  renderDetails(node) {
    const data = node.data()
    this.emptyTarget.hidden = true
    this.titleTarget.textContent = data.label
    this.currentTarget.textContent = `FlowPulse › ${data.label}`
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
    this.currentTarget.textContent = "FlowPulse › Tutta la rete"
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

    const neighborhood = this.contextFor(selected)
    const positions = this.radialPositions(selected, neighborhood.nodes())
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

  radialPositions(selected, nodes) {
    const focusId = selected.id()
    const positions = { [focusId]: { x: 0, y: 0 } }
    const hierarchyEdges = this.hierarchyEdges()
    const contextualEdges = this.automaticCenterValue ? this.contextualEdgesFor(selected) : this.cy.collection()
    const layoutEdges = this.automaticCenterValue
      ? hierarchyEdges.union(contextualEdges)
      : hierarchyEdges
    const contextualIds = new Set(contextualEdges.connectedNodes().not(selected).map((node) => node.id()))
    const visited = new Set([focusId])
    const depth = new Map([[focusId, 0]])
    const children = new Map([[focusId, []]])
    const rings = new Map()
    const queue = [selected]

    while (queue.length) {
      const current = queue.shift()
      const neighbors = current.connectedEdges().intersection(layoutEdges).connectedNodes()
        .intersection(nodes).sort((a, b) => {
          const contextualDifference = Number(contextualIds.has(a.id())) - Number(contextualIds.has(b.id()))
          return contextualDifference || this.compareNodes(a, b)
        })

      neighbors.forEach((neighbor) => {
        if (visited.has(neighbor.id())) return

        visited.add(neighbor.id())
        const ring = depth.get(current.id()) + 1
        depth.set(neighbor.id(), ring)
        children.set(neighbor.id(), [])
        children.get(current.id()).push(neighbor)
        rings.set(ring, [...(rings.get(ring) || []), neighbor])
        queue.push(neighbor)
      })
    }

    const disconnectedNodes = nodes.filter((node) => !visited.has(node.id())).sort((a, b) => this.compareNodes(a, b))
    disconnectedNodes.forEach((node) => {
      visited.add(node.id())
      depth.set(node.id(), 1)
      children.set(node.id(), [])
      children.get(focusId).push(node)
      rings.set(1, [...(rings.get(1) || []), node])
    })

    const radii = new Map([[0, 0]])
    const maxDepth = Math.max(0, ...rings.keys())
    for (let ring = 1; ring <= maxDepth; ring += 1) {
      const count = (rings.get(ring) || []).length
      const maxClusterSpan = Math.PI * 1.75
      const collisionRadius = count <= 1 ? 180 : 210 / (2 * Math.sin(maxClusterSpan / (2 * (count - 1))))
      const provisionalGap = ring === 1 ? 220 : 140
      radii.set(ring, Math.max(radii.get(ring - 1) + provisionalGap, collisionRadius))
    }

    const angles = new Map()
    const collisionMargin = 21
    const dimensionsFor = (ring) => {
      if (ring === 0) return { width: 210, height: 70 }
      if (ring === 1) return { width: 184, height: 62 }
      return { width: 166, height: 56 }
    }
    const boxAt = (node, ring, radius) => {
      const angle = angles.get(node.id())
      const dimensions = dimensionsFor(ring)
      const x = Math.cos(angle) * radius
      const y = Math.sin(angle) * radius
      return {
        node,
        x,
        y,
        left: x - dimensions.width / 2 - collisionMargin,
        right: x + dimensions.width / 2 + collisionMargin,
        top: y - dimensions.height / 2 - collisionMargin,
        bottom: y + dimensions.height / 2 + collisionMargin
      }
    }
    const boxesOverlap = (first, second) => !(
      first.right <= second.left || first.left >= second.right ||
      first.bottom <= second.top || first.top >= second.bottom
    )
    const childOffsets = new Map()
    const calculateCones = () => {
      childOffsets.clear()
      const sectorWidths = new Map()
      const calculateSector = (node, branchAngle = 0) => {
        const nodeChildren = children.get(node.id()) || []
        if (!nodeChildren.length) {
          sectorWidths.set(node.id(), 0)
          return 0
        }

        // Root branches first receive their real direction. Their descendants
        // can then calculate tangential clearance for that orientation.
        if (node.id() === focusId && nodeChildren.length > 1) {
          if (nodeChildren.length === 2) {
            const rootSpan = Math.PI / 2
            nodeChildren.forEach((child, index) => {
              const childAngle = -rootSpan / 2 + rootSpan * index
              childOffsets.set(child.id(), childAngle)
              calculateSector(child, childAngle)
            })
            sectorWidths.set(node.id(), rootSpan)
            return rootSpan
          }

          const rootSpan = Math.PI * 2
          const rootStep = rootSpan / nodeChildren.length
          nodeChildren.forEach((child, index) => {
            const childAngle = -Math.PI / 2 + rootStep * index
            childOffsets.set(child.id(), childAngle)
            calculateSector(child, childAngle)
          })
          sectorWidths.set(node.id(), rootSpan)
          return rootSpan
        }

        const childRing = depth.get(nodeChildren[0].id())
        const childRadius = radii.get(childRing)
        const childDimensions = dimensionsFor(childRing)
        const tangentialSize = (
          Math.abs(Math.sin(branchAngle)) * childDimensions.width +
          Math.abs(Math.cos(branchAngle)) * childDimensions.height +
          collisionMargin * 2
        )
        const minimumSeparation = 2 * Math.asin(Math.min(1, tangentialSize / (2 * childRadius)))
        const infos = nodeChildren.map((child) => ({ child, width: calculateSector(child, branchAngle) }))

        const centers = []
        let rightEdge = 0
        infos.forEach((info, index) => {
          const halfWidth = info.width / 2
          const center = index === 0
            ? halfWidth
            : Math.max(rightEdge + halfWidth, centers[index - 1] + minimumSeparation)
          centers.push(center)
          rightEdge = center + halfWidth
        })

        const leftEdge = centers.length ? centers[0] - infos[0].width / 2 : 0
        const sectorCenter = (leftEdge + rightEdge) / 2
        infos.forEach((info, index) => childOffsets.set(info.child.id(), centers[index] - sectorCenter))
        const width = Math.max(0, rightEdge - leftEdge)
        sectorWidths.set(node.id(), width)
        return width
      }
      calculateSector(selected)

      angles.set(focusId, 0)
      const assignAngles = (node) => {
        const baseAngle = angles.get(node.id()) || 0
        ;(children.get(node.id()) || []).forEach((child) => {
          angles.set(child.id(), baseAngle + (childOffsets.get(child.id()) || 0))
          assignAngles(child)
        })
      }
      assignAngles(selected)

      // The tree owns the angle, not the ring. Packing each orbital independently
      // made single-child chains zig-zag because a child could be rotated away
      // from its parent. Sibling cones are already separated recursively above;
      // any remaining collision is solved by increasing that orbital's radius.
    }

    const solveRadii = () => {
      for (let ring = 1; ring <= maxDepth; ring += 1) {
        const orbitalStep = ring === 4 ? 206 : 196
        radii.set(ring, ring === 1 ? 230 : radii.get(ring - 1) + orbitalStep)
      }
    }

    for (let iteration = 0; iteration < 7; iteration += 1) {
      calculateCones()
      solveRadii()
    }

    nodes.not(selected).forEach((node) => {
      const ring = depth.get(node.id())
      const box = boxAt(node, ring, radii.get(ring))
      positions[node.id()] = { x: box.x, y: box.y }
    })

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
    if (!selected.length || !rings.length) return

    const center = selected.renderedPosition()
    const zoom = this.cy.zoom()
    const namespace = "http://www.w3.org/2000/svg"
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

  contextFor(selected) {
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
    const directlyLinkedIds = new Set(
      contextualEdges.connectedNodes().not(selected).map((node) => node.id())
    )
    nodes = nodes.union(contextualEdges.connectedNodes())
    const edges = hierarchyEdges.filter((edge) => (
      siteNodes.contains(edge.source()) &&
      siteNodes.contains(edge.target()) &&
      !directlyLinkedIds.has(edge.target().id())
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
    return selected.connectedEdges(selector).not(".mode-hidden").filter((edge) => {
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
          "height": 62
        }
      },
      {
        selector: "node[hasDomain]",
        style: { "background-color": "#eef5ff", "border-width": 3 }
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
        style: { "curve-style": "bezier", "line-style": "dashed", "line-color": "#7c3aed", "target-arrow-color": "#7c3aed" }
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
        selector: ".selected",
        style: { "background-color": "#2563eb", "border-color": "#1d4ed8", "border-width": 5, "color": "#ffffff", "width": 210, "height": 70 }
      },
      {
        selector: "node.selected[hasMapColor]",
        style: { "background-color": "data(mapColor)", "border-color": "data(mapColor)", "color": "data(mapSelectedTextColor)" }
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
