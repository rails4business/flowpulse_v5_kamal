import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide", "tab"]
  static values = { interval: { type: Number, default: 8000 }, initial: String }

  connect() {
    this.index = Math.max(0, this.slideTargets.findIndex((slide) => slide.dataset.slideId === this.initialValue))
    this.paused = false
    this.touchStartX = null
    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.render(false)
    this.observer = new IntersectionObserver(([entry]) => {
      this.visible = entry.isIntersecting
      this.schedule()
    }, { threshold: 0.35 })
    this.observer.observe(this.element)
  }

  disconnect() {
    this.stop()
    this.observer?.disconnect()
  }

  previous(event) {
    event?.preventDefault()
    this.goTo((this.index - 1 + this.slideTargets.length) % this.slideTargets.length)
  }

  next(event) {
    event?.preventDefault()
    this.goTo((this.index + 1) % this.slideTargets.length)
  }

  select(event) {
    event.preventDefault()
    this.goTo(Number(event.params.index))
  }

  pause() {
    this.paused = true
    this.stop()
  }

  resume() {
    this.paused = false
    this.schedule()
  }

  visibilityChange() {
    document.hidden ? this.stop() : this.schedule()
  }

  touchStart(event) {
    this.touchStartX = event.touches[0]?.clientX
    this.pause()
  }

  touchEnd(event) {
    if (this.touchStartX !== null) {
      const distance = event.changedTouches[0]?.clientX - this.touchStartX
      if (Math.abs(distance) > 45) distance > 0 ? this.previous() : this.next()
    }
    this.touchStartX = null
    this.resume()
  }

  goTo(index) {
    if (!Number.isInteger(index) || index < 0 || index >= this.slideTargets.length) return

    this.index = index
    this.render(true)
    this.schedule()
  }

  render(updateUrl) {
    this.slideTargets.forEach((slide, index) => {
      const active = index === this.index
      slide.classList.toggle("hidden", !active)
      slide.setAttribute("aria-hidden", String(!active))
    })
    this.tabTargets.forEach((tab) => {
      const active = tab.dataset.slideId === this.slideTargets[this.index].dataset.slideId
      tab.setAttribute("aria-selected", String(active))
      tab.classList.toggle("border-blue-600", active)
      tab.classList.toggle("text-blue-700", active)
      tab.classList.toggle("bg-white", active)
      tab.classList.toggle("border-transparent", !active)
      tab.classList.toggle("text-slate-600", !active)
      tab.classList.toggle("bg-slate-50", !active)
    })
    if (updateUrl) {
      const url = new URL(window.location.href)
      url.searchParams.set("home", this.slideTargets[this.index].dataset.slideId)
      window.history.replaceState({}, "", url)
    }
  }

  schedule() {
    this.stop()
    if (this.reducedMotion || this.paused || !this.visible) return
    const delay = this.index === this.slideTargets.length - 1 ? this.intervalValue * 1.5 : this.intervalValue
    this.timer = window.setTimeout(() => this.next(), delay)
  }

  stop() {
    if (this.timer) window.clearTimeout(this.timer)
    this.timer = null
  }
}
