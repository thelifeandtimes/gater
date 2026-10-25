# Implementation plan

Build a host-native Gall agent in vertical slices. Finish each phase's exit conditions before enabling the next level of live behavior. The project currently contains planning documents only.

## Phase 0 Prove the interfaces

Use a disposable test group and test ships. Pin kernel/Kelvin, installed Tlon desk revision, action marks, molds, and library dependencies.

1. Confirm the collection's canonical address, chain, verified contract behavior, deployment block, and token discovery method.
2. Read effective ownership for a known L1 point and L2 point. Verify address-to-ships discovery, snapshot completeness, ownership updates, and restart behavior.
3. Establish an ownership checkpoint/freshness protocol for `%azimuth`. If unavailable, specify the separate finalized replay/snapshot adapter before claiming strict finality.
4. Serve a minimal Eyre page. Authenticate a second ship with EAuth, distinguish anonymous/local/remote requests, and test how old sessions behave after an ownership or continuity change.
5. From a test Gall agent on the host, invite a second ship, observe acceptance, add/remove a dedicated role, and revoke an unused invitation. Exercise channel access and protected-member failure cases.
6. Probe Ethereum and Base endpoints for chain ID, log-range limits, historical calls, and finality tags. Measure the collection's bootstrap volume and host memory impact.

**Exit:** reproducible integration fixtures and recorded compatible versions; a demonstrated path for each core operation; no unresolved claim that a source is complete/finalized when it is not. Unsupported hosts remain in dry-run mode with a specific reason.

## Phase 1 Define state and policy

Implement versioned molds and pure reducers for collections, groups, ownership observations, eligibility, claims, invitation suppression, audit entries, and the effect outbox. Enforce both uniqueness indexes and claim revisions in one state transition. Keep configurable policy separate from chain/Tlon transport.

**Exit:** reducer tests prove one-to-one mapping, multi-collection role aggregation, stale-result rejection, ownership-generation invalidation, and idempotent replay.

## Phase 2 Read chain state in dry run

Implement the Azimuth adapter selected in Phase 0 and NFT polling through Iris. Bootstrap from a pinned checkpoint; reconcile logs and owner reads; catch up in bounded batches. Persist progress, source generation, freshness, and index completeness. Add retries, rate limits, canonical-hash checks, and rebuild paths.

The admin view displays eligible ships, projected invites/roles/removals, checkpoint age, and why an operation is blocked. Dry run exercises the full decision path without emitting group changes.

**Exit:** independently checked fixture wallets produce the expected ship/NFT join; restart resumes correctly; partial history, reorgs, and RPC failures cannot produce false grants or mass removals.

## Phase 3 Deliver invitations

Enable the Tlon adapter for invitations only, initially for an allowlisted test cohort. Add pending admission with no NFT role. Deduplicate, rate-limit, respect bans/leaves/manual exclusions, and revoke Gater-owned pending admissions on confirmed loss. Observe actual group state to resolve uncertain results.

**Exit:** one address with several points and one NFT produces the expected invitations, accepting an invitation produces ordinary membership, and no claim role appears automatically.

## Phase 4 Serve claims and assign roles

Build the Eyre member page: authenticated ship, eligible tokens, existing association, claim/release/move controls, and pending/error states. Enforce authorization and CSRF on the backend. Add wallet authorization only as required by the selected conflict policy.

Use a durable transition for remaps: record the new intent, withdraw the old entitlement, confirm applicable old-role removal, activate the new entitlement, then confirm the new role. Handle a member joining or leaving while a claim is in progress.

**Exit:** two ships competing for one NFT cannot both obtain its entitlement; remapping converges after a crash; the browser cannot choose another actor or an arbitrary role; unrelated roles survive.

## Phase 5 Reconcile losses and operator changes

React to NFT transfers/burns, point ownership changes, continuity changes, policy edits, bans, membership changes, and manual managed-role changes. Recompute aggregate entitlements and apply the selected membership-loss policy. Add operator pause, per-group disable, dry-run preview, retry inspection, and explicit protected-member exceptions.

**Exit:** the transfer/sale/outage/manual-change scenarios in [acceptance-tests.md](acceptance-tests.md) pass. Every pending or failed side effect has an observable status and a recovery path.

## Phase 6 Package and pilot

Create the `%gater` desk distribution, `desk.bill`, `sys.kelvin`, marks, dependency pins, install/upgrade instructions, backup/export procedures, and state migrations. Run a small live pilot with the actual collection after reviewing dry-run results. Expand the invite cohort only after confirming real member behavior and RPC cost.

**Exit:** reproducible install on a fresh compatible ship; restart/upgrade/restore tests; documented credentials and provider setup; host-visible health and action audit; successful end-to-end claim and transfer test.

## Intended repository structure

Only the documentation and illustrative configuration currently exist. Add executable files as the associated phase starts:

```text
desk/
  app/gater.hoon                 persistent agent and orchestration
  sur/gater.hoon                 versioned state and action molds
  mar/gater/                    typed actions, responses, and updates
  lib/gater-policy.hoon          eligibility and desired-state reducers
  lib/gater-claims.hoon          claim indexes and transitions
  lib/gater-azimuth.hoon         ownership source adapter
  lib/gater-erc721.hoon          ABI decoding and ownership index
  lib/gater-groups.hoon          versioned Tlon integration
  lib/gater-http.hoon            member and host HTTP routes
  ted/gater/                    bounded RPC work, if threads are used
  gen/gater/                    host setup and diagnostics
  desk.bill
  sys.kelvin
tests/
  fixtures/                     sanitized ownership/group/RPC scenarios
  lib/                          reducer and adapter tests
  integration/                  test-ship scenarios and harness
docs/
config/
```

Use Sail for the initial member interface to avoid requiring a separate service or a large frontend build. A richer static UI can follow without changing authentication or policy. A companion indexer is a fallback only if the measured bootstrap/performance requirements exceed practical ship limits; it must preserve source evidence and explicit trust boundaries.

## Deployment inputs

The first integration run needs a host ship and HTTPS URL, a disposable group flag, its installed Tlon/kernel versions, a non-admin managed role, the canonical NFT contract and start block, and two test identities. Provider access can be supplied locally at that point. The Infura project must allow the required Ethereum and Base methods/networks; validate capabilities instead of assuming the account plan.

The main schedule uncertainty is Phase 0: complete Azimuth ownership with usable provenance, deployed Tlon compatibility, and EAuth session handling. Estimate the remaining work after these spikes rather than treating any of them as solved integrations.
