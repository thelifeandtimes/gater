# Acceptance checks

Automated suites live in `tests/`; see [development](development.md) for commands.

## Executed reducer/input cases

DM-default, invite-all and no-outreach modes; claim before membership; unsigned sibling takeover denial; linked-ship-authorized reassignment; concurrent revision conflict; unrelated wallet rejection; one token per ship per collection; release authority; stale inputs; NFT and ship-owner changes; remove-role-and-membership default; optional membership retention; another collection sustaining the same role; broad-invite eligibility loss; retaining an eligible broad-invite member before claiming; and preserving ships across distinct Azimuth owner addresses.

HTTP/input cases cover host versus remote EAuth-shaped identities, rejecting anonymous comet identities, same-origin guards, host-only configuration, the live-delivery lock, arbitrary collection defaults, malformed/duplicate ownership, empty snapshots, stale RPC snapshots, checkpoint identity/regression, and uint256 imports.

Page separation cases cover public routes, host-only HTML/scripts/APIs, rejection of remote ships and unauthenticated host-shaped requests, member route authentication, exact path/extension matching, safe login return paths, separate action allowlists, and exclusion of configuration fields from member responses. HTTP smoke verifies the public-to-private redirect and the same separation on the running desk.

Source cases cover v0→v1 migration, exclusion of proxy authority, native ownership changes and subscription gaps, claim invalidation on NFT transfer/rebuild epochs, unchanged-generation preservation, malformed coverage, same-checkpoint mutation, explicit divergent-checkpoint recovery, and failure pause without false revocation.

## RPC reader cases

Finalized pagination; chain mismatch; unavailable/stale finality; missing contract; unsupported standard; changed block hash; ownerOf mismatch; transfer/burn replay; token ID zero and uint256 maximum; duplicate, removed, out-of-range and foreign-contract logs; missing mint history; and ERC-20-shaped events.

Persistent indexer cases add restart continuation, transfer-away-and-back generations, self transfers, burns/remints, ERC-2309 bounds, omitted constructor-mint detection, sparse enumeration, duplicate/unsupported enumeration, deployment validation, range reduction, canonical log checks, wrong header numbers, code-change refusal, explicit rebuilds, atomic write failures, failure/recovery, redacted RPC retries, host-import retries and watch backoff.

## Local integration

The source smoke test receives the native Azimuth initial snapshot, resumes its subscription, imports synthetic provenance-bearing NFT snapshots, pauses on failure and invalidates a claim after a simulated transfer-away-and-back. The EAuth smoke test uses two real running fake ships, Ames discovery and normal browser HTTP endpoints, then verifies remote identity, unsigned takeover denial, linked-ship transfer, host-only boundaries, actor binding, restoration, logout and rejected approval. These are local tests, not live chain or Tlon proofs.

## Strict reassignment cases

The wallet suite checks an independent eth-account signature/hash vector, valid owner authorization, wrong signer, replay, expiry, excess validity, host/URL/chain/token/recipient/generation/owner changes, stale inputs, host suppression, malformed signatures, high-s and invalid recovery IDs. It also covers linked-ship authority, ineligible recipients, refusal to displace a recipient's other claim, and independence across collections.

The wallet HTTP smoke test signs a real server-generated challenge using public test key 1, submits it through a remote EAuth session, rejects unsigned/forged/spoofed/replayed requests, and restores the association through linked-ship approval. Browser checks verify the transfer form and visible wallet message/signature controls. Browser-extension signing and hardware-wallet compatibility remain pilot checks.

## Production acceptance still outstanding

- EAuth server-side expiry, callback replay and deployment proxy behavior.
- Azimuth completeness and processed-chain health/finality proof; ownership event handling is implemented.
- Live RPC integration against the configured collection/provider, verified mint coverage and large-history limits.
- Real Tlon delivery for DMs, invite/accept, claimed admission, roles, pending cancellation and kicking.
- Removal-before-grant under failed acknowledgements, restarts and delayed messages.
- Protected host/channel hosts, manual roles, moderation bans, outbox deduplication and replay.
- Cold-pier save/load with queued network operations; Gall reload and v0→v1 reducer migration are covered.

A passing reducer test does not prove a Tlon action was delivered. This build intentionally sends no Tlon actions.
