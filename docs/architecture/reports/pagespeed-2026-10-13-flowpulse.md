# PageSpeed Flowpulse — 13 ottobre 2026

## Perimetro

- ambiente: produzione;
- strumento: Lighthouse `13.4.1`, installato esternamente alla repository;
- strategia: mobile, throttling simulato;
- esecuzioni: tre per pagina;
- valore registrato: mediana;
- report JSON grezzi: temporanei e non versionati.

INP non è disponibile come dato di laboratorio e non viene sostituito con un
valore inventato. TBT è stato osservato come diagnostica, ma non registrato al
posto di INP.

## Risultati

| Pagina | Performance | Accessibilità | LCP | CLS | TTFB | Trasferimento | Richieste |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Landing `/` | 92 | 100 | 2.660 ms | 0 | 55 ms | 309 KB | 16 |
| Progetti `/flowpulse/progetti` | 96 | 100 | 2.631 ms | 0 | 56 ms | 243 KB | 15 |

## Confronto con i budget

Entrambe le pagine rispettano i budget di performance, accessibilità, CLS,
TTFB, trasferimento e numero di richieste. L'LCP supera invece l'obiettivo di
2.500 ms:

- landing: `+160 ms`;
- progetti: `+131 ms`.

La pagina inizialmente prevista, `/flowpulse/rete`, è autenticata e rinvia al
login. Non è stata usata come baseline pubblica: il rilievo Lighthouse sui
target tattili apparteneva al collegamento “Password dimenticata?” del form di
accesso e dovrà essere affrontato separatamente insieme all'autenticazione.

## Diagnostica iniziale

Gli elementi LCP sono testi introduttivi, non immagini:

- landing: il paragrafo che inizia con “Ognuno parte da un battito diverso”;
- progetti: il paragrafo che inizia con “Brand, strumenti e progetti”.

Il miglioramento va quindi cercato soprattutto nel percorso di rendering e
negli asset CSS/JavaScript iniziali, non comprimendo immagini che non
costituiscono l'LCP.

Sulla landing Lighthouse indica come opportunità principali:

- CSS non utilizzato: circa 37 KB e 300 ms stimati;
- JavaScript non utilizzato: circa 25 KB e 300 ms stimati;
- CSS non minificato: circa 7 KB e 150 ms stimati.

È comparso anche un avviso relativo alla source map di
`stimulus.min-2395e199.js`; non incide direttamente sul punteggio pubblico, ma
va verificato durante la revisione degli asset.

## Prossimo intervento

Prima di modificare la grafica occorre identificare l'elemento LCP delle due
pagine pubbliche. Gli interventi devono restare condivisi soltanto quando
layout e asset sono realmente comuni; non si applicano ottimizzazioni
generiche agli altri Brand senza misurarli.
