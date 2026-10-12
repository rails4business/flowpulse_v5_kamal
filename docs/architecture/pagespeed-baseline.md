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

## Registrazione futura

Dopo le misurazioni esterne, per ogni pagina si aggiungeranno al relativo
`baseline` la data, lo strumento e le mediane delle tre esecuzioni. I report
grezzi voluminosi non devono entrare nei modelli applicativi; possono essere
archiviati separatamente e collegati dal report tecnico datato.
