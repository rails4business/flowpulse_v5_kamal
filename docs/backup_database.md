# Backup del database di produzione

Ogni lunedì alle 9:00 il Mac scarica un backup del database di produzione in
`~/Documents/Backups/flowpulse/` e tiene gli ultimi 8 (due mesi).

- Script: `bin/backup_production_db`. Automatizza la procedura fatta a mano il 29 ottobre 2026:
  `ssh` + `pg_dump` nel container `flowpulse_v_5-db`, verifica con `pg_restore --list`, permessi
  `600` e `SHA256SUMS.txt` aggiornato.
- Pianificazione: `config/launchd/net.flowpulse.backup-db.plist`.
- Log: `/tmp/flowpulse-backup-db.log`.

Se il Mac è in stop alle 9:00 il backup parte al risveglio; se è spento quel lunedì, salta alla
settimana dopo.

## Installazione

```bash
chmod +x bin/backup_production_db
bin/backup_production_db          # prova a mano: deve stampare "Backup salvato in ..."
cp config/launchd/net.flowpulse.backup-db.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/net.flowpulse.backup-db.plist
```

## Passare al backup giornaliero

Nel plist togliere la chiave `Weekday` (resta solo `Hour` e `Minute`), portare `KEEP` a 14 nello
script, poi:

```bash
launchctl unload ~/Library/LaunchAgents/net.flowpulse.backup-db.plist
cp config/launchd/net.flowpulse.backup-db.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/net.flowpulse.backup-db.plist
```

## Ripristino

```bash
createdb flowpulse_restore
pg_restore --no-owner --dbname=flowpulse_restore ~/Documents/Backups/flowpulse/<file>.dump
```

## Non compreso

I file caricati (volume `flowpulse_v_5_storage`, `/rails/storage`) non sono nel dump del database.
