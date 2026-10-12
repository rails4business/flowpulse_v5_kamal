# Aggiornamento autenticazione, accessi, Site e lingue

> **Fonte corrente aggiornata al 12 ottobre 2026.** `BrandAccess` e
> `DomainAccess` sostituiscono rispettivamente `TravelerSubscription` e
> `DomainMembership`. `NodeParticipation` è progettato, ma viene rinviato alla
> fase dedicata a percorsi, ruoli e accessi economici.

## La distinzione essenziale

```text
User + Session     → autenticazione globale
Profile            → identità della persona
BrandAccess        → accesso generale al Brand/Node radice
DomainAccess       → porta linguistica del Brand utilizzata
NodeParticipation  → futura partecipazione a un Node interno
Domain             → indirizzo pubblico
Site               → composizione editoriale e presentazione
```

La metafora operativa è quella della casa:

- l'autenticazione riconosce la persona;
- `BrandAccess` permette di entrare nella casa;
- `DomainAccess` registra quale porta, lingua o presentazione viene usata;
- `NodeParticipation` stabilirà quali stanze, percorsi o attività la persona
  frequenta e a quali condizioni.

## BrandAccess

```text
BrandAccess
├── profile_id
├── brand_node_id
├── source_domain_id
├── status
└── joined_at
```

- La coppia `profile_id + brand_node_id` è unica.
- Il `source_domain` ricorda la porta dalla quale è nato il rapporto.
- Il Node del Domain di provenienza deve coincidere con `brand_node`.
- Domini italiani, inglesi o con presentazioni differenti non producono un
  secondo accesso allo stesso Brand.
- Cancellare il BrandAccess disattiva anche i suoi DomainAccess.

## DomainAccess

```text
DomainAccess
├── profile_id
├── brand_access_id
├── domain_id
├── status
├── activated_at
└── last_accessed_at
```

- Il Domain deve presentare lo stesso Node del BrandAccess.
- La coppia `profile_id + domain_id` è unica.
- Lo stesso BrandAccess può avere più DomainAccess, per esempio italiano e
  inglese.
- Gli alias tecnici come `www` non creano un accesso autonomo.
- Visitare una pagina pubblica non crea alcun record.
- L'accesso nasce o viene riattivato quando la persona entra nell'area del
  Brand o usa una CTA esplicita.

```text
BrandAccess: PosturaCorretta
├── DomainAccess: posturacorretta.org · it
└── DomainAccess: dominio inglese · en
```

## Registrazione e accesso

```text
richiesta
└── Domain
    ├── Site e lingua
    ├── autenticazione globale
    └── BrandAccess
        └── DomainAccess
```

- La registrazione crea `User` e `Profile` una volta sola.
- L'ingresso da un Domain autenticato crea o riattiva BrandAccess e
  DomainAccess.
- La CTA pubblica “Accedi al brand” usa lo stesso flusso.
- Una seconda lingua riutilizza il BrandAccess e aggiunge soltanto il
  DomainAccess mancante.
- Un Domain canonico usato per l'accesso deve essere collegato a un Node.

## NodeParticipation: fase successiva

`NodeParticipation` non viene ancora introdotto. Servirà quando una persona
parteciperà a una parte specifica del Brand:

```text
NodeParticipation
├── profile_id
├── node_id
├── brand_access_id
├── participation_kind
├── access_kind
├── status
├── starts_at
└── ends_at
```

Potrà rappresentare iscrizioni a percorsi o corsi, ruoli di insegnante e
collaboratore e accessi gratuiti, acquistati, in abbonamento o su invito. La
parte economica non appartiene al BrandAccess: il Brand può essere accessibile
gratuitamente mentre un corso interno richiede un acquisto.

Fino a questa fase, il controllo storico che permette a un BrandAccess di
vedere alcuni Node discendenti con visibilità `subscription` viene conservato
per compatibilità. Non è il contratto definitivo.

## Il ruolo di Site e delle Skill

Il Site non possiede utenti, accessi o permessi. Decide **come** un Domain
presenta il Node e le risorse disponibili.

Più Domain e Site possono presentare lo stesso Node. Riconoscono lo stesso
BrandAccess, mentre possono produrre DomainAccess distinti perché sono porte
diverse.

La lingua non può appartenere soltanto al Site: una Skill può produrre
contenuti, corsi, eventi o servizi riutilizzati da più Node e Site. La singola
risorsa deve dichiarare la propria lingua.

```text
Skill
└── SkillProduct / risorsa
    ├── source_locale
    ├── contenuto originale
    └── traduzioni editoriali collegate (facoltative)

Domain.locale + Site
└── scelgono la variante disponibile da presentare
```

## Strategia per le traduzioni

Per l'MVP l'applicazione non traduce automaticamente tutto. Browser e AI
possono aiutare nella lettura, ma quella traduzione non diventa una
pubblicazione editoriale: non ha un canonical controllato, non è verificata e
non entra automaticamente in sitemap, `hreflang`, API o dati strutturati.

1. Ogni Site e risorsa dichiarano la lingua originale.
2. Inizialmente si indicizza soltanto l'originale.
3. Browser e AI possono tradurlo per la lettura personale.
4. Quando un Brand lavora stabilmente in un'altra lingua, crea una traduzione
   editoriale verificata.
5. Solo quella versione riceve URL, canonical, `hreflang`, sitemap e API.
6. L'AI può preparare la bozza; proprietario o produttore ne approvano la
   pubblicazione.

## Stato

- [x] definito `BrandAccess` come accesso unico al Brand/Node;
- [x] definito `DomainAccess` come porta linguistica collegata;
- [x] predisposta la migrazione conservativa dei record esistenti;
- [x] aggiornati registrazione, login, CTA, dashboard e selezione Domain;
- [x] mantenuti stato, date e possibilità di disattivazione;
- [ ] introdurre `NodeParticipation`;
- [ ] sostituire l'ereditarietà provvisoria sui Node `subscription`;
- [ ] definire traduzioni e `source_locale` dei prodotti delle Skill.

