# Brief lavoro autonomo — auto-20260629-9087ee

_Direttiva iniziale: Stabilizzare e rifinire in autonomia il giro chat di Wevo: backend reale, frontend reale, UI chat premium e iterativa, niente mock chat salvo autoresponse OK per utenti mock, branch separato senza toccare main._

## Obiettivo
Portare la chat di Wevo a uno stato stabile e credibile sia lato prodotto che lato implementazione: flusso reale con Firebase, niente chat fake legacy, UI curata e distintiva.

## Scope
- stabilizzare backend chat reale
- collegare frontend a dati veri per discover, matches e chat detail
- utenti mock consentiti solo come destinatari speciali con auto-risposta `OK`
- migliorare la UI chat con iterazioni di qualità, senza look SaaS generico
- usare branch separato e non toccare `main`

## Direzione visiva
- premium, sociale, intima, con presenza viva
- moderna ma non fredda
- carattere forte, dettagli minuziosi, micro-gerarchie, profondità morbida
- evitare cyberpunk rumoroso o glassmorphism gratuito

## Done
- chat reale funzionante per utenti registrati
- rules/backend più sicuri del prima
- UI chat nettamente migliore e più memorabile
- build web ok
- checkpoint e commit sul branch dedicato

