# Verification record

## Landscape tile patch 0.2.1 — 2026-10-29 UTC

On disposable fake `~nec` (Vere 4.6 / `%zuse 408`), imported the new Docket mark, library, type and metadata into the existing v0.2.0 desk, compiled Gater, and revived it. Docket automatically registered a ready `%site` charge named Gater, version 0.2.1, targeting `/gater/config`. Browser review confirmed the gate icon and that clicking the tile opens the authenticated host configuration in a new tab.

A separate, empty test desk passed the complete 51-file source import and agent compile. Its decoded Docket noun matched the upgraded desk. HTTP checks confirmed the destination serves the signed-in host and rejects anonymous access. The three bundled Docket dependencies match `urbit/urbit` commit `50c7f5239610fc72263df7aa99b4d171cfe9d408` byte for byte; the tile reuses the existing published v0.2.0 SVG icon at an immutable public URL. No glob is required. The installer passed Python syntax checking.

This patch changes desk metadata, the optional source loader and documentation; it does not change Gall application logic or saved state. No livenet ship was accessed or updated. The broader v0.2.0 verification below remains the application baseline.

## Native RPC release 0.2.0 — 2026-10-29 UTC

The native release compiled on disposable fake `~nec` and a newly installed Gater desk on fake `~zod`, with Vere 4.6 / `%zuse 408`. All 196 Hoon scenarios (including 29 native RPC cases), 89 Python cases and 19 JavaScript cases passed. The source loader now converts `%txt` license/notice files to Clay’s line-list representation; the complete 47-file import and agent compile passed.

Native RPC HTTP integration passed anonymous/member endpoint rejection, invalid endpoint and bootstrap rejection, write-only responses, blank preservation, custom override/fallback, explicit clear and credential persistence across Gall reload. A real EAuth visitor from the other fake ship was refused RPC configuration, bootstrap changes and configuration reads. Existing HTTP claim/auth/CSRF/save-load, source lifecycle/failure/generation and presentation/privacy regressions passed on separate fixture state. Community integration also passed group/initial-chat and role creation, scoped branding, reload and deletion while preserving Tlon objects. Browser review confirmed the password fields, custom endpoint controls, saved-state indicators and scan progress with no console errors.

Real-chain integration uses only the fake ship, a provider key and Urbit’s publicly published bootstrap. The bootstrap matched the reviewed block/hash/digest. Native Iris completed the finalized Ethereum suffix through block 26,299,535, including canonical event-block and rollup-input checks; the audit became verified. No Python NFT/audit worker is used in this test. Native Nockmilio verification reconciled all 1,957 tokens and checked every owner at finalized Base block 53,251,175. Credentials, the source epoch and checkpoint survived Gall reload; saving matching collection coverage preserved that epoch. The next native round advanced Ethereum to 26,299,727 and Base to 53,251,570, with both sources fresh, no errors and the same NFT epoch. The initial scan temporarily outlived audit freshness, correctly pausing eligibility until the next audit completed.

Credentials persist in private Gall state and the pier’s event history; clearing active configuration does not erase old events. No artwork or metadata storage was introduced. No live ship was read or changed during these tests; Tlon delivery was disabled for real-chain integration. Historical bootstrap trust, RPC completeness and reviewed ERC-721 event semantics remain explicit assumptions.

## Public release 0.1.0 — 2026-10-29 UTC

The release desk compiled on disposable fake `~nec` with Vere 4.6 / `%zuse 408`.
All 89 Python cases, 19 JavaScript cases and 167 Hoon scenarios passed. HTTP
claims, authorization, persistence and presentation/privacy integration checks
passed after refreshing the expired fake ownership fixtures. No live ship was
modified during release preparation.

Installer, indexer, importer and auditor support an explicit `--live-ship`
identity, including moon hosts. Unit checks cover exact target propagation,
credential/receipt identity checks, injection rejection and incompatible target
options. Actual control-thread checks on the fake pier rejected both a matching
fake identity and a mismatched live identity. Existing comet-only opt-ins retain
their rank restriction, and development runners remain fake-only. Installation
on the publisher moon is left to its operator.

