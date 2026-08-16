// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

document.addEventListener("click", (event) => {
  document.querySelectorAll("details[data-close-on-outside][open]").forEach((menu) => {
    if (!menu.contains(event.target)) menu.removeAttribute("open")
  })
})

document.addEventListener("keydown", (event) => {
  if (event.key !== "Escape") return

  document.querySelectorAll("details[data-close-on-outside][open]").forEach((menu) => {
    menu.removeAttribute("open")
    menu.querySelector("summary")?.focus()
  })
})
