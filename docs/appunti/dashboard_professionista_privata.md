# Appunti: Dashboard Privata Professionista (PosturaCorretta)

## Obiettivo
Creare un'area privata (Dashboard) riservata ai professionisti dove gestire dati sensibili e funzionalità operative, tra cui la tab "Collabora" (accordi, spese, contributi).

## Logica di Accesso e Sicurezza (Proposta)
- **Metodo di Login:** Login privato (nascosto al pubblico) tramite Email o Numero di Telefono (WhatsApp).
- **Autorizzazione (Role Assignment):**
  - L'accesso sarà governato dal modello `RoleAssignment`.
  - Un utente avrà accesso alla dashboard solo se possiede un `RoleAssignment` con `role: :professional` (o simili).
  - L'assegnazione del ruolo dovrà avere un riferimento (context/domain) al brand specifico (es. `posturacorretta`), in modo che il professionista possa vedere solo le informazioni relative a quel brand.

## Fasi di Sviluppo Future
1. Implementare il sistema di autenticazione via Email/WhatsApp (se non già presente per i profili).
2. Strutturare il collegamento tra il `DirectoryPerson` (il record pubblico) e l'utente reale autenticato (tramite `profile_id` o simile).
3. Gestire l'autorizzazione verificando che l'utente abbia un `RoleAssignment` valido per il dominio `posturacorretta.org`.
4. Spostare la vista `collabora.yml` (e i dati finanziari/amministrativi) all'interno di questa dashboard protetta.
