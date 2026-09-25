# Schede di implementazione centralizzate in Flowpulse

Flowpulse dispone ora di un registro interno per descrivere una modifica prima di scrivere il codice e seguirla fino alla verifica in produzione.

Le schede sono organizzate per Brand responsabile e possono assumere gli stati:

```text
proposta → approvata → in sviluppo → verificata → distribuita
```

È disponibile anche lo stato `in pausa`, senza trasformare l’attesa in una funzione completata.

## Separazione dal changelog

La scheda di implementazione può cambiare mentre il lavoro procede. Il changelog del Brand viene invece scritto soltanto dopo che la funzione è stata realizzata e verificata.

Il registro permette quindi di conservare nello stesso punto:

- problema e obiettivo;
- confini della modifica;
- Brand responsabile;
- model e interfacce coinvolti;
- test e procedura di deploy;
- collegamento al changelog finale.

## Accesso

La pagina `/flowpulse/sviluppo` e i relativi dettagli sono riservati al superadmin. Il link compare nel menu Flowpulse soltanto per chi dispone di questo ruolo.

Le schede restano in YAML e Markdown: non vengono ancora modificate dal browser e non producono automaticamente commit o deploy.
