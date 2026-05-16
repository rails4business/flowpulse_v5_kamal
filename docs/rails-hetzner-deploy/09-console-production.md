# Console production con Kamal

Comandi da lanciare dalla root del progetto.

## Console Rails production

Alias configurato in `config/deploy.yml`:

```bash
bin/kamal console
```

Comando completo equivalente:

```bash
bin/kamal app exec --interactive --reuse "bin/rails console"
```

## Shell nel container app

Alias:

```bash
bin/kamal shell
```

Comando completo:

```bash
bin/kamal app exec --interactive --reuse "bash"
```

## Database console

Alias:

```bash
bin/kamal dbc
```

Comando completo:

```bash
bin/kamal app exec --interactive --reuse "bin/rails dbconsole --include-password"
```

## Log production

Alias:

```bash
bin/kamal logs
```

Comando completo:

```bash
bin/kamal app logs -f
```

## Comandi Rails singoli

Esempi:

```bash
bin/kamal app exec "bin/rails runner 'puts Rails.env'"
bin/kamal app exec "bin/rails db:migrate:status"
bin/kamal app exec "bin/rails routes"
```

## Note

- Gli alias sono definiti in `config/deploy.yml`.
- La console usa l'ambiente production dentro il container deployato.
- Prima di entrare in console, assicurarsi che `~/.kamal/secrets` contenga almeno `RAILS_MASTER_KEY`, `KAMAL_REGISTRY_PASSWORD` e `POSTGRES_PASSWORD`.
- Per uscire dalla console Rails: `exit`.
- Per uscire dalla shell: `exit`.
