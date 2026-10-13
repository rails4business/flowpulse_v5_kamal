# PageSpeed — contratto e baseline dei domini

La configurazione canonica è
`config/data/performance/domain_budgets.yml`. Contiene i budget comuni, le
pagine rappresentative e lo stato della baseline di ogni dominio canonico.

## Regole

- Lighthouse o PageSpeed Insights vengono eseguiti **esternamente** alla
  repository: non si installano pacchetti npm nel progetto Rails.
- La strategia iniziale è mobile, con tre esecuzioni per pagina.
- Si registra il valore mediano, la data, l'ambiente e lo strumento usato.
- Una baseline resta `pending` finché non esiste una misurazione reale.
- Un dominio non pubblico può essere `skipped`, sempre con una motivazione.
- I punteggi non diventano campi di Domain, Node o Skill.

## Budget iniziali

| Misura | Budget |
| --- | ---: |
| Performance | almeno 90 |
| Accessibilità | almeno 90 |
| LCP | massimo 2.500 ms |
| INP | massimo 200 ms |
| CLS | massimo 0,1 |
| TTFB | massimo 800 ms |
| Trasferimento | massimo 1.536 KB |
| Richieste | massimo 70 |

Questi sono obiettivi iniziali, non risultati già raggiunti. INP e dati reali
possono non essere disponibili per domini con poco traffico; in quel caso si
registra l'assenza senza sostituirla con un valore inventato.

## Controllo interno

```sh
bin/rails performance:audit
```

Il comando controlla che ogni Domain canonico sia coperto, che budget e path
siano validi e mostra le baseline ancora da misurare. Non avvia Lighthouse e
non effettua chiamate di rete.

## Misurazione automatizzata esterna

Il runner comune usa il binario Lighthouse già installato nel sistema, senza
aggiungere dipendenze npm all'applicazione:

```sh
# Elenca le pagine pending senza effettuare richieste
script/audit_domain_performance.rb --dry-run

# Misura un solo dominio, anche se possiede già una baseline
script/audit_domain_performance.rb --domain flowpulse.net

# Misura tutte le baseline pending e fallisce se supera un budget
script/audit_domain_performance.rb --strict
```

Per ogni pagina esegue tre audit mobile, calcola la mediana e produce
`summary.json`, `report.md` e i report Lighthouse grezzi in una cartella
temporanea. Non modifica automaticamente il catalogo versionato: i risultati
vanno controllati prima di essere registrati. Un redirect verso login viene
considerato un errore, così una pagina privata non può essere scambiata per la
pagina pubblica richiesta.

## Linee guida comuni del frontend

I Brand mantengono colori, tipografia e identità differenti, ma condividono
questi vincoli tecnici:

- CSS compilato e minificato in produzione; niente framework caricati da CDN
  nelle pagine definitive;
- componenti comuni per nav, pulsanti, form, dialog, privacy e autenticazione,
  personalizzati tramite token del Brand;
- target tattili comodi, con obiettivo di almeno 44 × 44 px nei controlli
  principali e spaziatura sufficiente fra link vicini;
- JavaScript caricato soltanto dove serve; servizi esterni e video rimandati
  fino al consenso o all'interazione;
- immagini con dimensioni dichiarate; risorsa LCP caricata prioritariamente e
  immagini fuori schermo in lazy loading;
- pagine autenticate escluse da sitemap, `llms.txt` e baseline pubbliche;
- stesso budget mobile e stessa procedura di misurazione per tutti i domini.

Una regola condivisa non implica un unico foglio CSS gigantesco. Layout e
componenti riutilizzabili restano comuni; ogni Site aggiunge soltanto tema e
stili realmente necessari.

## Registrazione futura

Dopo le misurazioni esterne, per ogni pagina si aggiungeranno al relativo
`baseline` la data, lo strumento e le mediane delle tre esecuzioni. I report
grezzi voluminosi non devono entrare nei modelli applicativi; possono essere
archiviati separatamente e collegati dal report tecnico datato.
