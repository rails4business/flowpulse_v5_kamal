# Piano di allineamento dei Node

Questo documento descrive come allineare il catalogo dei Node alla struttura approvata nel terzo diagramma Mermaid di `public/posturacorretta-flusso-ingresso-percorsi.html`.

Nessuna modifica o cancellazione descritta qui deve essere applicata prima dell'approvazione del piano.

## Obiettivo

Separare chiaramente:

- il metodo e l'ingresso del Percorso Integrato;
- lo Stato di Salute e le fasi del percorso personale;
- la rete territoriale, professionale e formativa;
- il percorso educativo interno a PosturaCorretta.

## 1. Struttura di Percorso Integrato

La struttura approvata è:

```text
Percorso Integrato
├─ Osservazione e metodo scientifico · Paradigmi di scelta della cura
├─ Con chi iniziare
│  ├─ Professionisti della salute · Patologie e sintomi
│  ├─ Professionisti del benessere · Prevenzione e qualità della vita
│  └─ Insegnanti PosturaCorretta · Educazione alla salute
├─ Linee guida per creare un Percorso Integrato
└─ Inizia il Percorso Integrato
```

I quattro Node di primo livello sono fratelli e vengono ordinati tramite `position`.

Node coinvolti:

| Slug | Titolo | Operazione |
|---|---|---|
| `percorso-integrato` | Percorso Integrato | mantenere come Node dominio e contenitore della colonna |
| `paradigmi-scelta-cura` | Osservazione e metodo scientifico · Paradigmi di scelta della cura | mantenere lo slug e aggiornare titolo e descrizione |
| `con-chi-iniziare` | Con chi iniziare | aggiungere come contenitore |
| `professionisti-salute-patologie-sintomi` | Professionisti della salute · Patologie e sintomi | rendere figlio di `con-chi-iniziare` |
| `professionisti-benessere-prevenzione-qualita-vita` | Professionisti del benessere · Prevenzione e qualità della vita | rendere figlio di `con-chi-iniziare` |
| `educazione-alla-salute` | Insegnanti PosturaCorretta · Educazione alla salute | rendere figlio di `con-chi-iniziare` |
| `linee-guida-percorso-integrato` | Linee guida per creare un Percorso Integrato | aggiungere come Node pubblico |
| `inizia-percorso-integrato` | Inizia il Percorso Integrato | mantenere/aggiornare |

## 2. Catena principale di Stato di Salute

La fine della prima colonna entra nella seconda:

```text
Inizia il Percorso Integrato
└─ Stato di Salute
```

La struttura interna approvata è:

```text
Stato di Salute
└─ Questionario di orientamento sullo stato di salute
   └─ Stop al dolore
      └─ Prevenzione e rischi
         └─ Performance e risorse
            └─ Percorso Benessere
               └─ Educazione alla salute con le metodiche posturali
```

Le cinque direzioni formano una progressione ordinata. Il questionario può orientare la persona verso il punto più adatto della sequenza: non implica che tutti debbano iniziare da Stop al dolore. Il questionario non sostituisce diagnosi, valutazioni o indicazioni professionali.

Node coinvolti:

| Slug | Titolo | Operazione |
|---|---|---|
| `stato-di-salute` | Stato di Salute | impostare come figlio di `inizia-percorso-integrato` |
| `questionario-orientamento-stato-di-salute` | Questionario di orientamento sullo stato di salute | aggiungere come figlio di `stato-di-salute` |
| `stop-al-dolore` | Stop al dolore | impostare come figlio del questionario |
| `prevenzione` | Prevenzione e rischi | impostare come figlio di `stop-al-dolore` |
| `performance` | Performance e risorse | impostare come figlio di `prevenzione` |
| `percorso-benessere` | Percorso Benessere | impostare come figlio di `performance` |
| `educazione-alla-salute-metodiche-posturali` | Educazione alla salute con le metodiche posturali | impostare come figlio di `percorso-benessere` |

## 3. Ramo territoriale, professionale e formativo

I quattro ambiti organizzativi sono Node contenitori fratelli:

```text
Stato di Salute
├─ Comuni
├─ Centri
├─ Professioni
└─ Scuole · Formazione professionisti
```

Nuovi Node proposti:

| Slug | Titolo | Tipo iniziale | Funzione |
|---|---|---|---|
| `comuni` | Comuni | `project` | contenitore dei singoli comuni |
| `centri` | Centri | `project` | contenitore dei centri territoriali |
| `professioni` | Professioni | `project` | contenitore delle categorie professionali |
| `scuole-formazione-professionisti` | Scuole · Formazione professionisti | `project` | contenitore di scuole ed enti formativi |

Questi quattro Node:

- saranno pubblici;
- saranno rappresentati nella colonna di Stato di Salute;
- saranno contenitori, non singoli professionisti o singole scuole;
- potranno ricevere figli in seguito;
- non verranno inseriti nella catena personale dal dolore al benessere.

Comuni e Centri restano paralleli perché in futuro potranno avere relazioni molti-a-molti. Nella prima implementazione i quattro contenitori rimarranno vuoti.

