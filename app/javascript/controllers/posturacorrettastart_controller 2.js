import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["pathRequest", "pathPlace", "pathDuration", "pathDiagnosis", "pathMedicalVisits"]

  connect() {
    console.log("PosturacorrettastartController connected!")
    this.selectedMotivation = ""

    const urlParams = new URLSearchParams(window.location.search)
    const tabFromUrl = urlParams.get('tab')
    if (tabFromUrl) {
      this.switchTab({ params: { tab: tabFromUrl } })
    }
  }

  switchTab(event) {
    const tabId = (event.params && event.params.tab) || (event.currentTarget && event.currentTarget.dataset.posturacorrettastartTabParam)
    console.log("Switching to tab:", tabId)
    
    if (!tabId) {
      console.error("No tabId provided!")
      return
    }

    const url = new URL(window.location)
    url.searchParams.set('tab', tabId)
    window.history.pushState({}, '', url)
    
    // Update active state in navigation
    document.querySelectorAll('.tab-btn').forEach(btn => {
      // Classi base per tutti: text-slate-600 hover:text-slate-900
      btn.classList.remove('bg-white', 'text-blue-700', 'shadow-sm', 'bg-blue-600', 'text-white')
      btn.classList.add('text-slate-600')
      
      if (btn.getAttribute('data-posturacorrettastart-tab-param') === tabId) {
        btn.classList.remove('text-slate-600')
        btn.classList.add('bg-white', 'text-blue-700', 'shadow-sm')
      }
    })

    // Hide all tab contents and show selected
    document.querySelectorAll('.tab-content').forEach(content => {
      content.classList.add('hidden')
      content.classList.remove('block', 'animate-[fadeIn_0.3s_ease-in-out]')
    })
    
    const targetTab = document.getElementById('tab-' + tabId)
    if (targetTab) {
      targetTab.classList.remove('hidden')
      targetTab.classList.add('block', 'animate-[fadeIn_0.3s_ease-in-out]')
    } else {
      console.error("Target tab not found: tab-" + tabId)
    }

    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  nextQuizStep(event) {
    this.selectedMotivation = event.params.motivation || event.currentTarget.dataset.posturacorrettastartMotivationParam
    document.getElementById('quiz-step-1').classList.add('hidden')
    document.getElementById('quiz-step-2').classList.remove('hidden')
  }

  showQuizResult(event) {
    const approachText = event.params.approach || event.currentTarget.dataset.posturacorrettastartApproachParam
    document.getElementById('quiz-step-2').classList.add('hidden')
    document.getElementById('quiz-result').classList.remove('hidden')
    
    const motivationPrefix = this.selectedMotivation ? this.selectedMotivation.split(':')[0] : ""
    document.getElementById('result-title').innerText = approachText + " (" + motivationPrefix + ")"
  }

  resetQuiz() {
    document.getElementById('quiz-result').classList.add('hidden')
    document.getElementById('quiz-step-1').classList.remove('hidden')
    this.selectedMotivation = ""
  }

  toggleMatrix() {
    const matrix = document.getElementById('matrix-container')
    if (matrix.classList.contains('hidden')) {
      matrix.classList.remove('hidden')
    } else {
      matrix.classList.add('hidden')
    }
  }

  sendPathRequest(event) {
    event.preventDefault()

    const request = this.pathRequestTarget.value.trim()
    if (!request) return

    const message = [
      "Ciao, vorrei iniziare un percorso con PosturaCorretta.",
      "",
      "Problema o obiettivo:",
      request,
      `Paese o città: ${this.pathPlaceTarget.value.trim()}`,
      `Da quanto tempo: ${this.pathDurationTarget.value.trim()}`,
      `Diagnosi: ${this.pathDiagnosisTarget.value}`,
      `Medico o visite: ${this.pathMedicalVisitsTarget.value}`,
      "",
      "Vorrei essere ricontattato per capire come procedere."
    ].join("\n")

    window.open(`https://wa.me/393792891488?text=${encodeURIComponent(message)}`, "_blank", "noopener,noreferrer")
  }
}
