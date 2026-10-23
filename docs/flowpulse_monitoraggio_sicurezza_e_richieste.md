# Flowpulse: monitoraggio, limiti alle richieste e sicurezza

Ultima verifica del repository: 23 ottobre 2026.

## Obiettivo

Proteggere l'ecosistema di domini ospitato sul server Hetzner senza aggiungere un sistema di monitoraggio pesante alla stessa applicazione Rails. La priorità è accorgersi dei problemi prima che il server diventi irraggiungibile, limitare gli abusi più comuni e conservare soltanto i dati realmente utili.

La disponibilità del server e la sicurezza applicativa sono due problemi collegati ma distinti:

- il monitoraggio infrastrutturale indica se CPU, memoria, disco, rete, database o code sono in difficoltà;
- il monitoraggio di sicurezza rileva accessi falliti, autorizzazioni negate, abuso dei form, superamento dei limiti e modifiche amministrative;
- il rate limiting protegge le risorse, ma una risposta HTTP `429 Troppe richieste` non è da sola la prova di un attacco.

## Soluzione minima consigliata

### Controlli esterni gratuiti

1. **UptimeRobot** per raggiungibilità, lentezza, DNS e scadenza SSL dei domini. Il piano gratuito dichiara 50 monitor con controllo ogni 5 minuti: <https://uptimerobot.com/pricing/>.
2. **Grafana Cloud Free** per CPU, memoria, disco, rete e avvisi del server Hetzner. Il piano gratuito dichiara 10.000 serie metriche, 14 giorni di conservazione e tre utenti: <https://grafana.com/products/cloud/free-tier/>.
3. **Healthchecks.io** per verificare che backup e attività periodiche vengano realmente eseguiti. Il piano gratuito dichiara 20 controlli: <https://healthchecks.io/pricing/>.

Configurazione iniziale suggerita:

- UptimeRobot su tutti i domini pubblici e su `/up`;
- Grafana con un solo agente leggero sul server e campionamento ogni 60 secondi;
- Healthchecks.io sul backup del database e sulle attività indispensabili;
- Flowpulse come punto di accesso ai servizi e riepilogo degli allarmi, senza duplicare tutte le metriche.

I piani gratuiti e i loro limiti possono cambiare: ricontrollarli prima dell'attivazione.

## Intervento urgente a tempo minimo

Se non c'è tempo per costruire o gestire una soluzione interna, evitare di aggiungere ora raccolte dettagliate nel database. L'ordine minimo consigliato è questo:

1. **Attivare un monitor esterno sui domini principali.** UptimeRobot non impedisce un picco, ma avvisa rapidamente se il sito diventa lento o irraggiungibile. È il primo passo perché richiede pochi minuti e nessuna modifica al server.
2. **Verificare che al server Hetzner sia applicato un Cloud Firewall.** Le sole porte web `80/443` devono essere pubbliche; SSH deve essere ristretto alle sorgenti necessarie al deploy e PostgreSQL non deve essere pubblico. Il firewall Hetzner è gratuito e blocca il traffico in ingresso non espressamente consentito: <https://docs.hetzner.com/cloud/firewalls/overview/>. Non modificare la regola SSH senza avere verificato da dove parte Kamal, per evitare di perdere l'accesso al server.
3. **Mettere progressivamente i domini dietro Cloudflare Proxy**, iniziando da un solo dominio e verificando login, inviti, form, PWA e certificati prima di estendere la configurazione. Cloudflare dichiara protezione DDoS automatica e senza limiti su tutti i piani, compreso Free: <https://developers.cloudflare.com/ddos-protection/about/>. Le risorse statiche vengono inoltre servite dalla cache edge e quindi non raggiungono sempre Hetzner: <https://developers.cloudflare.com/cache/get-started/>.
4. **Valutare Bot Fight Mode soltanto dopo una prova controllata.** È disponibile sul piano Free, ma non è personalizzabile e può disturbare monitor, integrazioni o client legittimi: <https://developers.cloudflare.com/waf/feature-interoperability/>.

La misura che evita più efficacemente i picchi volumetrici sul piccolo server è Cloudflare davanti all'origine. Il firewall Hetzner riduce l'esposizione delle porte, ma non sostituisce una protezione DDoS HTTP. UptimeRobot segnala il problema, ma non lo blocca.

