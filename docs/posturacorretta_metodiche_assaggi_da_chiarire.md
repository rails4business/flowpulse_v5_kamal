# Metodiche e assaggi PosturaCorretta

## Decisione implementata

Il percorso educativo contiene questi corsi, in sequenza:

1. La prima settimana con PosturaCorretta
2. Igiene Posturale
3. Primo incontro con la Fisioterapia
4. Primo incontro con la GDS
5. Primo incontro con l’Osteopatia
6. Primo incontro con Corpo e Coscienza
7. Primo incontro con la Kinesiologia Applicata
8. Altre metodiche posturali

`La prima settimana con PosturaCorretta` e `Igiene Posturale` non rappresentano
l’assaggio di una singola metodica e quindi non hanno un ponte verso il catalogo.

## Ponti tra corsi e metodiche

I quattro corsi introduttivi sono collegati ai rispettivi Node canonici mediante
Node tecnici nascosti di tipo `access_bridge`:

```text
Primo incontro con la Fisioterapia   ⇄ Fisioterapia
Primo incontro con la GDS            ⇄ GDS
Primo incontro con l’Osteopatia      ⇄ Osteopatia
Primo incontro con Corpo e Coscienza ⇄ Corpo e Coscienza
Primo incontro con la Kinesiologia Applicata ⇄ Kinesiologia Applicata
```

Nel grafico sono visibili soltanto le due estremità reali; non esistono Node
visibili duplicati chiamati `Conosci … con PosturaCorretta`.

## Altre metodiche posturali

`Altre metodiche posturali` è il corso conclusivo del percorso educativo. È
collegato al contenitore canonico `Metodiche posturali`, non alle singole
metodiche Feldenkrais, Alexander o Kinesiologia Applicata.

Non esistono nel percorso educativo:

- `Programma · Altre metodiche posturali`;
- schede figlie Feldenkrais, Alexander o Kinesiologia Applicata;
- una `Sintesi del percorso` separata.

Le metodiche canoniche restano parallele sotto `Metodiche posturali`; il campo
`position` ne determina esclusivamente l’ordine visivo.

## Catalogo canonico

Fisioterapia è stata aggiunta come decima voce canonica. Il test automatico
verifica l’insieme completo dei dieci Node e le relative posizioni.

## Stato

- [x] Titolo `Altre metodiche posturali` ripristinato.
- [x] Livello `Programma · Altre metodiche posturali` eliminato.
- [x] Duplicati visibili `Conosci … con PosturaCorretta` eliminati.
- [x] Cinque ponti corso–metodica nascosti creati.
- [x] Ponte tra `Altre metodiche posturali` e il contenitore creato.
- [x] Fisioterapia aggiunta al catalogo canonico.
- [x] Configurazione, test e database locale aggiornati.

## Prossima decisione

Definire URL e SEO dei Node canonici delle metodiche, stabilendo come le nuove
pagine Node sostituiranno gradualmente le pagine attuali sotto
`/posturacorretta/metodiche` senza perdere URL indicizzati e metadati.
