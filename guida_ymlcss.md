# Guida: Creare Componenti Rails con YAML e HyperUI

Questa guida ti spiega come trasformare le tue pagine Rails in un sistema flessibile (stile CMS), separando i testi (YAML) dal design (HTML + Tailwind tramite HyperUI).

---

## 1. Il Concetto di Base
Invece di avere file HTML chilometrici con i testi "hardcoded" (scritti fissi nel codice), noi facciamo questo:
1. **Dati (YAML)**: Contiene solo i testi (titoli, descrizioni, bottoni).
2. **Componenti (Partials di Rails)**: Sono pezzetti di codice HTML isolati (`_accordion.html.erb`, `_card.html.erb`). Copiamo il codice da HyperUI qui dentro.
3. **Pagine (Views)**: La pagina unisce i Dati ai Componenti.

---

## 2. Esempio Pratico: L'Accordion delle FAQ

Immagina di voler creare una sezione delle Domande Frequenti (FAQ).

### Step 1: Crea il file YAML (I Dati)
Crea o apri un file, ad esempio `config/data/faq.yml`, e inserisci i dati:

```yaml
# config/data/faq.yml
faqs:
  - question: "Devo avere esperienza pregressa?"
    answer: "Assolutamente no, il percorso è studiato anche per chi parte da zero."
  - question: "Posso disdire l'abbonamento?"
    answer: "Sì, puoi cancellare l'iscrizione in qualsiasi momento dal tuo profilo."
  - question: "Quali metodiche vengono utilizzate?"
    answer: "Integriamo respiro, postura, e movimento consapevole."
```

### Step 2: Crea il Componente Rails (Il Design)
Crea un "partial" (un file che inizia col trattino basso). Lo chiameremo `app/views/components/_accordion.html.erb`. 
Andiamo su [HyperUI FAQ](https://www.hyperui.dev/components/marketing/faqs), copiamo un componente e sostituiamo i testi finti con le nostre variabili Ruby (`item['question']`):

```erb
<!-- app/views/components/_accordion.html.erb -->
<!-- Questo componente si aspetta di ricevere una variabile chiamata 'items' (che sarà un array) -->

<div class="space-y-4">
  <% items.each do |item| %>
    <!-- Il tag <details> gestisce l'apertura/chiusura senza usare Javascript! -->
    <details class="group [&_summary::-webkit-details-marker]:hidden" <%= "open" if item == items.first %>>
      <summary class="flex cursor-pointer items-center justify-between gap-1.5 rounded-lg bg-gray-50 p-4 text-gray-900">
        <h2 class="font-medium">
          <%= item['question'] %>
        </h2>

        <!-- Icona Freccia/Più animata -->
        <span class="shrink-0 rounded-full bg-white p-1.5 text-gray-900 sm:p-3">
          <svg xmlns="http://www.w3.org/2000/svg" class="size-5 shrink-0 transition duration-300 group-open:-rotate-45" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clip-rule="evenodd" />
          </svg>
        </span>
      </summary>

      <p class="mt-4 px-4 leading-relaxed text-gray-700">
        <%= item['answer'] %>
      </p>
    </details>
  <% end %>
</div>
```

### Step 3: Assembla la Pagina (Il Risultato)
Ora, nella pagina in cui vuoi far apparire le FAQ (ad esempio `app/views/pages/home.html.erb`), devi solo dire a Rails di renderizzare il componente passandogli i dati dallo YAML.

**Nel Controller (`app/controllers/pages_controller.rb`):**
```ruby
def home
  # Carichiamo i dati
  @faq_data = YAML.load_file(Rails.root.join('config', 'data', 'faq.yml'))
end
```

**Nella Vista (`app/views/pages/home.html.erb`):**
```erb
<section class="max-w-3xl mx-auto py-12">
  <h2 class="text-3xl font-bold mb-8 text-center">Domande Frequenti</h2>
  
  <!-- Chiamiamo il componente e gli passiamo l'array 'faqs' preso dallo YAML -->
  <%= render "components/accordion", items: @faq_data['faqs'] %>
  
</section>
```

---

## 3. Altri Componenti Frequenti

Questa stessa esatta logica si applica a tutto!
*   **Hero Section**: Lo YAML avrà `title`, `subtitle`, `button_text`. Il partial `_hero.html.erb` formatterà questi 3 dati.
*   **Griglia di Cards**: Lo YAML avrà un array `cards` con `icon`, `title`, `description`. Il partial `_card_grid.html.erb` farà un `.each` per generare le card di HyperUI.
*   **Tab**: Come per le aree di PosturaCorretta. Lo YAML contiene le tab, la vista crea un loop per generare i bottoni e un altro loop per generare i contenuti.

## 4. Perché creare cartelle per i componenti?
È buona norma creare una cartella dedicata ai componenti riutilizzabili (es. `app/views/components/`). In questo modo, se decidi che le Card devono avere l'ombra più marcata (`shadow-xl` invece di `shadow-md`), modifichi solo il file `_card.html.erb` e tutto il sito si aggiornerà automaticamente!
