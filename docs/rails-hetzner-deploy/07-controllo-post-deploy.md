# 7️⃣ Controllo post-deploy

- Verifica app: https://tuodominio.com
- Visualizza log dei container:

```bash
kamal logs production
```

- Accedi al container Rails:

```bash
kamal ssh production -c web
```
