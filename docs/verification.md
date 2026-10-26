# Verification record

Verified on 2026-10-25 with Vere 4.6 and kernel `%zuse 408`, using disposable local fake ships `~nec` and `~zod`.

| Check | Result |
| --- | --- |
| Complete Gall desk compilation | Pass |
| Fresh desk bootstrap via the documented loader | Pass |
| Hoon policy scenarios | 18 passed |
| Hoon HTTP/input/checkpoint scenarios | 32 passed |
| Hoon source/migration scenarios | 21 passed |
| Python indexer/RPC-reader scenarios | 42 passed |
| JavaScript syntax | Pass |
| JSON examples and local documentation links | Pass |
| HTTP smoke: public landing, login redirect, protected pages/scripts/APIs, exact routing, separate views/action allowlists, host login, CSRF, claim, actor binding, revision conflict, outbox, restoration | Pass |
| Gall save/load through suspend/revive | Saved revision and associations preserved |
| Native source integration | Actual `/event` initial snapshot and resumed subscription; proxy-keyed ownership schema verified against installed source |
| NFT import/failure integration | Synthetic coverage-bearing import, claim, source failure pause, recovery and transfer-generation invalidation passed; fixtures restored |
| Real EAuth between fake ships | Ames endpoint discovery, approval, callback/return path, remote identity, protected configuration, sibling claim replacement, actor binding, restoration, logout and rejected approval passed |
| Browser | Separate public landing, authenticated claim page, host configuration, collection editing controls, source-health panel and preserved collection link verified; prior claim/persistence checks also passed |

**113 Hoon/Python scenarios passed**, alongside the integration checks above. No recognition DMs, invitations or Tlon membership/role changes were delivered. EAuth itself exchanged authentication messages between the two local fake ships.

RPC tests use deterministic provider fixtures; synthetic imports are not evidence of real holdings. Live Infura/Base verification is deferred at the user's request until an endpoint is available. Nockmilio deployment and mint coverage remain unverified. Azimuth subscription observations do not prove complete processed chain state. Server-side EAuth expiry, callback replay, reverse-proxy deployment and full pier restart with pending network work remain future checks.

See [acceptance checks](acceptance-tests.md) for the remaining production gates. The tested UI uses invented ownership fixtures, not actual Nockmilio holdings.
