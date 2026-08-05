# PosturaCorretta · anagrafica unica di professionisti e luoghi

## Obiettivo

Per ora **PosturaCorretta** gestisce in modo autonomo professionisti, insegnanti, scuole, centri e luoghi. Impegno e GeneraImpresa restano fuori da questa prima implementazione.

Ogni persona e ogni luogo deve esistere una sola volta, con uno **slug univoco**. Le sezioni del sito non devono duplicare nome, descrizione, immagine, contatti o indirizzo: devono soltanto creare un collegamento alla rispettiva anagrafica e aggiungere il ruolo svolto in quel contesto.

## Stato attuale

La prima anagrafica è già attiva in:

```text
config/data/posturacorretta/posturacorretta_professionisti.yml
```

Contiene per ora Giovanni Damiata e Marco Belleri. La pagina **Percorsi sul territorio → Professionisti** e il filtro dei contenuti la leggono come integrazione provvisoria ai record database.

Il vecchio file `config/data/posturacorretta/professionisti/professionisti.yml` contiene dati storici/di esempio e non deve ricevere nuovi inserimenti: verrà archiviato solo dopo la migrazione completa.

## File anagrafici

```text
config/data/posturacorretta/posturacorretta_professionisti.yml
config/data/posturacorretta/posturacorretta_location.yml
```

### Professionista

Campi minimi:

```yml
- slug: giovanni-damiata
  name: "Dott. …"
  type: professional # professional, teacher, school, organizer
  professions: [medico]
  methodologies: []
  image: ""
  short_description: ""
  website_url: ""
  social_links: {}
  public: false
```

Uno stesso record può avere più ruoli: per esempio una persona può essere professionista, insegnante dell'Accademia e conduttore di un evento. Il ruolo pubblico viene dichiarato nel collegamento alla sezione, non duplicando la persona.

### Luogo

Campi minimi:

```yml
- slug: studio-calvisano
  name: "Studio …"
  type: studio # studio, centro, associazione, natura, location-evento
  address: ""
  city: Calvisano
  province: BS
  country: IT
  latitude:
  longitude:
  image: ""
  website_url: ""
  social_links: {}
  public: false
```

Le coordinate sono facoltative, ma utili per ricerca territoriale, eventi e indicazioni stradali.

## Collegamenti per sezione

Ogni sezione conserva un file piccolo con soli riferimenti e informazioni contestuali.

```text
config/data/posturacorretta/collegamenti/percorso.yml
config/data/posturacorretta/collegamenti/accademia.yml
config/data/posturacorretta/collegamenti/contenuti.yml
config/data/posturacorretta/collegamenti/metodiche.yml
config/data/posturacorretta/collegamenti/eventi.yml
config/data/posturacorretta/collegamenti/collabora.yml
```

Esempio:

```yml
- section: eventi
  target_slug: lago-idro-settembre-2026
  professional_slug: giovanni-damiata
  location_slug: lago-idro
  role: conduttore
  badge: "Conduttore"
  public: true
  order: 1
```

`section` e `target_slug` indicano l'oggetto specifico: un percorso, modulo dell'Accademia, contenuto, metodica, evento o proposta di collaborazione.

## Contributi e spese

Quando servirà indicare chi ha pagato o sostenuto un'attività, non va inserito il dato nel profilo generale della persona. Va usato un collegamento dedicato e non pubblico per impostazione predefinita:

```yml
- target_type: evento
  target_slug: lago-idro-settembre-2026
  contributor_slug: giovanni-damiata
  kind: denaro # denaro, tempo, materiale, spazio
  amount: 120
  currency: EUR
  description: "Noleggio attrezzatura"
  visibility: private
```

Questo permette di distinguere:

- chi partecipa o lavora;
- chi mette a disposizione un luogo;
- chi sostiene una spesa;
- cosa è visibile nella card pubblica e cosa resta gestionale.

## Ordine di implementazione

1. Completare il file delle location dopo aver ricevuto le sedi corrette.
2. Migrare gradualmente le schede ripetute di professionisti e location, senza cambiare subito tutte le pagine.
3. Creare i file di collegamento anche per Accademia, Metodiche, Eventi e Collabora.
4. Rendere tutte le card e i filtri del sito lettori dell'anagrafica unica.
5. Solo dopo aggiungere contributi, spese e autorizzazioni di visibilità.

## Vincoli

- Nessuna dipendenza da Impegno o GeneraImpresa in questa fase.
- Lo slug è stabile: non deve cambiare quando cambia il nome pubblico.
- Informazioni di contatto, siti e social sono pubblicati solo con consenso.
- Il costo o il contributo è un dato del collegamento, non dell'anagrafica della persona.
