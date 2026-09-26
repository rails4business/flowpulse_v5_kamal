# Contribuire a Flowpulse

Le modifiche a dipendenze, CI, deploy e infrastruttura passano attraverso una
pull request e vengono integrate una alla volta.

## Configurazione locale

Installa il hook Git incluso nel repository:

```bash
git config core.hooksPath scripts
chmod +x scripts/pre-push
```

Il file deve chiamarsi esattamente `scripts/pre-push`: questo è il nome cercato
da Git quando viene configurato `core.hooksPath`.

Il hook mostra un promemoria sui push diretti verso `main` e `master`, ma non
li blocca. Non esegue `stash`, `clean`, `reset` e non modifica file locali.

## Flusso di lavoro

1. Per Dependabot e per i file critici lavora in un branch dedicato. Il lavoro
   ordinario del proprietario può continuare sul branch principale.
2. Non usare `git stash` o `git clean` per preparare l'integrazione.
3. Se la cartella principale contiene lavoro non concluso, verifica la pull
   request in una `git worktree` separata.
4. Esegui localmente i controlli con:

   ```bash
   bin/ci_checks
   ```

5. Apri la pull request e attendi che tutti i job siano verdi:
   `scan_ruby`, `scan_js`, `lint`, `test` e `system-test`.
6. Integra una sola pull request alla volta.
7. Dopo il merge aggiorna `main` con `git pull --ff-only`.
8. Lascia che Dependabot aggiorni le altre pull request prima di valutarle.

Gli aggiornamenti major richiedono sempre una verifica dedicata. Non è
previsto alcun auto-merge per le pull request di Dependabot.

## Credenziali e deploy

Non inserire mai nel repository:

- `.kamal/secrets`;
- `config/master.key`;
- password, token o valori estratti dalle Rails encrypted credentials.

Nel progetto `.kamal/secrets` è un file ponte locale: risolve i valori dalle
Rails credentials e li passa a Kamal. Un normale `git pull --ff-only` non lo
elimina.

Le worktree e i nuovi clone non contengono i file ignorati. Per questo motivo
si possono usare per test, lint e build, ma il deploy deve partire soltanto
dalla cartella principale configurata e dopo aver verificato i prerequisiti
locali.

Il deploy resta manuale e separato dal merge della pull request.

## Revisione dei file critici

`CODEOWNERS` richiede la revisione del proprietario per workflow, Dependabot,
deploy, immagine Docker, credenziali cifrate e dipendenze Ruby. La regola viene
applicata effettivamente soltanto se nelle regole del repository GitHub è
attiva la revisione dei Code Owner.

La procedura completa è documentata in
`docs/appunti/DEPENDABOT_E_CREDENZIALI_KAMAL.md`.
