# Autenticazione FlowPulse: User, BrandAccess e Session

## Decisione corrente

L’identità è globale, l’autorizzazione appartiene al Brand e la sessione attiva
è collegata direttamente al relativo `BrandAccess`.

```text
User globale
└── Profile
    └── BrandAccess
        └── Session
```

`DomainAccess` è stato eliminato: hostname e lingua non costituiscono
autorizzazioni personali.

## Responsabilità

- `User`: email, password e stato di verifica dell’identità globale.
- `Profile`: dati della persona condivisi nell’ecosistema.
- `BrandAccess`: autorizzazione della persona a un Brand/Node.
- `Session`: autenticazione attiva, associata a `User` e `BrandAccess`.
- `Domain`: indirizzo tecnico del Brand, canonical e redirect.
- `Site`: presentazione editoriale e variante linguistica.

La `Session` può non avere `brand_access_id` soltanto negli spazi globali di
FlowPulse. Su un dominio di Brand deve corrispondere al Node del dominio:

```text
Session.user == BrandAccess.profile.user
Domain.node == BrandAccess.brand_node
```

Se una condizione non coincide, la sessione viene revocata.

## Registrazione

```text
email + password
→ User pending_email_verification
→ email di verifica
→ User active
→ BrandAccess
→ Session
```

L’accesso non viene creato prima della conferma dell’email. La verifica è
monouso e scade dopo 30 minuti.

## Inviti

`BrandInvitation` contiene email, Brand/Node, autore dell’invito, eventuale
ruolo e scadenza. L’invito pre-autorizza l’accesso al Brand; la persona deve
comunque verificare l’email se sta creando un nuovo User.

## Login successivo

```text
email + password globale
→ controllo BrandAccess
→ nuova Session del Brand
```

La password appartiene allo User, mai al dominio. Resend viene usato per prima
verifica, recupero e controlli di sicurezza, non per ogni login ordinario.

## Domain e Site

Ogni Brand/Node può avere molti record `Domain`, ma un solo dominio canonico
con `primary: true`. Gli altri sono alias e reindirizzano al principale.

Le lingue appartengono ai Site:

```text
brand.example/it/
brand.example/en/
```

Cambiare lingua non crea un accesso né una sessione. Le cartelle editoriali
seguono la convenzione `<node_slug>_<locale>` e possono essere dichiarate nella
mappa `sites` del dominio principale.

## Logout e revoca

- logout: revoca la Session corrente;
- cancellazione del BrandAccess: revoca tutte le Session collegate;
- cambio password: revoca tutte le Session dello User.

## Passi successivi

- la radice linguistica (`/it`, `/en`) è disponibile solo per i Site dichiarati
  nella mappa `sites`; resta da estendere il prefisso alle pagine editoriali
  interne quando verrà aggiunta una seconda lingua reale;
- aggiungere l’approvazione manuale per i Brand che non usano accesso libero o invito;
- valutare in futuro un’autenticazione centrale FlowPulse per passare fra Brand
  differenti senza reinserire la password.
