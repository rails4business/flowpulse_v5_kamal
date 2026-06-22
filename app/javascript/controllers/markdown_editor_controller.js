import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (!window.EasyMDE) {
      this.retries = (this.retries || 0) + 1
      if (this.retries <= 20) this.loadRetry = window.setTimeout(() => this.connect(), 50)
      return
    }

    if (this.editor) return

    this.editor = new window.EasyMDE({
      element: this.element,
      autofocus: false,
      forceSync: true,
      minHeight: "420px",
      placeholder: this.element.placeholder,
      spellChecker: false,
      status: false,
      toolbar: [
        "bold",
        "italic",
        "heading",
        "|",
        "quote",
        "unordered-list",
        "ordered-list",
        "|",
        "link",
        "image",
        "table",
        "|",
        "preview",
        "side-by-side",
        "fullscreen"
      ]
    })

    this.editor.codemirror.on("change", () => this.editor.codemirror.save())
  }

  disconnect() {
    window.clearTimeout(this.loadRetry)

    if (!this.editor) return

    this.editor.toTextArea()
    this.editor = null
  }
}
