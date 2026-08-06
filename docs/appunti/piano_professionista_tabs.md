# Piano: Riorganizzazione della pagina Professionista

## Obiettivo
Passare da una pagina a scorrimento lungo a una pagina a TAB per l'hub del professionista, definendo chiaramente quali sezioni e informazioni devono essere visibili.

## Struttura delle TAB proposte

### 1. Info Personali & Sedi (Tab predefinita)
*Cosa contiene:*
- Biografia, contatti e città.
- **Classificazione:** Area (es. Salute, Prevenzione), Ambito (es. Verde, Rosso, Blu) e Paradigma.
- **Sedi in cui opera:** Elenco delle Location fisiche in cui il professionista è attivo.

### 2. Servizi e Programmi (ex Percorsi)
*Cosa contiene:*
- I pacchetti e i servizi offerti dal professionista.
- **Raggruppamento:** I servizi verranno raggruppati visivamente in base alla Sede (Location) in cui vengono erogati (poiché non tutti i servizi sono disponibili in tutte le sedi).

### 3. Accademia
*Cosa contiene:*
- Mostrare l'abilitazione del professionista.
- Moduli in cui insegna o è educatore.

### 4. Contenuti
*Cosa contiene:*
- Video YouTube, articoli o altri contenuti multimediali in cui è presente.

### 5. Metodiche
*Cosa contiene:*
- Percorso di studi.
- Eventuali metodiche di cui è referente.

### 6. Eventi
*Cosa contiene:*
- Calendario degli eventi (passati e futuri) a cui partecipa.

### 7. Collabora (Solo Superadmin 🔒)
*Cosa contiene:*
- Sezione nascosta al pubblico, visibile solo all'admin.
- Accordi, contributi (denaro/tempo/spazio) e note gestionali.

---

## Appunti sui Dati e Nomenclatura (Da rivedere in un secondo momento)
- Aggiungere `area`, `ambito` e `paradigma` in `posturacorretta_professionisti.yml`.
- Compilare `location_slug` per legare i servizi ai luoghi fisici.
- Valutare se rinominare il file `collegamenti/percorso.yml` in `ambiti_e_programmi.yml` (per gli standard) e creare `servizi.yml` (per le specializzazioni offerte dal professionista, che si sommano per creare il percorso). *[Nota: per evitare errori, questa parte di rinominazione file verrà affrontata dopo aver sistemato l'interfaccia visiva, valutando e creando un nuovo piano di lavoro per questo obiettivo ].*
