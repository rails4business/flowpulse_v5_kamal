# Ripristinata la home sul dominio principale

L’accesso diretto a `rails4b.com` passava dal dispatcher dei domini, mentre la route interna `/rails4b` passava dal controller della landing.

Il dispatcher ora prepara gli stessi dati YAML prima di renderizzare la pagina:

- identità e testi della landing;
- due percorsi ordinati;
- contenuti associati ai passi;
- percorso selezionato tramite parametro.

La correzione mantiene la home sul dominio principale senza introdurre redirect verso un percorso interno e aggiunge un test specifico per l’host Rails4Business.
