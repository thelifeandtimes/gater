# Implementation plan

## Delivered first pass

- [x] Local Git repository and coherent design documents.
- [x] Persistent `%gater` state and pure eligibility/claim reducers.
- [x] Configurable recognition: DM by default, invite all, or none.
- [x] Authorized reassignment, revision conflict checks, one-to-one mapping per collection.
- [x] Role/membership loss policy, aggregation and host suppression in the reducer.
- [x] Separate public entry page, authenticated claim page and host-only configuration UI/APIs with EAuth-aware authorization.
- [x] Native optional Azimuth snapshot polling (superseded by the event subscription below).
- [x] Read-only finalized ERC-721 RPC reader and checkpoint-validated import.
- [x] Action preview and test-pier tooling.

## Source and authentication stage

- [x] Real EAuth handshake between two fake ships: Ames endpoint discovery, approval, return redirect, remote identity, unsigned takeover denial, linked-ship transfer, host-only boundaries, logout and rejected approval.
- [x] Native Azimuth `/event` initial snapshot and ordered ownership updates, plus periodic reconciliation. Select `%own` entries from the installed proxy-keyed index; management/transfer/spawn/vote authority does not qualify.
- [x] Invalidate claims on observed ship ownership changes, NFT transfer-generation changes, index rebuilds and unobserved subscription gaps.
- [x] Supported external indexer with atomic cursor/state/snapshot persistence, restart continuation, range-limit reduction, bounded retries/backoff, explicit source failure and reviewed rebuilds after divergence.
- [x] ERC-721Enumerable bootstrap or reviewed deployment-era Transfer/ERC-2309 bootstrap, checked against totalSupply and ownerOf at a finalized checkpoint.
- [x] State v0→v1 migration, source-health UI, reducer tests, provider simulations and local integration tests.
- [x] Verify Ethereum/Base endpoint access, Nockmilio's deployment block, minimal proxy and mint-event source; supply a reviewed bootstrap configuration.
- [x] Complete Nockmilio's full live ownership replay and restart verification. Request pacing, Retry-After handling and resumable log/owner work address provider throughput limits. See [source checks](nockmilio-verification.md).
- [x] Establish canonical finalized Azimuth history coverage and an atomic processed checkpoint from a pinned Urbit bootstrap, including native L2 replay. The persistent audit worker verifies RPC logs, canonical blocks and rollup inputs; this is bootstrap/RPC trust, not a proof from genesis.
- [ ] Test server-side EAuth expiry, callback replay and deployment reverse-proxy behavior.

The live Nockmilio index and Azimuth audit now pass and resume from persisted checkpoints. The remaining authentication checks concern session expiry and public reverse-proxy deployment. Native Iris ingestion is an optional later replacement for the supported external worker.

## Strict reassignment update (2026-10-26)

- [x] Unsigned sibling takeover denied without changing existing claims.
- [x] Linked-ship transfer to an eligible recipient, preserving one-to-one mapping.
- [x] EOA wallet-signed takeover bound to host, collection/NFT, ownership, recipient, revision and five-minute expiry.
- [x] Claim UI controls, malformed-signature/replay tests and two-ship HTTP tests with an independent Ethereum signing library.
- [ ] ERC-1271 contract-wallet adapter and actual browser/hardware-wallet compatibility tests.

## Tlon delivery and observed reconciliation

A shared adapter compiles against the pinned interfaces and has fake-ship integration coverage for DMs, claim invitations, accepted roles, eligibility loss, voluntary release, broad invitations, pending cancellation, manual-role preservation and Gall ledger reload. Production authorization requires a fresh ownership audit and NFT sources, explicit targets, and exact operation approval or automatic mode. Its persisted ledger separates acknowledgement from observed completion and records which roles it added. The dedicated comet is deployed with delivery paused; its first real invitation is a manual pilot step.


1. Implemented: pinned `%groups`/`%chat` interfaces and versioned marks/payloads, documented in [integrations](integrations.md).
2. Implemented: configurable DM content and collection claim link, recipient deduplication, obsolete-work cancellation and uncertain-delivery handling without blind DM retries.
3. Implemented: broad invitation, admission after claim, role addition/removal, pending cancellation and managed membership removal.
4. Implemented: observed group state, Gater-owned effect tracking, protected members/manual roles and current eligibility checks.
5. Implemented: serialized removals before grants, persisted retries/receipts and observed completion. Broader delayed-message and cold-pier fault injection remains valuable.
6. Implemented: paused/manual/automatic controls, explicit targets, exact approvals and rejected/uncertain result recovery.

Two-ship Tlon tests pass invite acceptance, roles, voluntary release, loss, ledger reload and manual-access preservation. Unit tests cover authorization and retry gates. See [production delivery](production-delivery.md) for the first real invitation walkthrough and remaining operational limits.

## Generalize and pilot

Support one collection feeding multiple groups, persistent audit history and host diagnostics. Add explicit wallet/delegation and other NFT-standard adapters only after defining their ownership semantics. Run a small consenting pilot with the target group before broader recognition messages.

Needed for the pilot: host URL/ship, group name, dedicated role, installed Tlon revision, RPC endpoints and verified collection bootstrap parameters. Secrets remain private. No product-policy questions block the next implementation step.
