# Estrazione di GeneraImpresa

GeneraImpresa è mantenuta separabile da Flowpulse tramite tre confini:

1. il catalogo pubblico vive in `config/data/generaimpresa/brands.yml`;
2. i progetti vengono letti da `GeneraImpresaCatalog`, senza dipendere dalle viste;
3. controller e viste sono isolati nel namespace logico `genera_impresa`.

Quando il catalogo sarà stabile si potrà estrarlo in una nuova applicazione mantenendo gli slug come identificatori. Flowpulse potrà esporre i dati tramite API JSON firmate oppure esportare snapshot YAML/JSON durante il deploy.

Per Cloudflare la soluzione più semplice è mantenere Rails come origine e configurare DNS, TLS e cache degli asset tramite Cloudflare. Una futura versione statica del catalogo potrà essere pubblicata su Cloudflare Pages; le funzioni che modificano progetti, attività e investimenti dovranno invece continuare a usare Flowpulse o un servizio Rails dedicato.
