# Funnel di Ingresso: PosturaCorretta Start (In Lavorazione)

## Obiettivo
Sviluppare la nuova esperienza gamificata e "instagrammabile" lavorando in parallelo rispetto al sito attuale, in una sezione isolata. Il nuovo funnel non sostituirà l'ingresso principale finché non sarà completato.
Utilizzeremo il prototipo HTML fornito (`public/viste_html/posturacorretta_app.html`) per costruire la vista e lo stile del nuovo controller.

## Architettura e Decisioni
- **Nome Controller:** `PosturacorrettastartController`
- **Integrazione Prototipo:** Trasferiremo il CSS e l'HTML dal file statico `posturacorretta_app.html` nei relativi file di Rails, creando un layout dedicato per non interferire con il CSS globale del sito in questa fase di test.
- **Sviluppo in Parallelo:** L'URL sarà `/posturacorrettastart`. Le logiche di interazione (cambio tab, quiz) verranno tradotte in un controller Stimulus.

## Roadmap di Implementazione

### 1. Controller & Routing
- Generazione del controller `PosturacorrettastartController` per gestire questa nuova sezione sperimentale.
- Aggiunta della rotta isolata in `config/routes.rb`:
  ```ruby
  get 'posturacorrettastart', to: 'posturacorrettastart#index'
  ```

### 2. Views & Layout (Dal Prototipo a Rails)
- Creazione del layout `app/views/layouts/posturacorrettastart.html.erb`: un layout Rails dedicato solo a questa sezione. Conterrà il CSS originale del prototipo (tag `<style>`) per garantire un'implementazione rapida e perfettamente fedele al file HTML fornito, senza rischio di conflitti con l'asset pipeline del sito principale.
- Creazione della vista `app/views/posturacorrettastart/index.html.erb`: trascrizione del `<body>` del prototipo `posturacorretta_app.html` in formato ERB. 

### 3. Javascript (Stimulus)
- Creazione del controller `app/javascript/controllers/posturacorrettastart_controller.js`: conversione dello script JS presente nel prototipo (logica di tab switching, quiz e matrice 3D) in un controller Stimulus moderno (`data-controller="posturacorrettastart"`).
