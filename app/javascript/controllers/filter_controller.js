// app/javascript/controllers/filter_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [
        "categoryDropdown", "brandDropdown",
        "categoryList", "brandList",
        "currentCategory", "currentBrand",
        "categoryArrow", "brandArrow"
    ]

    connect() {
        this.handleWindowClick = this.handleWindowClick.bind(this)
        window.addEventListener('click', this.handleWindowClick)
    }

    disconnect() {
        window.removeEventListener('click', this.handleWindowClick)
    }

    handleWindowClick(event) {
        if (!event.target.closest('.dropdown-container')) {
            this.closeAll()
        }
    }

    toggle(event) {
        const type = event.currentTarget.dataset.filterType
        const dropdown = this[`${type}DropdownTarget`]
        const arrow = this[`${type}ArrowTarget`]
        const wasHidden = dropdown.classList.contains('hidden')

        this.closeAll()
        dropdown.classList.toggle('hidden')

        // Ruota la freccia solo se ora è aperto
        if (!wasHidden) {
            arrow.classList.add('rotate-180')
        }
    }

    filter(event) {
        const type = event.currentTarget.dataset.filterType
        const query = event.target.value.toLowerCase()
        const list = this[`${type}ListTarget`]

        Array.from(list.children).forEach(item => {
            const text = item.innerText.toLowerCase()
            item.style.display = text.includes(query) ? 'flex' : 'none'
        })
    }

    select(event) {
        const type = event.currentTarget.dataset.filterType
        const value = event.currentTarget.dataset.value

        if (type === 'category' && this.hasCurrentCategoryTarget) {
            this.currentCategoryTarget.textContent = value
        } else if (type === 'brand' && this.hasCurrentBrandTarget) {
            this.currentBrandTarget.textContent = value
        }

        this.closeAll()

        // Opzionale: emetti evento per aggiornare la lista via AJAX/Turbo in futuro
        this.element.dispatchEvent(new CustomEvent('filter:change', { detail: { type, value } }))
    }

    reset() {
        if (this.hasCurrentCategoryTarget) this.currentCategoryTarget.textContent = 'Tutte'
        if (this.hasCurrentBrandTarget) this.currentBrandTarget.textContent = 'Tutti'

        // Se hai ancora la funzione globale showSubTab, puoi chiamarla qui:
        // if (typeof showSubTab === 'function') showSubTab('all')
    }

    closeAll() {
        if (this.hasCategoryDropdownTarget) this.categoryDropdownTarget.classList.add('hidden')
        if (this.hasBrandDropdownTarget) this.brandDropdownTarget.classList.add('hidden')
        if (this.hasCategoryArrowTarget) this.categoryArrowTarget.classList.remove('rotate-180')
        if (this.hasBrandArrowTarget) this.brandArrowTarget.classList.remove('rotate-180')
    }
}