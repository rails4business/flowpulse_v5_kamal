# Step 0008 - Permessi guidati dall'active role

## Obiettivo

Allineare quello che l'utente vede nella sidebar con quello che puo davvero aprire via URL.

La regola centrale e:

```text
role_assignments = quali ruoli puoi attivare
active_role      = cosa puoi vedere e aprire adesso
```

Quindi un utente con piu assegnazioni non deve vedere o raggiungere tutte le aree insieme.
Deve prima attivare il ruolo operativo corretto.

## Problema

Oggi il menu e gia in parte filtrato dal ruolo attivo, ma i controller usano controlli distribuiti:

- `require_admin!`
- `require_superadmin!`
- `require_role!(:creator)`
- controlli custom come `require_admin_user!`
- helper view come `can_access_path?`

Questo puo creare divergenze:

- un link sparisce dalla sidebar ma la pagina resta raggiungibile via URL;
- un utente con ruolo admin assegnato puo entrare in admin anche se sta lavorando come traveler;
- un superadmin puo vedere link non coerenti con il ruolo attivo.

## Decisione

Usare una sola policy per visibilita e accesso.

### Regole

- `traveler`: aree pubbliche/dashboard viaggiatore.
- `demo`: aree demo read-only.
- `creator`: creator world e nodi del creator attivo.
- `teacher`: area teacher.
- `tutor`: area tutor.
- `professional`: area professional.
- `admin`: strumenti admin operativi non superadmin.
- `superadmin`: domini, role map, assigned roles e governo app.

### Superadmin

Il superadmin non vede tutto sempre.

Il superadmin puo attivare `superadmin` e, quando quel ruolo e attivo, accede alle aree di governo.
Se lavora come `traveler`, `creator`, `admin`, ecc. vede e apre solo quell'area.

## Implementazione

1. Aggiungere una policy centrale in `FlowRoles`.
2. Usare la policy in `NavigationHelper` per mostrare/nascondere link.
3. Usare la stessa policy nei controller per bloccare accesso diretto via URL.
4. Eliminare controlli custom duplicati dove possibile.
5. Aggiungere test per:
   - admin assegnato ma active role traveler non entra in admin;
   - admin assegnato con active role admin entra in admin operativo;
   - superadmin con active role traveler non entra in domini;
   - superadmin con active role superadmin entra in domini;
   - sidebar mostra solo link coerenti con active role.

## Stato

Implementato.

Fatto:

- `FlowRoles.can?` usa l'active role come fonte di verita per demo, admin, superadmin e ruoli workspace.
- `require_role!` e `require_permission!` passano dalla policy centrale.
- `Admin::BaseController`, `ResourcesController` e `Demo::BaseController` usano la policy centrale.
- `NavigationHelper` filtra i link con la stessa logica usata dai controller.
- I redirect di accesso negato tornano alla dashboard coerente con il ruolo attivo.
- Test aggiunti/aggiornati per superadmin, admin operativo, traveler e demo mode.