The publication review inspected all candidate files and all historical Git
blobs for credential patterns; none were found. Piers, local configuration,
runtime checkpoints, backups and screenshots are excluded. The three vendored
ownership libraries match the upstream revision named in the third-party notice.
The release package is built from the committed tree and accompanied by a
SHA-256 checksum.

## Automatic lifecycle and theme inheritance — 2026-10-29 UTC

The `%7` envelope adds per-collection manual approval settings and durable
post-kick notification jobs. The dedicated comet migrated with automatic
delivery enabled, manual approval off for Nockmilio, and the default editable
removal message. Existing collection policy, branding, host settings and Tlon
receipts were preserved. Its queue was empty before and after; this upgrade
sent no live invitations, kicks or DMs.

Passed 171 targeted cases: 81 Python, 19 JavaScript (12 browser-only artwork and
7 appearance), and 71 Hoon (36 actions, 18 community, 17 delivery). HTTP and
presentation integration checks passed, including private settings exclusion
and the retired ship-side media routes.

The two-fake-ship Tlon run confirmed automatic admit → release → revoke → kick
→ custom DM with rejoin URL, remote DM receipt, no duplicate after Gall reload,
manual collection approval, approval refusal while globally paused, NFT-transfer
removal, invite-all recognition, and protection of independent manual roles.
An unrelated queued DM for a nonexistent fixture group exposed head-of-queue
blocking; dispatch now skips unavailable groups while retaining removal barriers
within each group. The full run passed with that fixture still present
(`~nec/gater-1793252676`).

Browser checks covered the empty and linked membership slots, unlinked labels,
selection/confirmation and release, removal of the public host-claims shortcut,
manual-approval and removal-message fields, and editor closure after saving.
A temporary fake `%settings` profile was observed in the actual claim page's
palette and font, then restored. Legacy defaults inherit; custom palettes and
explicit font overrides remain supported. The real hosting comet currently has
no appearance profile, so its general UI uses the Omart/Tend-style fallback.

Artwork remains browser-only. Visual evidence:
`output/linked-membership-review.png` (disposable fake-ship fixture).

## Browser-only artwork update — 2026-10-29 UTC

The `%6` save envelope has no artwork cache. The dedicated comet migrated from
`%5`, preserving collection policy, branding, the pending visitor admission and
paused delivery. The legacy media field is discarded during migration. The bulk
worker and its 641,182-byte JSON cache were removed; its user service was stopped,
disabled and removed. Urbit event history and old backups were not rewritten.

The new browser suite passes **12 cases** covering authenticated holdings only,
contract/token/block binding, URL safety, bounded session caching, expiry,
identity changes, logout cancellation, late replies and RPC failure. All **81
Python cases** pass. The affected Hoon suites pass **36 HTTP/action cases and 18
community cases**. Full agent compilation, HTTP claim/restoration/save-load and
presentation/privacy smoke checks pass. The obsolete metadata/image endpoints
return 404 and the artwork script requires an authenticated ship.

Browser verification loaded only six eligible fake-ship cards directly from
Scatter using one collection-level URL pattern. Header/avatar resolution also
worked directly in the browser; claim and release both succeeded. The screenshot
is `output/browser-only-artwork-review.png`. Nockmilio uses the same pattern on
the comet. Generic public RPC/metadata loading remains subject to CORS and provider
availability, with token-number fallbacks; private Infura credentials are never
published. No real membership action was sent.

After the worker restart, Infura briefly reported finalized Base height 53,228,317
behind the saved 53,228,499 checkpoint while confirming that checkpoint's hash.
The source correctly paused; the next refresh recovered at 53,228,896 without an
index rebuild or claim reset. The audit and ownership sources were fresh at the
final check, and the pending visitor admission remained intact.

## Earlier build — 2026-10-29 UTC

The final suite passes **155 Hoon scenarios and 87 Python scenarios (242 total)**.
The new cases cover claim-scoped concurrency, release while still eligible,
canonical audit coverage/calldata, L2 deposit and transfer-generation replay,
branding migration, exact approval/target/freshness gates, large framed control
responses, and private audit reads. All browser scripts pass syntax checks.

