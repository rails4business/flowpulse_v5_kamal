import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "list" ]

  connect() {
    this.article = document.querySelector(".node-public-article")
    this.headings = Array.from(document.querySelectorAll(".node-public-content h1, .node-public-content h2, .node-public-content h3"))
    if (this.headings.length === 0) {
      this.element.style.display = "none"
      return
    }

    this.buildToc()
    this.setupObserver()
    this.scrollToInitialHash()

    const tocToggle = document.getElementById("tocSidebarToggle")
    if (tocToggle) {
      tocToggle.classList.remove("hidden")
    }
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  buildToc() {
    const listElement = this.listTarget
    listElement.innerHTML = ""
    this.links = []

    this.headings.forEach((heading, index) => {
      // Ensure the heading has an ID
      if (!heading.id) {
        heading.id = this.parameterize(heading.textContent) || `section-${index}`
      }

      // Add scroll-margin-top so scroll targets sit nicely below fixed header
      heading.style.scrollMarginTop = "100px"

      const headingLevel = Number.parseInt(heading.tagName.replace("H", ""), 10)
      const li = document.createElement("li")
      li.className = "node-public-toc-item"

      const link = document.createElement("a")
      link.href = `#${heading.id}`
      link.className = `node-public-toc-link node-public-toc-link-level-${Math.min(headingLevel, 3)}`
      
      link.textContent = heading.textContent
      link.dataset.tocId = heading.id

      // Smooth scroll handler
      link.addEventListener("click", (e) => {
        e.preventDefault()
        this.activateLink(heading.id)
        this.scrollArticleToHeading(heading)
        history.pushState(null, null, `#${heading.id}`)
      })

      li.appendChild(link)
      listElement.appendChild(li)
      this.links.push(link)
    })
  }

  setupObserver() {
    this.observer = new IntersectionObserver((entries) => {
      // Find the first entry that is intersecting
      const visibleEntry = entries.find(entry => entry.isIntersecting)
      if (visibleEntry) {
        const id = visibleEntry.target.id
        this.activateLink(id)
      }
    }, {
      root: this.article,
      rootMargin: "-24px 0px -75% 0px"
    })

    this.headings.forEach(heading => this.observer.observe(heading))
  }

  activateLink(id) {
    if (this.activeTocId === id) return

    this.activeTocId = id
    let activeLink = null

    this.links.forEach(link => {
      const isActive = link.dataset.tocId === id

      if (isActive) {
        activeLink = link
        link.classList.add("is-active")
        link.setAttribute("aria-current", "true")
      } else {
        link.classList.remove("is-active")
        link.removeAttribute("aria-current")
      }
    })

    if (activeLink) {
      this.scrollActiveLinkIntoView(activeLink)
    }
  }

  scrollActiveLinkIntoView(link) {
    const scrollContainer = this.element
    if (scrollContainer.scrollHeight <= scrollContainer.clientHeight) return

    const containerRect = scrollContainer.getBoundingClientRect()
    const linkRect = link.getBoundingClientRect()
    const topPadding = 16
    const targetTop = scrollContainer.scrollTop + linkRect.top - containerRect.top - topPadding
    if (Math.abs(scrollContainer.scrollTop - targetTop) < 8) return

    scrollContainer.scrollTo({
      top: targetTop,
      behavior: "smooth"
    })
  }

  scrollArticleToHeading(heading, behavior = "smooth") {
    if (!this.article || !heading) return

    const articleRect = this.article.getBoundingClientRect()
    const headingRect = heading.getBoundingClientRect()
    const topPadding = 20
    const targetTop = this.article.scrollTop + headingRect.top - articleRect.top - topPadding

    this.article.scrollTo({
      top: Math.max(targetTop, 0),
      behavior
    })
  }

  scrollToInitialHash() {
    if (!window.location.hash) return

    const hash = decodeURIComponent(window.location.hash.slice(1))
    const heading = this.headings.find((item) => item.id === hash)
    if (!heading) return

    requestAnimationFrame(() => {
      this.activateLink(heading.id)
      this.scrollArticleToHeading(heading, "auto")
    })
  }

  parameterize(string) {
    return string
      .toLowerCase()
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "") // remove accents
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/(^-|-$)/g, "")
  }
}
