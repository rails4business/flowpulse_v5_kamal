# Metodiche PosturaCorretta: decisioni da prendere

Questo documento raccoglie le decisioni necessarie per trasformare il catalogo delle metodiche in Node FlowPulse, collegarlo ai corsi e mantenerlo leggibile nella rete.

Le decisioni vanno affrontate **una alla volta**, nell'ordine indicato. Una decisione approvata viene marcata come completata prima di passare alla successiva.

## Stato attuale

- Esiste il Node contenitore `metodiche-posturali`, figlio di `apprendimento-2-connessione`.
- Il contenitore è pubblicato e per ora non ha figli.
- `/posturacorretta/metodiche` espone un catalogo di 9 metodiche configurate in `config/data/posturacorretta/metodiche/metodiche.yml`.
- Ogni metodica possiede già slug, titolo, descrizione, tipologie, ambiti, aree, paradigmi, fondatore e collegamenti a professionisti o scuole.
- La rete supporta Node gerarchici, Node Link tramite ponti, modalità `only/all` e profondità configurabile nell'URL.

## Decisioni già prese

- [x] Creare un solo Node contenitore chiamato **Metodiche posturali**.
- [x] Collocarlo sotto **Apprendimento 2 · Consapevolezza con le metodiche posturali**.
- [x] Non aggiungere metodiche figlie finché non viene decisa la migrazione.
- [x] Conservare nell'URL della Centralità `node`, `vista`, `modalita` e `livelli`.

---

## 1. Quali metodiche diventano Node?

**Domanda:** trasformiamo subito tutte le 9 metodiche attuali in Node figli di `metodiche-posturali`, oppure iniziamo con un gruppo pilota?

Opzioni:

1. Tutte le 9 metodiche.
2. Un primo gruppo pilota, per esempio GDS, Osteopatia e Mézières.
3. Solo le metodiche già collegate a corsi attivi.

**Raccomandazione:** tutte le 9, perché hanno già slug e schede pubbliche; l'importazione può essere automatica e verificabile.

- [x] Decisione approvata
- Scelta: tutte le 9 metodiche attualmente presenti nel catalogo diventano Node figli di `metodiche-posturali`.
- Note: la struttura dei dati da importare viene definita nella decisione 2 prima di creare i Node.

## 2. Qual è la sorgente principale dei dati?

**Domanda:** dopo la creazione dei Node, dove rimangono i dati dettagliati delle metodiche?

Opzioni:

1. Il Node contiene identità e gerarchia; il file `metodiche.yml` conserva i dati specialistici.
2. Tutti i dati vengono trasferiti immediatamente nei Node e nei relativi contenuti.
3. Il file YAML genera interamente i Node a ogni importazione.

**Raccomandazione aggiornata:** trasferimento completo nei Node e nei relativi `NodeContent`; il YAML viene usato soltanto per la migrazione iniziale.

- [x] Decisione approvata
- Scelta: opzione 2. Dopo la migrazione, Node e NodeContent diventano la fonte ufficiale.
- Note: gli attributi strutturati entrano in `NodeContent.data`, il testo in `body_md`; il vecchio YAML resta temporaneamente come confronto e viene dismesso dopo la verifica.

## 3. Quale URL deve essere canonico?

**Domanda:** la scheda pubblica principale resta `/posturacorretta/metodiche/:slug` oppure diventa la Node Show?

Opzioni:

1. Conservare l'URL attuale e renderizzare al suo interno il Node.
2. Rendere canonico l'URL pubblico del Node e reindirizzare il vecchio URL.
3. Conservare entrambe le pagine con funzioni differenti.

**Raccomandazione:** conservare gli URL attuali, evitando rotture e duplicazioni SEO, ma usare progressivamente la stessa composizione della Node Show.

- [ ] Decisione approvata
- Scelta provvisoria: gli URL saranno sistemati dopo l'importazione dei Node.
- Note: prima di cambiare gli URL bisogna definire canonical, redirect, metadati SEO e gestione delle pagine già indicizzate.

## 4. Che relazione hanno le metodiche con i corsi?

**Domanda:** i corsi diventano figli delle metodiche oppure restano nella propria gerarchia e vengono collegati?

Opzioni:

1. Corsi come figli della metodica.
2. Corsi nella gerarchia didattica attuale e Node Link dalla metodica.
3. Nessun collegamento nella prima fase.

**Raccomandazione:** opzione 2. Una metodica può essere presente in più corsi e un corso può utilizzare più metodiche.

- [x] Decisione approvata
- Scelta: i corsi rimangono nella propria gerarchia e vengono collegati alle presentazioni educative delle metodiche tramite Node Link.
- Note: i corsi PosturaCorretta rappresentano un assaggio o un'introduzione ad alcune metodiche, non la metodica completa. Si riutilizzano i Node corso già esistenti, per esempio `principi-di-fisioterapia`.

## 5. Qual è il Node di presentazione educativa?