The complete two-fake-ship Tlon run passed invitation and acceptance with a role,
remote DM receipt, ledger reload, voluntary release/removal while still eligible,
reclaim, ownership-loss revocation/kick, invite-all, cancelled pending admission,
and preservation of manual roles/membership. Evidence: `~nec/gater-1793245150`
and its `-invite` group. Transport was disabled afterward.

Final HTTP checks passed the public/private routes, CSRF, member actor binding,
claim restoration and Gall reload. Real EAuth between fake ships passed scoped
return paths, host-only boundaries, release/reclaim, unsigned takeover denial,
logout and rejected login. Logging out the remote EAuth session preserved the
independent host session. Community integration also passed group/initial-chat and role creation, scoped branding, reload and deletion while preserving Tlon objects. Browser review confirmed styled dialogs, editor closure
and success notice, X banner/avatar loading, artwork cards, confirmation and
release. The final card-selection screenshot is `output/claim-cards-review.png`;
its ownership fixtures belong to the disposable fake ship, not the live claimant.

On the dedicated comet, existing collection policy/branding and the pending
visitor admission were preserved. The full initial Ethereum suffix of 3,250
logs, 1,301 distinct blocks and 336 rollup inputs matched canonical RPC history;
the host accepted finalized block **26,295,742**. Trust starts at the explicitly
pinned Urbit bootstrap, not genesis; see [delivery trust](production-delivery.md).
The first cache serialization attempt exposed Python's giant-decimal limit for
rollup calldata; cached input values now use hexadecimal and have a regression
case. The persistent worker then verified block **26,295,806**, saved its cache,
and resumed after a service restart to verify **26,295,838** using that cache.

All **1,956 Nockmilio artworks** and both configured X image URLs were imported.
The presentation smoke passed host `%settings` appearance extraction, full safe
palette handling, private-field exclusion, display-only public metadata,
contract/chain binding and protected audit access.
Source images may be temporarily unavailable and use a token fallback; successful
metadata is cached and missing entries are retried. The comet's anonymous/host
HTTP checks pass, and delivery remains **paused with no live receipts**. No real
invitation, DM, wallet transaction or signature was performed in this update.

## Historical verification


Verified on 2026-10-25; source, authentication and fake-only Tlon delivery retested on 2026-10-26 with Vere 4.6 and kernel `%zuse 408`, using disposable local fake ships `~nec` and `~zod`.

| Check | Result |
| --- | --- |
| Complete Gall desk compilation | Pass |
| Fresh desk bootstrap via the documented loader | Pass |
| Hoon policy scenarios | 19 passed |
| Hoon HTTP/input/checkpoint scenarios | 32 passed |
| Hoon source/migration scenarios | 21 passed |
| Hoon wallet/strict-reassignment scenarios | 26 passed |
| Python indexer/RPC/control-guard scenarios | 56 passed |
| Hoon Tlon wire/protection scenarios | 10 passed |
| Hoon delivery ledger scenarios | 6 passed |
| JavaScript syntax | Pass |
| JSON examples and local documentation links | Pass |
| HTTP smoke: public landing, login redirect, protected pages/scripts/APIs, exact routing, separate views/action allowlists, host login, CSRF, claim, actor binding, revision conflict, outbox, restoration | Pass |
| Gall save/load through suspend/revive | Saved revision and associations preserved |
| Native source integration | Actual `/event` initial snapshot, resumed subscription and explicit `/own/noun` reconciliation; missing Gall mark suffix fixed and regression exercised |
| NFT import/failure integration | Synthetic coverage-bearing import, claim, source failure pause, recovery and transfer-generation invalidation passed; fixtures restored |
| Real EAuth between fake ships | Ames endpoint discovery, approval, callback/return path, remote identity, protected configuration, unsigned takeover denial, linked-ship transfer, actor binding, restoration, logout and rejected approval passed |
| Wallet HTTP integration | Independent eth-account 0.13.7 signing of a real server challenge; owner signature accepted, wrong signer/actor/token/expiry/replay rejected, linked-ship transfer and restoration passed |
| Browser | Separate public landing, authenticated claim page, host configuration, collection editing controls, source-health panel and preserved collection link verified; linked-ship transfer and exact wallet authorization message/controls also verified |

