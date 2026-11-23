# Piano: richieste, profili e iscrizioni ai domini

Obiettivo: ogni richiesta arrivata a un dominio resta del dominio anche se chi la manda
non ha un account; quando la persona si registra, la richiesta viene collegata al suo
profilo (e quindi al suo utente). Il proprietario del Brand e il superadmin vedono, per
ogni dominio, sia le richieste sia i profili iscritti.

Si procede un punto alla volta, verificandolo prima del successivo.

## Situazione attuale (23/11/2026)

- `BrandRequest` è sempre legata a `domain` e `brand_node`. La persona è un
  `participant_contact` (contatto con nome ed email, salvato nel profilo del proprietario
  del Brand) se non è loggata, oppure un `requester_profile` se lo è.
- Ogni utente ha sempre il suo profilo (creato insieme all'account): collegare il
  profilo basta per risalire all'utente.
- L'iscrizione al dominio esiste già: `BrandAccess` (profilo, Brand, dominio di
  provenienza, `joined_at`), creata alla registrazione con invito
  (`grant_profile_brand_access_for_node!`).
- Alla registrazione con invito `complete_access_request_for!` chiude la richiesta come
  `accepted` ma **non** le assegna il profilo.
- Nessun collegamento per email tra richieste e utenti; nessuna pagina "Iscritti" nel
  pannello del Brand.
- In sviluppo non ci sono richieste: i dati da collegare sono in produzione.

## Punti

1. **Profilo alla registrazione con invito.** Quando l'invito viene accettato, la
   richiesta collegata riceve `requester_profile` = profilo di chi ha accettato
   (solo se non ne ha già uno), poi viene chiusa come `accepted`.
2. **Collegare le richieste esistenti** con un comando rake, idempotente, con modalità
   prova (stampa senza cambiare nulla) e applica:
   - sicuro: richiesta con invito accettato → profilo di chi l'ha accettato;
   - per email: contatto con la stessa email di un utente con email verificata, o
     registrato con un invito arrivato a quell'email → collegamento automatico;
   - gli altri casi con email uguale finiscono in un elenco da controllare a mano.
   Lo stato delle richieste (aperte o chiuse) non cambia.
3. **Nuove richieste con l'email di un utente esistente.** Nessun collegamento
   automatico (chiunque può scrivere l'email di un altro nel modulo): nel pannello
   compare "corrisponde a un utente registrato" con il pulsante **Collega**.
4. **Pannello del Brand**, per dominio, visibile al proprietario e al superadmin:
   richieste con filtro "senza utente / con utente" e pagina **Iscritti**
   (profili con `BrandAccess`, data di iscrizione, richieste collegate).