**Domanda:** quale Node rappresenta la presentazione generale “educazione e conoscenza delle metodiche” a cui collegare le singole metodiche?

Da definire:

- titolo esatto;
- slug;
- posizione nella gerarchia;
- eventuale contenuto già esistente da riutilizzare;
- relazione con `metodiche-posturali` e con i corsi.

Opzioni iniziali:

1. Creare un nuovo Node di presentazione.
2. Riutilizzare un capitolo o Node esistente.
3. Usare direttamente il contenitore `metodiche-posturali` come presentazione.

- [x] Decisione approvata
- Scelta: sotto ciascuna metodica viene creato un Node educativo con titolo nel formato **Conosci [nome metodica] con PosturaCorretta**.
- Note: questo Node presenta il punto di vista educativo di PosturaCorretta e si collega ai corsi esistenti pertinenti; per esempio la presentazione della Fisioterapia si collega a `principi-di-fisioterapia`.

## 6. In quale direzione funzionano i Node Link?

**Domanda:** i collegamenti tra metodiche, presentazione e corsi devono essere visibili da entrambe le estremità?

Possibili direzioni:

1. Bidirezionale.
2. Visibile dalla metodica verso il corso.
3. Visibile dal corso verso la metodica.
4. Direzione scelta separatamente per ogni collegamento.

Da verificare anche la regola in `ONLY NODE`: il Node Link diretto dal centro deve prevalere sulla gerarchia senza duplicare inutilmente lo stesso Node.

- [x] Decisione approvata
- Scelta: collegamento bidirezionale tra la presentazione educativa e la metodica, per poter navigare in entrambe le direzioni.
- Note: la resa in `ONLY NODE` dovrà evitare duplicazioni quando lo stesso elemento è già raggiungibile dalla gerarchia.

## 7. Quanti figli mostra inizialmente il grafico?

**Domanda:** quando un Node ha molti figli, quanti vengono visualizzati subito nella rete radiale?

Opzioni:

1. Tutti i figli.
2. Un limite globale uguale per ogni Node.
3. Un limite configurabile per Node.
4. Un limite calcolato automaticamente in base allo spazio disponibile.

**Raccomandazione:** limite configurabile per Node con un valore predefinito globale. Il numero di livelli non risolve da solo il problema, perché molte metodiche appartengono allo stesso livello.

- [x] Decisione approvata
- Scelta: limite configurabile per Node, con massimo iniziale di 5 figli visibili nel grafico.
- Valore iniziale: 5.
- Note: il limite riguarda soltanto la rappresentazione iniziale; tutti i figli rimangono esistenti e accessibili.

## 8. Come si accede ai figli non mostrati?

**Domanda:** che cosa compare quando il numero dei figli supera il limite?

Opzioni:

1. Un elemento virtuale `+N` che espande il ramo.
2. Un pulsante “Mostra altri” nel pannello laterale.
3. Un collegamento alla vista card o tabella.
4. Combinazione di espansione progressiva e apertura del catalogo.

**Raccomandazione:** opzione 4. Il grafico può espandersi progressivamente, mentre la raccolta completa rimane disponibile in una vista più adatta.

- [x] Decisione approvata
- Scelta: dopo i primi 5 figli compare un riquadro virtuale **Altri +N**.
- Note: il riquadro apre l'elenco completo in tabella. Per ora non viene aggiunto un selettore tra card e tabella.

## 9. Come vengono scelti e ordinati i figli visibili?

**Domanda:** quali metodiche vengono mostrate per prime quando è attivo un limite?

Opzioni:

1. Posizione manuale.
2. Ordine alfabetico.
3. Metodiche evidenziate, poi posizione manuale.
4. Popolarità o numero di collegamenti.

**Raccomandazione:** posizione manuale, con futura possibilità di marcare alcuni Node come evidenziati. L'ordine non dovrebbe dipendere automaticamente dalla popolarità.

- [x] Decisione approvata
- Scelta: ordine manuale tramite il campo `position` già presente nel modello Node.
- Note: i primi cinque elementi secondo `position` vengono mostrati nel grafico; gli altri restano nella tabella completa.

## 10. Qual è la vista principale del contenitore?

**Domanda:** nella Node Show di `metodiche-posturali`, come presentiamo l'elenco completo?

Opzioni:

1. Card.
2. Tabella.
3. Grafico.
4. Card come predefinita, con selettore card/tabella/grafico.

**Raccomandazione aggiornata:** una sola vista completa a tabella, affiancata alla sintesi radiale, evitando per ora controlli di visualizzazione aggiuntivi.

- [x] Decisione approvata
- Scelta: tabella come vista predefinita dell'elenco completo.
- Note: niente selettore card/tabella nella prima versione. La possibilità di aggiungere card viene rimandata.

## 11. I filtri attuali vengono conservati?

**Domanda:** la futura vista Node mantiene i filtri per ambito, area, paradigma, professionista, luogo e tipologia?

Opzioni:

