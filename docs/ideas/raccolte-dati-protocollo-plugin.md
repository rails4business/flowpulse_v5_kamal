# Raccolte di dati con protocollo e plugin

**Progetto:** Rails4Business  
**Stato:** idea da esplorare, non prodotto esistente  
**Data:** 17 novembre 2026

## L’idea in una frase

E se ogni raccolta di dati avesse specifiche chiare e un plugin che permettesse a più applicazioni di consultarla, alimentarla e aggiornarla?

## Il problema

Molte applicazioni raccolgono dati simili in archivi separati. Gli stessi contenuti vengono ricreati, corretti e mantenuti più volte, spesso con formati differenti. Il valore non sta solo nell’applicazione, ma anche nella qualità, nella provenienza e nell’aggiornamento delle informazioni che utilizza.

## La proposta

Non un protocollo unico che descrive qualunque dato, né un database universale. Ogni raccolta tematica definisce il proprio protocollo di dati e mette a disposizione un plugin di integrazione.

Una raccolta comprende:

1. **Dati:** record e risorse conservati in un archivio gestito da un soggetto identificabile.
2. **Specifiche:** schema, campi obbligatori, vocabolario, identificatori, formati, versioni e regole di qualità.
3. **Regole di partecipazione:** chi può leggere, inserire, proporre modifiche, validare o rifiutare contributi.
4. **Interfaccia di scambio:** API documentate e comportamenti prevedibili.
5. **Plugin:** componente integrabile in un’applicazione per utilizzare le funzioni della raccolta.

Il plugin è l’accesso pratico alla raccolta; il protocollo definisce il contratto che il plugin e la raccolta rispettano. Un client non Rails deve poter interoperare tramite le stesse API.

## Due raccolte di esempio

### Esercizi motori

Una raccolta pubblica contiene esercizi con obiettivo, posizione iniziale, istruzioni, varianti, destinatari, precauzioni, media, fonti e versioni. Un professionista propone un esercizio, un altro suggerisce una correzione e un responsabile valida la modifica. Applicazioni di fisioterapia o fitness possono integrare la raccolta rispettando licenze e permessi.

Per le informazioni sulla salute servono revisione professionale, indicazioni di sicurezza e una distinzione esplicita tra contenuti proposti e validati.

### Parcheggi

Una raccolta descrive aree e tratti di strada, gratuità, tariffe, disco orario, fasce temporali, eccezioni, fonti e data di verifica. Le applicazioni consultano i dati e gli utenti possono proporre aggiornamenti documentati, per esempio allegando la fotografia di un cartello.

## Dove conservare i dati

Non è necessario imporre un unico server. Una raccolta può essere ospitata su PostgreSQL/PostGIS, un altro database o un servizio gestito. La compatibilità dipende dal rispetto del protocollo, non dal motore di archiviazione.

Per la prima sperimentazione conviene partire da una raccolta autorevole, con API pubbliche e proposte di modifica moderate. Sincronizzazione e federazione potranno essere valutate in seguito.

## Possibile implementazione con Ruby on Rails 8

- **Server Rails:** raccolte, record, utenti, autorizzazioni, revisioni e audit.
- **PostgreSQL:** persistenza e versionamento; PostGIS per dati geografici.
- **JSON Schema:** descrizione e validazione dei record.
- **OpenAPI:** contratto delle API HTTP.
- **OAuth 2.0 o token limitati:** accesso delle applicazioni quando necessario.
- **Rails Engine o gem:** primo plugin Ruby, affiancato da un client JavaScript.
- **Manifest versionato:** endpoint, schemi, capacità e politiche di contributo.

Sono componenti candidati, non uno standard già definito. Lo standard deve essere documentato indipendentemente dal codice Rails.

## MVP: il primo esperimento

1. Scegliere una sola raccolta, per esempio esercizi motori.
2. Definire uno schema minimo e un manifest leggibile dalle applicazioni.
3. Implementare ricerca, lettura e proposta di record tramite API.
4. Aggiungere approvazione, provenienza e cronologia delle modifiche.
5. Creare un plugin Rails integrabile in una seconda applicazione.
6. Verificare lo stesso scambio con un client non Rails.
7. Pubblicare specifiche, esempi, licenze e criteri di compatibilità.

## Questioni da decidere

- Chi governa una raccolta e nomina i validatori?
- Quali dati sono aperti e quali richiedono autenticazione?
- Come gestire attribuzione, licenze e diritti sui contributi?
- Come identificare univocamente un record tra applicazioni?
- Come trattare modifiche concorrenti, conflitti, duplicati e cancellazioni?
- Come distinguere dato originale, proposta, versione approvata e dato obsoleto?
- Il plugin è solo un client o offre anche interfacce per raccogliere contributi?
- Quali requisiti minimi rendono una raccolta compatibile con lo standard?

## Traccia editoriale Rails4Business

1. **Dai dati alla conoscenza condivisa:** le applicazioni possono aiutare a usare, raccogliere e aggiornare i dati.
2. **Tanti dati, tante applicazioni:** le stesse informazioni vengono replicate in archivi separati.
3. **Raccolte specializzate:** esercizi, parcheggi, sentieri e luoghi hanno regole differenti.
4. **Protocollo e plugin:** la raccolta definisce struttura, accesso e contributi; il plugin permette l’integrazione.
5. **Rails come laboratorio:** API, versioni, autorizzazioni e verifica dei contributi.
6. **Il primo esperimento:** specifiche, una raccolta e un plugin utilizzabile da una seconda applicazione.

## Criterio di successo

La prova non è avere una bella interfaccia. È dimostrare che **due applicazioni indipendenti possono usare e contribuire alla stessa raccolta rispettandone specifiche, autorizzazioni e verifiche**, senza duplicare inutilmente l’archivio.

## Relazione con l’architettura esistente

L’idea sviluppa in forma sperimentale la direzione già descritta nell’audit AI Discovery di Flowpulse: Skill come plugin attivabili e collezioni di risorse esposte attraverso contratti stabili. Rimane però un’idea autonoma perché introduce governance della raccolta, contributi moderati, provenienza, versionamento e interoperabilità verificata tra applicazioni indipendenti.