Non è consigliato introdurre in emergenza un limite globale molto basso dentro Rails: potrebbe bloccare utenti legittimi dietro reti condivise e aggiungere accessi alla cache o al database proprio durante il sovraccarico. I limiti applicativi già presenti devono rimanere concentrati su login, reset, inviti, form pubblici e pagine costose.

### Eventuale pagina Flowpulse

Una futura pagina `Flowpulse → Sicurezza e stato`, visibile solo al superadmin, dovrebbe rimanere semplice e mostrare:

- stato verde, giallo o rosso;
- ultimo controllo esterno riuscito;
- CPU/load, memoria e disco;
- errori `5xx` e risposte `429` recenti per dominio;
- eventi di sicurezza recenti;
- stato dell'ultimo backup;
- collegamenti alle dashboard esterne e una breve procedura d'intervento.

Non dovrebbe registrare ogni richiesta nel database. Gli eventi ripetuti devono essere aggregati e limitati, senza corpi delle richieste, cookie, token, query sensibili, dati sanitari o indirizzi IP completi.

## Protezioni già presenti nel progetto

### Trasporto, dominio e container

- In produzione HTTPS è forzato con `force_ssl` e l'applicazione considera il proxy SSL tramite `assume_ssl`.
- HSTS è configurato anche per i sottodomini.
- `HostAuthorization` usa l'elenco esplicito `APP_HOSTS`; soltanto `/up` è escluso per consentire i controlli di salute.
- Il container di produzione viene eseguito con un utente `rails` non-root.
- Il database è configurato come accessorio interno del deploy e nel file Kamal non viene dichiarata una porta PostgreSQL pubblica. L'effettiva esposizione di rete deve comunque essere verificata sul server.

### Account, sessioni e autorizzazioni

- Le password sono gestite con `has_secure_password` e BCrypt.
- Le registrazioni richiedono un invito personale valido.
- Gli inviti usano token casuali, nel database ne viene conservato il digest SHA-256, scadono dopo sette giorni e sono monouso.
- La sessione è conservata in un cookie firmato, `HttpOnly`, `SameSite=Lax` e `Secure` in produzione.
- Le sessioni possono essere revocate e scadono attualmente dopo 60 giorni.
- Le modifiche della password revocano tutte le sessioni dell'utente.
- L'accesso amministrativo è controllato tramite permessi, ruoli e responsabilità sul Node/Brand.
- Le richieste di accesso sono separate per Brand e l'invito viene generato da un amministratore autorizzato.

### Limiti alle richieste già attivi

- Login: massimo 10 tentativi in 3 minuti.
- Richiesta di reset password: massimo 10 tentativi in 3 minuti.
- Richiesta pubblica di accesso al Brand: massimo 5 invii in 10 minuti.
- Altri form pubblici `BrandRequest`: massimo 5 invii in 10 minuti.
- Le pagine pubbliche più costose di PosturaCorretta (`contenuti` e `metodiche`) hanno due limiti: 24 richieste al minuto per IP e 120 richieste al minuto complessive.
- Quando quei limiti vengono superati viene restituita una pagina `429`, con `Retry-After`, e viene scritto un evento strutturato nel log.
- Per quel monitoraggio l'indirizzo IP viene trasformato in un hash breve; non viene registrato direttamente.
- I form Rails mantengono la protezione CSRF predefinita. L'endpoint tecnico di sincronizzazione la disattiva intenzionalmente perché usa un Bearer token confrontato in tempo costante.

### Segreti, log e controlli sul codice

- Password, email, token, chiavi, OTP e altri parametri sensibili vengono filtrati dai log Rails.
- `RAILS_MASTER_KEY`, password PostgreSQL e token di sincronizzazione sono dichiarati come segreti di deploy e non come valori nel file di configurazione.
- La CI esegue Brakeman, `bundler-audit` e l'audit delle dipendenze JavaScript/importmap.
- Dependabot controlla settimanalmente gemme Ruby e GitHub Actions.

## Protezioni parziali o mancanti

### Priorità alta