1. Conservare tutti i filtri.
2. Ridurre i filtri visibili e mettere gli altri in “Filtri avanzati”.
3. Rimandare i filtri a una fase successiva.

**Raccomandazione:** conservarli nei dati, ma semplificare l'interfaccia iniziale con filtri avanzati richiudibili.

- [x] Decisione approvata
- Scelta: filtri rimandati a una fase successiva.
- Note: i dati necessari ai filtri vengono comunque importati in `NodeContent.data`, così potranno essere ripristinati e riprogettati senza perdere informazioni.

## 12. Come entra il catalogo nella Node Show componibile?

**Domanda:** quale blocco riutilizzabile della Node Show deve mostrare una raccolta numerosa di figli?

Possibile struttura:

```text
Node Show
├─ hero
├─ introduzione
├─ rete radiale sintetica
├─ raccolta figli (card o tabella)
├─ corsi e collegamenti
└─ call to action
```

Da decidere:

- nome e responsabilità del partial;
- configurazione tramite `view_type` o dati del contenuto;
- comportamento quando il Node non ha figli;
- riuso dello stesso partial per raccolte diverse dalle metodiche.

In termini semplici, questa decisione non riguarda i dati delle metodiche ma il pezzo grafico della futura Node Show. Bisogna decidere se creare un partial generico, per esempio `_children_table`, capace di mostrare i figli di qualsiasi Node, oppure un partial costruito solo per le metodiche.

**Raccomandazione:** partial generico `_children_table`, attivato soltanto quando il Node possiede figli o quando il riquadro `Altri +N` viene aperto.

- [x] Decisione approvata
- Scelta: partial generico `_children_table` per la tabella dei figli.
- Note: il componente sarà riutilizzabile anche per corsi, capitoli e altre raccolte; verrà implementato dopo la migrazione dei Node.

## 13. Quali elementi diventano Node e quali restano attributi?

**Domanda:** fondatori, scuole, professionisti, paradigmi, aree e tipologie devono diventare Node oppure restare classificazioni?

**Raccomandazione iniziale:** le metodiche diventano Node; paradigmi, aree e tipologie rimangono attributi. Scuole e professionisti potranno essere collegati come Node soltanto se possiedono una propria identità pubblica.

- [x] Decisione approvata
- Scelta: per ora diventano Node soltanto le nove metodiche.
- Note: paradigmi, aree e tipologie rimangono attributi. Scuole e professionisti diventeranno o verranno collegati come Node soltanto se possiedono una propria identità pubblica.

## 14. Pubblicazione e permessi

**Domanda:** tutte le metodiche importate diventano subito `published/public`?

Opzioni:

1. Tutte pubbliche perché le schede sono già pubbliche.
2. Importazione in bozza e pubblicazione dopo revisione.
3. Stato derivato dalla scheda YAML.

**Raccomandazione:** importazione pubblica per le schede già visibili, introducendo successivamente uno stato esplicito nel catalogo.

- [x] Decisione approvata
- Scelta: tutte le nove metodiche vengono importate come `published/public`.
- Note: le schede sono già pubbliche; eventuali nuovi inserimenti futuri potranno partire come bozza.

## 15. Strategia di migrazione

**Domanda:** come procediamo senza interrompere la pagina esistente?

Proposta in fasi:

1. Creare i Node e verificarne gerarchia, slug e visibilità.
2. Collegare ogni scheda esistente al rispettivo Node.
3. Aggiungere un primo Node Link pilota verso un corso.
4. Implementare il limite dei figli nel grafico.
5. Integrare card/tabella nella Node Show.
6. Rimuovere eventuali implementazioni duplicate solo dopo la verifica.

- [x] Decisione approvata
- Scelta: procedere per fasi, completando la ristrutturazione di PosturaCorretta prima del deploy.
- Note: nessuna implementazione duplicata viene rimossa finché importazione, collegamenti, URL e SEO non sono stati verificati.

---

## Decisioni ancora aperte

1. **Decisione 3:** URL canonici, redirect e SEO delle schede metodica.

Prima di affrontarla si può procedere con l'importazione iniziale dei nove Node, perché URL e SEO possono essere risolti senza cambiare la gerarchia e i dati importati.

## Avanzamento implementazione

- [x] Creati i nove Node metodica sotto `metodiche-posturali`.
- [x] Importati titoli, descrizioni, proprietà strutturate e contenuti Markdown.
- [x] Salvata la provenienza dei contenuti tramite `source_path` e checksum.
- [x] Impostati ordine, colori, `view_type: methodology` e visibilità `published/public`.
- [x] Sincronizzato e verificato il database locale.
- [ ] URL, redirect e SEO.
- [x] Presentazioni educative e collegamenti ai corsi per le sei metodiche che possiedono già un assaggio didattico corrispondente.
- [ ] Presentazioni educative per Mézières, RPG e Metodo Souchard, quando saranno disponibili corsi realmente collegabili.
- [ ] Limite dei figli e riquadro `Altri +N`.
- [ ] Partial generico `_children_table`.

