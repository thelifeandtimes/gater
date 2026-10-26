# Verification record

Verified on 2026-10-25; stricter reassignment retested on 2026-10-26 with Vere 4.6 and kernel `%zuse 408`, using disposable local fake ships `~nec` and `~zod`.

| Check | Result |
| --- | --- |
| Complete Gall desk compilation | Pass |
| Fresh desk bootstrap via the documented loader | Pass |
| Hoon policy scenarios | 19 passed |
| Hoon HTTP/input/checkpoint scenarios | 32 passed |
| Hoon source/migration scenarios | 21 passed |
| Hoon wallet/strict-reassignment scenarios | 26 passed |
| Python indexer/RPC-reader scenarios | 42 passed |
| JavaScript syntax | Pass |
| JSON examples and local documentation links | Pass |
| HTTP smoke: public landing, login redirect, protected pages/scripts/APIs, exact routing, separate views/action allowlists, host login, CSRF, claim, actor binding, revision conflict, outbox, restoration | Pass |
| Gall save/load through suspend/revive | Saved revision and associations preserved |
| Native source integration | Actual `/event` initial snapshot and resumed subscription; proxy-keyed ownership schema verified against installed source |
| NFT import/failure integration | Synthetic coverage-bearing import, claim, source failure pause, recovery and transfer-generation invalidation passed; fixtures restored |
| Real EAuth between fake ships | Ames endpoint discovery, approval, callback/return path, remote identity, protected configuration, unsigned takeover denial, linked-ship transfer, actor binding, restoration, logout and rejected approval passed |
| Wallet HTTP integration | Independent eth-account 0.13.7 signing of a real server challenge; owner signature accepted, wrong signer/actor/token/expiry/replay rejected, linked-ship transfer and restoration passed |
| Browser | Separate public landing, authenticated claim page, host configuration, collection editing controls, source-health panel and preserved collection link verified; linked-ship transfer and exact wallet authorization message/controls also verified |

**140 Hoon/Python scenarios passed**, alongside the integration checks above. No recognition DMs, invitations or Tlon membership/role changes were delivered. EAuth itself exchanged authentication messages between the two local fake ships.

RPC tests use deterministic provider fixtures; synthetic imports are not evidence of real holdings. Live Infura/Base verification is deferred at the user's request until an endpoint is available. Nockmilio deployment and mint coverage remain unverified. Azimuth subscription observations do not prove complete processed chain state. Server-side EAuth expiry, callback replay, reverse-proxy deployment and full pier restart with pending network work remain future checks.

See [acceptance checks](acceptance-tests.md) for the remaining production gates. The tested UI uses invented ownership fixtures, not actual Nockmilio holdings.

Wallet verification uses public test key 1 and no real wallet or chain. The EIP-191 verifier is checked against an independent implementation; an actual browser extension or hardware wallet has not been exercised. Contract-wallet signatures are unsupported pending an ERC-1271 adapter.