1. **Monitoraggio esterno e avvisi:** nel repository non risulta ancora configurato un servizio che avvisi quando il server o un dominio non rispondono.
2. **Firewall e porte Hetzner:** non sono verificabili dal repository. Controllare che siano pubbliche soltanto le porte necessarie e che PostgreSQL non sia raggiungibile da Internet.
3. **Backup e prova di ripristino:** non è presente evidenza sufficiente per confermare frequenza, cifratura, copia esterna e test periodici di restore.
4. **Protezione generale al proxy:** esistono limiti applicativi su alcune azioni, ma non una regola documentata a livello di reverse proxy per connessioni, richieste lente, dimensione del body e picchi generali.
5. **Content Security Policy:** il file di configurazione esiste, ma la policy è commentata e quindi non è attiva. Va prima introdotta in modalità report-only, verificando gli script inline e le risorse esterne, poi applicata gradualmente.

### Priorità media

6. **MFA per superadmin e amministratori:** non risulta implementata. È particolarmente consigliata per chi può amministrare più Brand.
7. **Sessione amministrativa:** 60 giorni è una durata comoda ma ampia per ruoli privilegiati. Valutare una durata più breve o la riautenticazione per operazioni sensibili.
8. **Eventi di sicurezza centralizzati:** vengono registrati alcuni `429`, ma manca una tassonomia comune per login falliti, `403`, `429`, errori `5xx`, modifiche di ruolo, inviti e operazioni superadmin.
9. **Endpoint di sincronizzazione:** il Bearer token è corretto, ma conviene aggiungere un limite di frequenza e un limite esplicito alla dimensione del payload.
10. **Rate limiting al login:** il limite esistente riduce il brute force semplice. Va verificato il comportamento dietro proxy affinché `request.remote_ip` rappresenti davvero il client; è utile anche rilevare attacchi distribuiti su molti IP senza introdurre blocchi account facilmente abusabili.

## Intervento prima del `429`

Il sistema dovrebbe segnalare l'avvicinamento alla soglia prima di iniziare a rifiutare richieste:

- giallo: utilizzo stabile oltre il 70% o crescita anomala;
- arancione: oltre l'85%, aumento dei tempi di risposta o degli errori;
- rosso: oltre il 95%, disco quasi pieno, database saturo o forte crescita dei `5xx`;
- `429`: rifiuto controllato delle sole richieste eccedenti, non blocco indiscriminato dell'intero dominio.

Le soglie iniziali sono orientative. Devono essere adattate dopo aver raccolto una base reale di almeno una o due settimane. Il rate limit va applicato più severamente a login, reset, inviti, upload e form pubblici; le normali pagine informative possono beneficiare soprattutto della cache.

## Ordine operativo consigliato

1. Attivare UptimeRobot sui domini principali e su `/up`.
2. Verificare firewall Hetzner, porte Docker/PostgreSQL e accesso SSH.
3. Verificare backup e completare una prova di ripristino.
4. Installare l'agente leggero per Grafana Cloud e configurare avvisi su memoria, load e disco.
5. Collegare backup e attività periodiche a Healthchecks.io.
6. Applicare limiti al proxy dopo aver osservato il traffico normale.
7. Introdurre CSP inizialmente in report-only.
8. Aggiungere MFA per gli account privilegiati.
9. Solo dopo, creare in Flowpulse un riepilogo degli allarmi esterni e degli eventi applicativi essenziali.

## Riferimenti di sicurezza

- OWASP, Denial of Service Cheat Sheet: <https://cheatsheetseries.owasp.org/cheatsheets/Denial_of_Service_Cheat_Sheet.html>
- OWASP, Logging Cheat Sheet: <https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html>
- NIST SP 800-61 Rev. 3, Incident Response: <https://csrc.nist.gov/pubs/sp/800/61/r3/final>

## Nota sul perimetro dell'audit

Questa verifica riguarda il codice e i file di deploy presenti nel repository. Non dimostra lo stato reale del server Hetzner, del firewall cloud, delle chiavi SSH, dei servizi Docker in esecuzione, dei backup remoti o dei pannelli esterni. Questi elementi richiedono una verifica diretta dell'infrastruttura di produzione.