**170 Hoon/Python scenarios passed**, alongside the integration checks above. Actual Tlon integration on the two fake ships passed DM submission and remote receipt, EAuth claim, role-bearing invitation, acceptance, observed role assignment, Gall ledger save/load, NFT-loss role/membership removal, and preservation of existing manual membership/roles. A separate invite-all case passed invitation without claim, cancellation after eligibility loss, reclaim, and preservation of a manual role added after Gater admission. The final evidence group is `~nec/gater-1793048996` plus its `-invite` group. The transport was disabled after testing. No livenet ship or real wallet was touched.

The complete Tlon desk was assembled from commit `e599fabcf4f715cfda67f73439c2e0871189bee1` and committed on the two fake piers; runtime diagnostics confirmed `commit e599fab`. Gater's complete agent and both new reachable libraries compiled on kernel 408. The current save envelope loads legacy state and persists the delivery ledger. Transport is restricted by the runtime fake flag and an explicit recipient allowlist. `live:true` remains rejected.

RPC unit tests use deterministic provider fixtures; synthetic imports are not evidence of real holdings. Live Ethereum/Base access, Nockmilio's deployment, proxy runtime and mint-event source were checked on 2026-10-26. Its full replay verified all 1,938 owners and a subsequent incremental process advanced the checkpoint with the same epoch. Real interrupted-work resumption was also exercised. See [live source checks](nockmilio-verification.md). Azimuth subscription observations do not prove complete processed chain state. Server-side EAuth expiry, callback replay, reverse-proxy deployment and full pier restart with pending network work remain future checks.

See [acceptance checks](acceptance-tests.md) for the remaining production gates. The tested UI uses invented ownership fixtures, not actual Nockmilio holdings.

Wallet verification uses public test key 1 and no real wallet or chain. The EIP-191 verifier is checked against an independent implementation; an actual browser extension or hardware wallet has not been exercised. Contract-wallet signatures are unsupported pending an ERC-1271 adapter.

RPC credential handling was retested on 2026-10-26: credential-redaction checks remain included in the 56 passing Python scenarios. Malformed endpoints are rejected before making requests, and HTTP-client errors omit credential-bearing URLs and their original exception chains. Regression checks cover carriage returns, tabs, invalid ports/hosts and HTTP-client failures. The corrected shared credential successfully authenticated on both networks.


## Dedicated livenet comet deployment (2026-10-28)

The separately created comet `~silzod-wacmer-tarper-ladtyl--disted-waclyr-natfur-litzod`
compiled and activated the desk. Deployment and RPC-import tooling now require
an explicit exact comet identity for live access; their guard checks rank and
runtime non-fake status in the same thread as the requested operation. Existing
smoke runners retain the original fake-only control function. On the real comet,
that function rejected access and a mismatched live identity was also rejected.
The Python suite now passes 67 scenarios. Six additional Hoon recognition cases
use 150,000 ship owners and 2,000 NFTs and cover all recognition actions,
collection isolation, zero addresses, comet exclusion and suppression. The full
Hoon suite totals 120 cases. Recognition now matches against a per-collection
holder-address set rather than scanning every NFT for every ship.

Anonymous public-page access, configuration/script/API denial, the claim login
redirect, comet host login and access to protected pages passed. A clean service
restart retained collection configuration and restored native Azimuth observation;
the HTTP checks passed again. The native watcher advanced to current mainnet
heights after initial catch-up; this observation does not supply the missing
processed-chain finality proof.

The deployment uses local user services and loopback HTTP port 8192. Recognition
is `none` for the Nockmilio pilot and both production delivery and fake-only
transport remain disabled. Real claimant EAuth and wallet signing are manual
checks. [Pilot instructions and the initial Vere runtime crash](comet-pilot.md)
record access, operation, recovery evidence and remaining limits.

