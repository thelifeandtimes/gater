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
- [ ] Verify the actual Nockmilio contract, deployment/mint coverage and live Ethereum/Base provider behavior. Deferred until the user supplies an RPC endpoint; the example is not a verified bootstrap configuration.
- [ ] Establish Azimuth completeness and an atomic processed chain checkpoint independently of subscription/poll time. The upstream event feed lacks that certificate.
- [ ] Test server-side EAuth expiry, callback replay and deployment reverse-proxy behavior.

Exit: the remaining real-source and deployed authentication checks above pass. Local tests establish the implemented behavior, not production source completeness. Native Iris ingestion is an optional later replacement for the supported external worker.

## Strict reassignment update (2026-10-26)

- [x] Unsigned sibling takeover denied without changing existing claims.
- [x] Linked-ship transfer to an eligible recipient, preserving one-to-one mapping.
- [x] EOA wallet-signed takeover bound to host, collection/NFT, ownership, recipient, revision and five-minute expiry.
- [x] Claim UI controls, malformed-signature/replay tests and two-ship HTTP tests with an independent Ethereum signing library.
- [ ] ERC-1271 contract-wallet adapter and actual browser/hardware-wallet compatibility tests.

## Then: Tlon delivery and observed reconciliation

1. Pin installed `%groups`/`%chat` interfaces; verify the versioned marks and payloads from source in [integrations](integrations.md).
2. Implement the DM adapter with configurable content and the claim link, one recipient per eligible ship, cooldown/deduplication, cancellation of obsolete unsent work, and ambiguous-delivery handling.
3. Implement broad invitation, admission after claim, role addition/removal, pending-invite cancellation and membership removal.
4. Subscribe to group state. Populate managed/applied state only for Gater-owned effects, respect bans/protected members/manual roles, and recheck eligibility just before delivery.
5. Serialize a replacement's removals before its grants. Failed removals must block conflicting grants. Persist retries, receipts and generations; a poke ack does not prove a membership change.
6. Add a live toggle only after those checks pass. Keep preview as the default operational mode.

Exit: two-ship Tlon tests prove invite acceptance, role assignment, authorized reassignment, loss, restarts, retries and protected-member behavior without duplicate messages or leaked roles.

## Generalize and pilot

Support one collection feeding multiple groups, persistent audit history and host diagnostics. Add explicit wallet/delegation and other NFT-standard adapters only after defining their ownership semantics. Run a small consenting pilot with the target group before broader recognition messages.

Needed for the pilot: host URL/ship, group name, dedicated role, installed Tlon revision, RPC endpoints and verified collection bootstrap parameters. Secrets remain private. No product-policy questions block the next implementation step.
