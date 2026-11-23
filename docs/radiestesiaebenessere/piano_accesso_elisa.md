# Piano: accesso di Elisa a generaimpresa.it, ruolo creator e node

Obiettivo: Elisa entra su generaimpresa.it con il suo account, vede il suo profilo,
ha il ruolo **creator** e il node **Radioestesia e Benessere** risulta suo.
In un secondo tempo avrà un pannello con le cose da aggiornare e il changelog
(oggi visibili solo al superadmin nella home del Brand).

Si procede un punto alla volta, verificando ognuno prima del successivo.

## Situazione attuale (verificata in sviluppo il 23/11/2026)

- La registrazione è **solo su invito**: `UsersController#create` rifiuta chi non ha
  un `BrandInvitation` valido; l'email deve coincidere con quella invitata.
- L'invito si genera dal pannello del Brand: `generaimpresa.it/generaimpresa/admin/requests`,
  pulsante "Approva e genera invito" su una richiesta di accesso. Il link vale 7 giorni
  e va inviato a mano.
- `generaimpresa.it` è il dominio primario del Brand `generaimpresa`.
- Il profilo esiste già: `/profile` (`ProfilesController#show`).
- Ruolo **creator**: esiste (`RoleAssignment` e `User#active_role`), ma nessuno lo ha ancora.
  Deve avere come parent un ruolo **ideatore** (oggi solo Mark Postura).
  La pagina admin dei ruoli assegna solo ideatore e operatori: per creator manca l'interfaccia.
- Node `radioestesia`: tipo professional, figlio di `brand-in-costruzione`, intestato
  all'ideatore Mark Postura, nessun profilo professionale collegato.
  `Node#administered_by?` dà accesso anche al **profilo professionale principale**
  (`Profile#primary_node`) di un node professional.
- Non esiste ancora un utente per Elisa.

## Punti

1. **Accesso.** Confermare l'email di Elisa (domanda 1 della mail).
   Creare la richiesta di accesso su generaimpresa.it, approvarla dal pannello
   `generaimpresa/admin/requests`, inviarle il link; lei crea l'account.
   Prima verificare in sviluppo che il giro funzioni su generaimpresa.
2. **Pannello profilo.** Dopo il primo accesso verificare cosa vede su `/profile`
   e dove arriva (oggi `auth_default_path` di generaimpresa.it è vuoto → home).
3. **Ruolo creator.** Assegnarle un `RoleAssignment` creator con parent l'ideatore
   Mark Postura. Decidere se farlo una tantum (script) o aggiungere creator
   alla pagina admin dei ruoli.
4. **Intestarle i node.** Proposta: collegare il suo profilo come profilo professionale
   principale del node `radioestesia` (`primary_node`): lo amministra senza spostare
   la proprietà. Trasferire la proprietà vera (`role_assignment`) richiede di togliere
   il node da `brand-in-costruzione`, perché un figlio deve avere lo stesso proprietario
   del padre: da valutare più avanti.
5. **(Secondo tempo) Pannello per Elisa** con cose da fare, domande, proposta prezzi,
   ore e changelog, visibile a lei come amministratrice del node.