I singoli professionisti e le singole scuole potranno essere Node `professional` e verranno gestiti separatamente dalla vista Brand.

## 4. Collegamento con PosturaCorretta

`Postura e fisiologia` possiede già una posizione nella gerarchia interna di PosturaCorretta:

```text
PosturaCorretta
└─ La prima settimana con PosturaCorretta
   └─ Postura e fisiologia
      └─ Postura e consapevolezza
         └─ Il corpo, un mondo da scoprire
```

Per non assegnare due parent allo stesso Node, il passaggio fra le colonne rimane un solo Node Link:

```text
Educazione alla salute con le metodiche posturali
⇢ Postura e fisiologia
```

Il ponte tecnico può continuare a usare lo slug:

```text
accesso-posturacorretta-da-percorso-integrato
```

Il Node ponte non deve apparire come card: il grafico deve mostrare soltanto il collegamento fra origine e destinazione.

## 5. Vecchi ponti da eliminare

I seguenti Node ponte sono incompatibili o ridondanti rispetto alla nuova struttura e vengono proposti per la cancellazione definitiva dal catalogo e dal database:

| Slug | Motivo |
|---|---|
| `accesso-stato-di-salute-da-posturacorretta` | introduce un collegamento diretto non presente nella nuova struttura |
| `accesso-stato-di-salute-da-giardino-del-corpo` | introduce un collegamento diretto non presente nella nuova struttura |
| `accesso-percorso-integrato-da-linea-postura-giardino` | riconnette la vecchia struttura al Percorso Integrato |
| `accesso-posturacorretta-da-prima-settimana` | duplica la gerarchia reale `PosturaCorretta → Prima settimana` |

Prima della cancellazione verrà verificato che:

- nessun altro Node li utilizzi come parent;
- nessun contenuto editoriale dipenda da essi;
- non possiedano domini;
- non siano richiamati da test, menu o configurazioni.

La cancellazione verrà eseguita soltanto sugli slug elencati, senza cancellazioni ricorsive.

## 6. Ponti da conservare

Verranno mantenuti:

- il ponte da `educazione-alla-salute-metodiche-posturali` a `apprendimento-1-espressione`;
- i ponti dalla Prima settimana alle aree previsti nello schema approvato;
- i ponti fra corsi introduttivi e metodiche;
- il ponte fra la landing `igieneposturale.it` e il corso interno Igiene Posturale.

## 7. Colonne e domini

- `percorso-integrato` continua a generare la colonna `percorsointegrato.it`.
- `stato-di-salute` continua a generare la colonna `statodisalute.it`.
- `posturacorretta` continua a generare la colonna `posturacorretta.org`.
- Il dominio può comparire come intestazione della colonna e il relativo Node come card, senza duplicare il record nel database.
- La vista Brand non deve mescolare i singoli Node Professional.

## 8. Ordine di implementazione

1. Verificare gli slug e le dipendenze dei quattro ponti da eliminare.
2. Aggiornare `config/nodes.yml` con la gerarchia approvata.
3. Aggiungere i quattro Node contenitori del ramo organizzativo.
4. Rimuovere dal catalogo YAML i vecchi ponti approvati.
5. Eliminare dal database locale esclusivamente i quattro ponti approvati.
6. Importare nuovamente il catalogo Node.
7. Aggiornare i test del catalogo e della rete.
8. Verificare le viste `all`, `only` e `corsie` in modalità Brand.
9. Controllare che la vista Professional rimanga separata.

## Audit dei ponti da eliminare

Controllo eseguito in sola lettura sul database locale:

- nessuno dei quattro ponti possiede figli;
- nessun altro Node li utilizza come `link_node`;
- non possiedono domini, servizi, processi, eventi, cicli o skill;
- i record Content associati sono vuoti;
- gli unici riferimenti esterni al catalogo YAML sono aspettative nei test, che verranno aggiornate insieme all'implementazione.

La cancellazione puntuale dei quattro ponti risulta quindi sicura rispetto ai dati attualmente presenti.

## 9. Verifiche finali

- La catena principale coincide con il Mermaid.
- I quattro contenitori Comuni, Centri, Professioni e Scuole sono distinti dal percorso personale.
- Nessuna card tecnica `access_bridge` è visibile.
- Non rimangono collegamenti diretti obsoleti.
- Cliccando un Node si mantiene la modalità `all` oppure `only`.
- Il numero di livelli selezionato viene conservato.
- Il catalogo YAML è valido e importabile più volte senza duplicazioni.
- I test Rails interessati terminano senza errori.

## Decisioni approvate

1. Approvata la cancellazione definitiva dei quattro vecchi ponti elencati.
2. Approvato: Comuni, Centri, Professioni e Scuole sono quattro Node contenitori fratelli sotto Stato di Salute.
3. Approvato: il solo ponte verso PosturaCorretta è `Educazione alla salute con le metodiche posturali ⇢ Postura e fisiologia`.
4. Approvato: Stato di Salute è figlio di `inizia-percorso-integrato`, ma rimane un Brand e un container indipendente grazie al proprio dominio.
5. Approvato: i quattro vecchi ponti elencati vengono cancellati definitivamente dopo la verifica delle dipendenze.
