# Roadmap del motore Radial Sector Layout

## Obiettivo

Costruire un motore di layout radiale proprietario, indipendente da Cytoscape e ispirato ai principi generali dei radial layout: centro singolo, livelli concentrici, settori gerarchici non sovrapposti, ordine stabile dei figli e raggi minimi necessari.

Il motore non copia codice o API di yFiles e non richiede nuove gemme, pacchetti Node o licenze commerciali.

## Responsabilità

- Rails e YAML definiscono nodi, relazioni, visibilità, domini e ordinamento.
- Il controller prepara il sottoinsieme visibile e l'albero di layout.
- Il motore radiale calcola coordinate, angoli, raggi e settori.
- Cytoscape disegna nodi, collegamenti, animazioni e interazioni.

## Fase 1 — Estrazione e base verificabile

Stato: **completata**

- [x] Documentare architettura e fasi.
- [x] Estrarre la geometria da `node_network_controller.js`.
- [x] Definire un input indipendente da Cytoscape.
- [x] Restituire posizioni, raggi e angoli senza modificare la resa corrente.
- [x] Aggiungere test JavaScript eseguibili senza dipendenze aggiuntive.
- [x] Verificare il caricamento Importmap e i test Rails esistenti.

Criterio di completamento: il controller non contiene più il calcolo geometrico e il risultato visivo rimane equivalente.

## Fase 2 — Settori gerarchici completi

Stato: **completata**

- [x] Calcolare bottom-up l'ingombro di ogni sottoalbero per ciascun livello.
- [x] Garantire che settori indipendenti non si intersechino nello spazio angolare disponibile.
- [x] Conservare la direzione del ramo lungo tutti i livelli.
- [x] Rispettare l'ordine configurato di parent e children.
- [x] Adattare il cono ai soli livelli effettivamente visibili.
- [x] Gestire in modo deterministico rami profondi e rami molto popolati.

Criterio di completamento: nessuna sovrapposizione tra rami gerarchici nei casi coperti dai test e coni coerenti cambiando profondità.

## Fase 3 — Raggi minimi e collisioni

Stato: **completata**

- [x] Calcolare il raggio minimo di ogni anello dalle dimensioni reali delle card.
- [x] Considerare etichette, margini e ingombro visuale delle card extra-dominio.
- [x] Aumentare il raggio soltanto quando lo spazio angolare non basta.
- [x] Eseguire una correzione finale locale senza alterare la direzione dei coni.
- [x] Stabilizzare il layout quando si cambia centro o numero di livelli.

Nota: i recinti che raggruppano più nodi restano nella fase 4, insieme alle altre geometrie trasversali al singolo sottoalbero.

Criterio di completamento: anelli compatti ed equidistanti quando possibile, senza esplosioni dello spazio causate da collisioni tra livelli diversi.

## Fase 4 — Relazioni trasversali e rifinitura UX

Stato: **completata**

- [x] Separare l'albero di layout dai bridge e dagli altri collegamenti trasversali.
- [x] Scegliere l'albero di supporto più leggibile quando il grafo non è un albero.
- [x] Ridurre incroci e sovrapposizioni dei collegamenti non gerarchici.
- [x] Integrare recinti di dominio e nodi extra-dominio nel calcolo finale.
- [x] Aggiungere diagnostica opzionale di settori, collisioni e raggi.
- [x] Verificare prestazioni e stabilità su reti grandi.

Criterio di completamento: All e Only Node mantengono le proprie regole, con disposizione leggibile e prevedibile anche in presenza di bridge.

La diagnostica può essere letta nella console aggiungendo `layout_debug=1` alla query string della pagina.

## Contratto previsto del motore

```js
const result = calculateRadialSectorLayout({
  focusId,
  nodeIds,
  childrenById,
  depthById,
  ringNodeIds,
  rootDirections,
  dimensionsByRing,
  nodeDimensionsById,
  minimumRingGap,
  collisionMargin
})

// result.positions[id] -> { x, y }
// result.radii          -> Map<livello, raggio>
// result.angles         -> Map<id, angolo>
// result.sectors        -> Map<id, Map<livello, { min, max }>>
```

## Decisioni tecniche

- JavaScript puro perché le dimensioni e l'interazione appartengono al browser.
- Nessuna dipendenza aggiuntiva.
- Input composto da identificativi e strutture dati semplici, senza oggetti Cytoscape.
- Algoritmo deterministico: stesso input e stesso ordine producono lo stesso risultato.
- Ruby continua a gestire dati e autorizzazioni, non la geometria interattiva.

