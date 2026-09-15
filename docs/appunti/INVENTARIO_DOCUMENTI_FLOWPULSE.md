# Inventario dei documenti Flowpulse

> Inventario iniziale del 15 settembre 2026. Serve a riordinare senza perdere
> informazioni. `Attivo` indica una fonte decisionale; `supporto` approfondisce
> un ambito; `da rivedere` può contenere parti ancora utili; `storico` non deve
> guidare nuove implementazioni; `prototipo` è un riferimento visuale.

## Fonti attive

| Documento | Ambito | Uso |
| --- | --- | --- |
| `PRINCIPI_FLOWPULSE_E_ORGANIZZAZIONE_SETTIMANALE.md` | Ecosistema | Principi, responsabilità, tre canali, ordine del lavoro e week plan |
| `ARCHITETTURA_CICLI_CONTENUTI_E_SERVIZI.md` | Flowpulse / 1Impegno | Content, DataSession, DataSlot, ruoli; Cycle e Service in standby |
| `REGISTRO_PROGETTI_YML.md` | Flowpulse | Fonte YAML e priorità dei progetti |
| `ROADMAP_PILOTA_POSTURACORRETTA_E_VISTA_OPERATIVA.md` | PosturaCorretta | Sequenza operativa del pilota |
| `vocabolario_impegno_e_brand.md` | 1Impegno | Vocabolario sintetico coerente con l'architettura corrente |

## Documenti di supporto da conservare

| Documento | Brand/ambito | Uso successivo |
| --- | --- | --- |
| `avvio_piattaforma_posturacorretta.md` | PosturaCorretta | Avvio del pilota |
| `piano_posturacorrettastart.md` | PosturaCorretta | Verificare passi ancora aperti |
| `programma_didattico_ruoli_e_partecipazioni.md` | PosturaCorretta | Recuperare formazione e partecipazioni |
| `programma_posturacorretta_in_1_mese.md` | PosturaCorretta | Recuperare struttura editoriale del percorso |
| `posturacorretta_anagrafica_professionisti_luoghi.md` | PosturaCorretta | Professionisti e centri affiliati |
| `posturacorretta_catalogo_contenuti.md` | PosturaCorretta | Catalogo editoriale |
| `posturacorretta_piano_contenuti_collaborativi.md` | PosturaCorretta / Rails4Business | Processo di produzione contenuti |
| `contenuti_trasversali_domini.md` | Tutti i brand | Provenienza, riuso e visibilità dei contenuti |
| `eventi_trasversali_domini.md` | Tutti i brand | Rivedere alla prova delle Session pubbliche |
| `ecosistema_persona_tre_progetti.md` | Ecosistema | Narrazione dei progetti intorno alla persona |
| `FLOWPULSE_INTEGRAZIONE_PROGETTI.md` | Flowpulse | Visione progetti e sovranità; modelli Project rinviati |
| `flowpulse_sovranita_progetti_community.html` | Flowpulse | Documento/prototipo narrativo |
| `dashboard_professionista_privata.md` | Professionisti | Rivedere dopo il pilota Operator |
| `piano_professionista_tabs.md` | Professionisti | Rivedere insieme alla futura area privata |
| `generaimpresa-extraction.md` | GeneraImpresa | Conservare per la successiva riattivazione |

## Documenti storici o superati

| Documento | Motivo |
| --- | --- |
| `data_event_mvp_decisioni.md` | Descrive il precedente DataEvent, rimosso prima dell'uso reale |
| `impegno_eventi_architettura.md` | Architettura precedente; prevalgono DataSession e DataSlot |
| `esperienze_eventi_commitment.md` | Ipotesi storiche da recuperare solo quando si modelleranno le partecipazioni |
| `posturacorretta_refactoring_guide.md` | Verificare rispetto all'interfaccia corrente prima di applicarlo |
| `role_navigation_refactor_plan.md` | Parte del refactoring ruoli è già stata implementata |

Questi file non vanno cancellati ora. Quando una decisione utile viene
recuperata, va trasferita nella fonte attiva appropriata e marcata come già
assorbita.

## Prototipi visuali rilevanti

| Prototipo | Stato e prossimo uso |
| --- | --- |
| `docs/private_prototypes/viste_html/6_weekplan.html` | Base da semplificare per il nuovo week plan generale |
| `docs/private_prototypes/viste_html/orario_ufficiale.html` | Fonte degli orari reali già discussi |
| `docs/private_prototypes/viste_html/0_dataevent_show.html` | Solo riferimento visuale; rinominare i concetti in DataSession/DataSlot |
| `docs/private_prototypes/viste_html/1impegno_official_2026.html` | Interfaccia 1Impegno da semplificare |
| `docs/private_prototypes/viste_html/home_posturacorretta_programma.html` | Programma lezioni PosturaCorretta |
| `docs/private_prototypes/viste_html/flowpulse_sovranita_progetti_community.html` | Visione Flowpulse; Project resta rinviato |

## Destinazione provvisoria dei contenuti

| Provenienza/tema | Brand proprietario |
| --- | --- |
| Rails, software, Flowpulse, processi e collaboratori digitali | Rails4Business |
| Postura, lezioni, schede, formazione e canale YouTube posturale | PosturaCorretta |
| Natura, musica, filosofia, valore, ricchezza e spiritualità | Il Giardino del Corpo |
| Materiale specifico di un professionista esterno | Progetto/brand del professionista |

I collegamenti tra brand non cambiano la proprietà editoriale. Un contenuto si
scrive una volta sola e viene richiamato dagli altri canali.

## Prossima revisione

Prima di spostare materialmente i contenuti occorre aggiungere a ciascun MD
selezionato questi metadati minimi:

```yaml
brand: rails4business | posturacorretta | ilgiardinodelcorpo | altro
status: draft | published | archived
visibility: public | private | superadmin
responsible: mark
published_at:
```

Il formato definitivo sarà provato su pochi contenuti reali prima di una
conversione generale.
