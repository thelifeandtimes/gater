# Implementation plan

## Delivered first pass

- [x] Local Git repository and coherent design documents.
- [x] Persistent `%gater` state and pure eligibility/claim reducers.
- [x] Configurable recognition: DM by default, invite all, or none.
- [x] Sibling takeover, revision conflict checks, one-to-one mapping per collection.
- [x] Role/membership loss policy, aggregation and host suppression in the reducer.
- [x] Host-served claim page and configuration UI with EAuth-aware authorization.
- [x] Native optional Azimuth snapshot polling.
- [x] Read-only finalized ERC-721 RPC reader and checkpoint-validated import.
- [x] Action preview and test-pier tooling.

## Next: prove the sources and authentication

1. Exercise a real EAuth handshake between two fake ships, including expiry, endpoint discovery, logout and reverse-proxy headers.
2. Subscribe to Azimuth's ownership-aware `/event` feed; reconcile the initial snapshot without losing events. Establish completeness and processed chain checkpoints independently of poll time. Track ownership generations so a ship sold away and back does not inherit an old claim.
3. Inspect Nockmilio's deployment and mint behavior. Add ERC-2309/constructor-mint or manifest discovery when needed. Prove bootstrap coverage before calling any snapshot complete.
4. Replace full-replay Python polling with a native Iris reader (or a deliberately supported external indexer). Persist cursor and state atomically, back off on rate limits, recover from restarts and reorgs, and invalidate source health on failure. Do not infer ownership loss from provider errors.

Exit: real-source snapshots have explicit coverage/provenance and remote authentication is tested, with replay/restart evidence.

## Then: Tlon delivery and observed reconciliation

1. Pin installed `%groups`/`%chat` interfaces; verify the versioned marks and payloads from source in [integrations](integrations.md).
2. Implement the DM adapter with configurable content and the claim link, one recipient per eligible ship, cooldown/deduplication, cancellation of obsolete unsent work, and ambiguous-delivery handling.
3. Implement broad invitation, admission after claim, role addition/removal, pending-invite cancellation and membership removal.
4. Subscribe to group state. Populate managed/applied state only for Gater-owned effects, respect bans/protected members/manual roles, and recheck eligibility just before delivery.
5. Serialize a replacement's removals before its grants. Failed removals must block conflicting grants. Persist retries, receipts and generations; a poke ack does not prove a membership change.
6. Add a live toggle only after those checks pass. Keep preview as the default operational mode.

Exit: two-ship Tlon tests prove invite acceptance, role assignment, sibling takeover, loss, restarts, retries and protected-member behavior without duplicate messages or leaked roles.

## Generalize and pilot

Support one collection feeding multiple groups, persistent audit history and host diagnostics. Add explicit wallet/delegation and other NFT-standard adapters only after defining their ownership semantics. Run a small consenting pilot with the target group before broader recognition messages.

Needed for the pilot: host URL/ship, group name, dedicated role, installed Tlon revision, RPC endpoints and verified collection bootstrap parameters. Secrets remain private. No product-policy questions block the next implementation step.
