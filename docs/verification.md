# Verification record

Verified on 2026-10-25 with Vere 4.6 and kernel `%zuse 408`, using a disposable local fake ship.

| Check | Result |
| --- | --- |
| Complete Gall desk compilation | Pass |
| Fresh desk bootstrap via the documented loader | Pass |
| Hoon policy scenarios | 18 passed |
| Hoon HTTP/input/checkpoint scenarios | 32 passed |
| Python RPC-reader scenarios | 16 passed |
| JavaScript syntax | Pass |
| JSON examples and local documentation links | Pass |
| HTTP smoke: public landing, login redirect, protected pages/scripts/APIs, exact routing, separate views/action allowlists, host login, CSRF, claim, actor binding, revision conflict, outbox, restoration | Pass |
| Gall save/load through suspend/revive | Saved revision and associations preserved |
| Browser | Separate public landing, authenticated claim page, host configuration, collection editing controls and preserved collection link verified; prior claim/persistence checks also passed |

No messages or Tlon membership/role changes were delivered. RPC tests use a deterministic provider fixture; there was no live Infura/Base scan. Remote EAuth identity handling has unit coverage, but a real two-ship handshake has not been exercised. Gall save/load was checked; a full process restart with pending network operations remains future work.

See [acceptance checks](acceptance-tests.md) for the remaining production gates. The tested UI uses invented ownership fixtures, not actual Nockmilio holdings.
