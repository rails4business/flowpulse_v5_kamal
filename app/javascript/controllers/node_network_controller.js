import { Controller } from "@hotwired/stimulus"
import cytoscape from "cytoscape"

export default class extends Controller {
  static targets = ["stage", "canvas", "drawer", "title", "current", "type", "description", "domains", "relation", "empty", "search", "openLink", "addLink", "deleteLink", "fullscreenButton", "modeButton"]
  static values = { graph: Object, selected: String, mode: { type: String, default: "brand" } }

  connect() {
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
    this.applyMode(this.modeValue, false)
    this.select(this.selectedValue || this.graphValue.elements.find((element) => element.data.kind === "node")?.data.id, false)
    window.requestAnimationFrame(() => {
      this.cy.resize()
      const selected = this.cy.$("node.selected")
      this.cy.fit(selected.length ? selected.closedNeighborhood() : this.cy.elements(), 72)
    })
  }

  disconnect() {
    document.removeEventListener("fullscreenchange", this.fullscreenChangeHandler)
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
    this.cy.layout(this.layoutOptions(selected.first())).run()
    this.cy.fit(selected.length ? selected.closedNeighborhood().not(".mode-hidden") : visible, 60)
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

  async toggleFullscreen() {
    if (document.fullscreenElement === this.stageTarget) {
      await document.exitFullscreen()
    } else {
      await this.stageTarget.requestFullscreen()
    }
  }

  updateFullscreenButton() {
    const active = document.fullscreenElement === this.stageTarget
    this.stageTarget.style.height = active ? "100vh" : "calc(100vh - 65px)"
    this.fullscreenButtonTarget.textContent = active ? "↙" : "⛶"
    this.fullscreenButtonTarget.setAttribute("aria-label", active ? "Esci dallo schermo intero" : "Visualizza a schermo intero")
    this.fullscreenButtonTarget.title = active ? "Esci dallo schermo intero" : "Schermo intero"
    window.setTimeout(() => {
      this.cy?.resize()
      const selected = this.cy?.$("node.selected")
      this.cy?.fit(selected?.length ? selected.closedNeighborhood() : this.cy.elements(), 72)
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
    this.drawerTarget.style.transform = "translateX(calc(100% + 2rem))"
  }

  select(id, updateUrl) {
    const selected = this.cy.getElementById(id)
    if (!selected.length || selected.data("kind") !== "node" || selected.hasClass("mode-hidden")) return

    const neighborhood = selected.closedNeighborhood().not(".mode-hidden")
    this.cy.elements().addClass("context-hidden").removeClass("faded selected incoming outgoing")
    neighborhood.removeClass("context-hidden")
    selected.addClass("selected")

    selected.incomers("node").addClass("incoming")
    selected.outgoers("node").addClass("outgoing")
    selected.connectedEdges().removeClass("faded")

    this.renderDetails(selected)
    this.drawerTarget.style.transform = "translateX(0)"
    this.cy.layout(this.layoutOptions(selected)).run()
    this.cy.animate({ fit: { eles: neighborhood, padding: 72 } }, { duration: 260 })

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
    this.drawerTarget.style.transform = "translateX(calc(100% + 2rem))"
  }

  layoutOptions(focusNode = null) {
    if (focusNode?.length) {
      const focusId = focusNode.id()

      return {
        name: "concentric",
        concentric: (node) => node.id() === focusId ? 2 : 1,
        levelWidth: () => 1,
        minNodeSpacing: 80,
        spacingFactor: 1.35,
        padding: 72,
        startAngle: -Math.PI / 2,
        sweep: Math.PI * 2,
        clockwise: true,
        equidistant: true,
        animate: false
      }
    }

    return {
      name: "breadthfirst",
      directed: true,
      spacingFactor: 1.25,
      padding: 48,
      animate: false
    }
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
        selector: "edge",
        style: {
          "curve-style": "bezier",
          "line-color": "#a8b4c5",
          "target-arrow-color": "#a8b4c5",
          "target-arrow-shape": "triangle",
          "width": 2
        }
      },
      {
        selector: "edge[kind = 'bridge']",
        style: { "line-style": "dashed", "line-color": "#7c3aed", "target-arrow-color": "#7c3aed" }
      },
      {
        selector: "edge[kind = 'ecosystem']",
        style: { "line-color": "#2563eb", "target-arrow-color": "#2563eb", "width": 4 }
      },
      {
        selector: "edge[kind = 'professional-owner']",
        style: { "line-style": "dotted", "line-color": "#0f9f6e", "target-arrow-color": "#0f9f6e", "width": 3 }
      },
      {
        selector: ".selected",
        style: { "background-color": "#2563eb", "border-color": "#1d4ed8", "color": "#ffffff" }
      },
      {
        selector: ".incoming",
        style: { "background-color": "#f1f5f9", "border-color": "#64748b" }
      },
      {
        selector: ".outgoing",
        style: { "background-color": "#ecfdf5", "border-color": "#159669" }
      },
      { selector: ".faded", style: { "opacity": 0.12 } },
      { selector: ".context-hidden", style: { "display": "none" } },
      { selector: ".mode-hidden", style: { "display": "none" } }
    ]
  }
}