The fresh Nockmilio audit verified 1,956 owners. A complete snapshot was accepted
by the comet at finalized Base block 53,219,684, reporting healthy/fresh source
state and disabled transport. Large control requests revealed Vere 4.6 encoder
pipe output truncated at 64 KB. The control client now uses private temporary
files and verifies frame length before opening the socket. Snapshot delivery
uses authenticated loopback Eyre with same-origin headers, runtime ship guards
and a temporary session, avoiding large JSON Hoon compilation. The current
snapshot HTTP limit is 2 MB.


The continuous worker advanced the live host to finalized Base block 53,219,895
with 1,956 tokens. A subsequent clean comet/service restart retained the real
imported state and fresh source health, and the host HTTP checks passed again.
The fake-pier source integration also passed using the new HTTP snapshot path;
the fake pier started for these regression checks was stopped afterward.

## EAuth browser redirect repair (2026-10-28)

The public login page originally returned `form-action 'self'`. Eyre accepted
the login POST and returned a 303 to the claimant's other origin, which the
browser blocked under that document's CSP. The live visitor request discovered an HTTP EAuth endpoint; its destination
subsequently upgrades to HTTPS. HTTP-only EAuth tests did not enforce CSP and missed this failure.

Only `/web/index/html` now permits `form-action 'self' http: https:` to support
discovered ship endpoints. Claim/configuration pages retain same-origin forms,
and all existing script, style, framing and base restrictions remain in place.
The complete desk compiled on the fake host and dedicated comet. All 34 Hoon
HTTP/input scenarios passed, including the two new policy-scope checks. The HTTP
smoke passed with actual response-header assertions, and the full two-fake-ship
EAuth smoke passed approval, identity, access boundaries, claims, logout and
rejection. A real browser reached the fake claimant's login on port 8191.

The fix is active on the dedicated Gater comet. Its anonymous/host access checks
passed. From `http://localhost:8192/gater`, the browser submitted the visitor’s ship name and
successfully reached the visitor’s HTTPS Eyre login displaying their ship name
with the EAuth return path. Verification stopped before entering a real access
key or approving authentication; the live approval/callback remains a user
check. No real claims, wallet signatures or Tlon actions were performed.

## Community editor and collection pages (2026-10-28)

All 135 Hoon scenarios passed: policy 19, HTTP/input 34, source/migration 21,
wallet 26, Tlon 10, delivery 6, recognition scale 6, community 13. The HTTP smoke
passed existing authentication and CSRF boundaries. The two-fake-ship EAuth
smoke now returns to `/gater/demo/claim` and rejects remote creation/deletion
requests. JavaScript syntax and diff whitespace checks passed.

The new community smoke used actual Tlon group/channel/role APIs on `~nec`.
It confirmed exact group slugs, `<id>-chat` registration, roles without admin
permissions, duplicate-name refusal, host/CSRF guards, scoped public and claim
routes, branding validation, `%3` save/load, stale deletion refusal and preserved
Tlon members/roles/channels after collection deletion. Final evidence group:
`~nec/ui-check-1793235701`. Membership transport remained disabled.

Browser checks saved a disposable branded community through the new card/editor
flow, selected a discovered hosted group and role, rendered the example heading
and description with a custom palette, and followed the collection-specific
claim link. That claim page showed only its selected collection. See
[community management](community-ui.md) for behavior and limitations.

The update was compiled and activated on the dedicated comet. Its prior
Nockmilio network/contract, group/role, recognition/loss policies, DM text, host
URL and Azimuth settings compared equal before and after migration. Anonymous
and host page checks passed, and the deployed card/editor rendered in-browser.
The host currently has no Tlon groups; the Nockmilio card labels its old
`nockmilio-preview` binding as needing setup. No real groups, roles or claims
were created or deleted during this deployment.

Post-deployment source verification caught Infura temporarily reporting
finalized block 53,221,803 below the saved checkpoint 53,222,002. The saved hash
still matched a direct block lookup. A subsequent finalized-head lookup returned
53,222,002 again, and restarting only the polling worker produced a healthy,
fresh import at that checkpoint. No index rebuild or finality-check relaxation
was used. Both disposable test ships were stopped after verification.
