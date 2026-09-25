import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tree", "rootTemplate", "dayTemplate", "sessionTemplate", "taskTemplate"]
  connect() { this.restore() }
  addRoot() { this.append(this.rootTemplateTarget, this.treeTarget) }
  addDay(event) { this.append(this.dayTemplateTarget, event.target.closest("[data-root]").querySelector("[data-days]")) }
  addSession(event) { this.append(this.sessionTemplateTarget, event.target.closest("[data-day]").querySelector("[data-sessions]")) }
  addTask(event) { this.append(this.taskTemplateTarget, event.target.closest("[data-session]").querySelector("[data-tasks]")) }
  remove(event) { event.target.closest("[data-root], [data-day], [data-session], [data-task]").remove(); this.save() }
  append(template, parent) { parent.append(template.content.cloneNode(true)); this.save() }
  save() { localStorage.setItem("impegno-operational-composer", this.treeTarget.innerHTML) }
  reset() { localStorage.removeItem("impegno-operational-composer"); this.treeTarget.innerHTML = ""; this.addRoot() }
  restore() { const draft = localStorage.getItem("impegno-operational-composer"); if (draft) this.treeTarget.innerHTML = draft; else this.addRoot(); this.element.addEventListener("input", () => this.save()); this.element.addEventListener("change", () => this.save()) }
}
