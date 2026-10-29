# Aggiungere un dominio a FlowPulse

Questa è la procedura unica per pubblicare un nuovo dominio con le protezioni minime di FlowPulse.

## Fonte unica

I domini pubblicati devono essere dichiarati in `config/domains.yml`. Non bisogna più copiare gli hostname in `proxy.hosts` o in `APP_HOSTS`: durante il deploy Kamal ricava automaticamente entrambi gli elenchi dai domini attivi del catalogo.

Un dominio creato soltanto nel pannello superadmin viene salvato nel database, ma non può ancora ricevere automaticamente un certificato TLS. Prima di pubblicarlo, esportarlo o riportarlo in `config/domains.yml` e distribuire la modifica.

## Configurazione minima

Aggiungere il dominio canonico e il relativo alias `www`:

```yaml
nuovodominio.it:
  security_profile: standard
  locale: it
  target_controller: landing
  target_action: nome_pagina
  primary: true
  node_slug: nome-brand
  site_title: "Nome del sito"
  site_description: "Descrizione sintetica del sito."

www.nuovodominio.it:
  canonical_host: nuovodominio.it
```

Il profilo `standard` è il minimo consigliato. Usare `sensitive` per salute, dati personali delicati o moduli che richiedono limiti più severi. Usare `api` soltanto per endpoint API progettati e autenticati come tali. Gli alias ereditano il profilo dal dominio canonico; se un profilo viene omesso, la protezione dei moduli usa comunque `standard` come fallback.

Per tenere il dominio nel catalogo senza pubblicarlo, impostare:

```yaml
active: false
```

I domini inattivi non vengono inseriti nel proxy TLS né in `APP_HOSTS`.

## Prima del deploy

1. Configurare il DNS del dominio canonico verso l'indirizzo del server.
2. Configurare `www` come CNAME del dominio canonico, oppure verso lo stesso indirizzo.
3. Verificare che il Node indicato da `node_slug` esista.
4. Controllare controller, action, titolo, descrizione e profilo di sicurezza.
5. Eseguire `bin/kamal config` per verificare che la configurazione completa venga generata senza errori. Il comando può mostrare anche valori riservati: non copiarne l'output in ticket o messaggi pubblici.

## Deploy e verifica

Eseguire il deploy con la procedura ordinaria:

```bash
bin/kamal deploy
```

L'hook successivo al deploy importa automaticamente il catalogo dei domini nel database. Kamal configura il proxy e richiede il certificato TLS per gli hostname attivi.

Dopo il deploy verificare:

```bash
curl -I https://nuovodominio.it/
curl -I https://www.nuovodominio.it/
```

Il dominio canonico deve rispondere in HTTPS; l'alias `www` deve essere servito oppure reindirizzato al canonico senza errori TLS.

## Moduli pubblici

Se il nuovo dominio introduce un modulo anonimo che modifica dati, non basta il profilo del dominio. Applicare `protect_public_submission`, includere `shared/public_submission_protection` nel form e registrare l'endpoint in `config/public_submissions.yml`. Eseguire poi i test di sicurezza del registro delle route.
