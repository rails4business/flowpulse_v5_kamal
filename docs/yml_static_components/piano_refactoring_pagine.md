# Procedura Standard: Refactoring Pagine con YAML e HyperUI

Questo documento è il modello da seguire ogni volta che vogliamo trasformare una pagina HTML statica (con testi hardcoded) in una pagina dinamica, modulare e facile da gestire.

L'approccio si divide in 3 fasi sequenziali:

---

## Step 1: Struttura YAML e Salvataggio (Data Layer)

Il primo passo è estrarre tutti i testi, i link e i contenuti dalla pagina HTML e spostarli in file YAML. Dividiamo i dati in due categorie chiare:

1. **Dati Condivisi (Globali)**
   - **Cosa sono:** Dati che compaiono in più pagine del sito (es. le voci del menu principale, gli "ambiti" di PosturaCorretta, i link ai social, le categorie degli utenti).
   - **Dove salvarli:** In una cartella dedicata ai file condivisi. Ad esempio: `config/data/posturacorretta/shared/taxonomies.yml` o `config/data/posturacorretta/shared/audiences.yml`.

2. **Dati Specifici per Pagina**
   - **Cosa sono:** Testi esclusivi di una determinata pagina (es. il titolo della Hero section, le FAQ specifiche di quella pagina, il copy di benvenuto).
   - **Dove salvarli:** In una cartella dedicata col nome della sezione/pagina, in modo da poter accogliere in futuro eventuali file Markdown o immagini correlati. Ad esempio: `config/data/posturacorretta/home/home.yml` oppure `.../metodiche/metodiche.yml`.

*(Nota: se in futuro avrai più progetti o marchi, ti basterà sostituire la cartella `posturacorretta` con `brands/[nome_brand]`, mantenendo la suddivisione `shared/` e cartelle per pagina)*.

---

## Step 2: Creazione Componenti HyperUI (Design Layer)

Il secondo passo riguarda il design. Vogliamo smettere di scrivere l'HTML lungo e ripetitivo direttamente nelle viste.

1. **Cartella Componenti:** Assicurati di avere una cartella dedicata per i componenti, come `app/views/components/`.
2. **Scelta del Componente:** Vai su [HyperUI](https://www.hyperui.dev/), trova il componente che fa per te (Accordion per le FAQ, Card per le opzioni, Hero per l'intestazione).
3. **Creazione del Partial:**
   - Crea un file che inizia con underscore (es. `_accordion.html.erb`).
   - Incolla l'HTML di HyperUI.
   - Sostituisci i testi finti con le variabili Ruby. Ricorda che il componente riceverà i dati dall'esterno tramite una variabile (es. `items`), quindi dovrai fare un loop: `<% items.each do |item| %>`.

*Nota:* HyperUI è fantastico perché non usa Javascript per componenti complessi come l'Accordion (sfrutta i tag nativi `<details>` e `<summary>`).

---

## Step 3: Assemblaggio (View + Controller Layer)

L'ultimo passo è unire i Dati (Step 1) con il Design (Step 2) all'interno della pagina finale.

1. **Caricamento dei Dati (Controller):**
   Nel controller che gestisce la pagina (es. `PosturacorrettaController`), carica i file YAML.
   ```ruby
   def home
     # Dati condivisi
     @taxonomies = YAML.load_file(Rails.root.join('config/data/posturacorretta/taxonomies.yml'))
     
     # Dati specifici della pagina
     @page_data = YAML.load_file(Rails.root.join('config/data/posturacorretta/home/home.yml'))
   end
   ```

2. **Renderizzazione della Vista (View):**
   Svuota il file della vista (es. `app/views/landing/posturacorretta.html.erb`) dai vecchi blocchi di codice Ruby e dai testi scritti a mano. Sostituiscili chiamando i componenti e passandogli i dati:
   
   ```erb
   <!-- Esempio: Renderizzare la Hero -->
   <%= render "components/hero", data: @page_data['hero'] %>

   <!-- Esempio: Renderizzare le FAQ -->
   <%= render "components/accordion", items: @page_data['faqs'] %>
   ```

### Risultato Finale
Alla fine di questo processo avrai:
- Viste cortissime e facilissime da leggere.
- Un design perfetto e consistente grazie a Tailwind/HyperUI.
- La possibilità di modificare qualsiasi testo del sito semplicemente cambiando un file YAML, senza mai toccare l'HTML.
