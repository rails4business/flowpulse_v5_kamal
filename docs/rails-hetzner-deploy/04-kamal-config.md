# 4️⃣ Configurazione Kamal nel progetto Rails

```bash
# In root del progetto
kamal init
```

- Modifica `kamal/config/production.rb`:

```ruby
server "IP_DEL_SERVER", user: "deploy", roles: [:app, :db, :web]
set :repo_url, "git@github.com:tuo-username/tuo-progetto.git"
```
