# Acceptance checks

Automated suites live in `tests/`; see [development](development.md) for commands.

## Executed reducer/input cases

DM-default, invite-all and no-outreach modes; claim before membership; unsigned sibling takeover denial; linked-ship-authorized reassignment; concurrent revision conflict; unrelated wallet rejection; one token per ship per collection; release authority; stale inputs; NFT and ship-owner changes; remove-role-and-membership default; optional membership retention; another collection sustaining the same role; broad-invite eligibility loss; retaining an eligible broad-invite member before claiming; and preserving ships across distinct Azimuth owner addresses.

HTTP/input cases cover host versus remote EAuth-shaped identities, rejecting anonymous comet identities, same-origin guards, host-only configuration, the live-delivery lock, arbitrary collection defaults, malformed/duplicate ownership, empty snapshots, stale RPC snapshots, checkpoint identity/regression, and uint256 imports.

Page separation cases cover public routes, host-only HTML/scripts/APIs, rejection of remote ships and unauthenticated host-shaped requests, member route authentication, exact path/extension matching, safe login return paths, separate action allowlists, and exclusion of configuration fields from member responses. HTTP smoke verifies the public-to-private redirect and the same separation on the running desk.

The public login document must allow HTTP(S) form redirects to the claimant's
discovered EAuth origin. Claim/configuration documents and assets retain
`form-action 'self'`; script, style, framing and base restrictions stay unchanged.
Hoon and HTTP checks assert this scope. Also test in a real browser: open
`http://127.0.0.1:8190/gater?collection=demo`, enter `~zod`, submit, and verify
navigation to the other fake ship at port 8191 (its login or approval page).
Run `eauth_smoke.py` first to initialize the two fake ships' endpoint discovery.
The urllib smoke client follows the EAuth protocol but cannot detect a browser
blocking its cross-origin redirect with CSP.

Source cases cover v0→v1 migration, exclusion of proxy authority, native ownership changes and subscription gaps, claim invalidation on NFT transfer/rebuild epochs, unchanged-generation preservation, malformed coverage, same-checkpoint mutation, explicit divergent-checkpoint recovery, and failure pause without false revocation.

## RPC reader cases

Finalized pagination; chain mismatch; unavailable/stale finality; missing contract; unsupported standard; changed block hash; ownerOf mismatch; transfer/burn replay; token ID zero and uint256 maximum; duplicate, removed, out-of-range and foreign-contract logs; missing mint history; and ERC-20-shaped events.

Persistent indexer cases add restart continuation, transfer-away-and-back generations, self transfers, burns/remints, ERC-2309 bounds, omitted constructor-mint detection, sparse enumeration, duplicate/unsupported enumeration, deployment validation, range reduction, canonical log checks, wrong header numbers, code-change refusal, explicit rebuilds, atomic write failures, failure/recovery, redacted RPC retries, host-import retries and watch backoff.

## Local integration

The source smoke test receives the native Azimuth initial snapshot, resumes its subscription, imports synthetic provenance-bearing NFT snapshots, pauses on failure and invalidates a claim after a simulated transfer-away-and-back. The EAuth smoke test uses two real running fake ships, Ames discovery and normal browser HTTP endpoints, then verifies remote identity, unsigned takeover denial, release/reclaim, host-only boundaries, actor binding, restoration, logout and rejected approval. These authentication/source checks use invented ownership. A separate `tlon_smoke.py` verifies actual Tlon delivery between fake ships: DM receipt, EAuth claim, invitation acceptance, role assignment, voluntary release and ownership-loss revocation, broad invitation and pending cancellation, manual-access preservation, observed receipts and Gall reload. Real NFT indexing is independently verified in [Nockmilio source checks](nockmilio-verification.md).

## Strict reassignment cases

The wallet suite checks an independent eth-account signature/hash vector, valid owner authorization, wrong signer, replay, expiry, excess validity, host/URL/chain/token/recipient/generation/owner changes, stale inputs, host suppression, malformed signatures, high-s and invalid recovery IDs. It also covers linked-ship authority, ineligible recipients, refusal to displace a recipient's other claim, and independence across collections.

The historical wallet HTTP smoke test signed a real server-generated challenge using public test key 1, submitted it through a remote EAuth session and rejected unsigned/forged/spoofed/replayed requests. The current UI removes linked-ship transfer in favor of release/reclaim; wallet-authorized takeover remains supported and covered by the verifier suite. Browser-extension signing and hardware-wallet compatibility remain pilot checks.

## Production acceptance still outstanding

- EAuth server-side expiry, callback replay and deployment proxy behavior.
- Independent trust beyond the pinned Urbit bootstrap and RPC provider. Canonical finalized suffix coverage, L2 replay, freshness and incremental restart now pass on the dedicated comet.
- Additional collection adapters, provider plans and large-history limits; Nockmilio replay, ownership validation and incremental restart are verified.
- First consenting real Tlon invitation and acceptance. Production controls are deployed and paused; fake-ship delivery for DMs, invite/accept, claimed admission, roles, pending cancellation and kicking passes.
- Removal-before-grant under failed acknowledgements, restarts and delayed messages.
- Broader failure injection for protected members/bans and outbox replay; pure protection tests and real manual-role preservation pass.
- Cold-pier save/load with queued network operations; Gall reload and v0→v1 reducer migration are covered.

A passing reducer test does not prove a Tlon action was delivered. The production adapter requires verified fresh sources, explicit targets and manual approval or automatic mode. It remains paused on the dedicated comet, with no real delivery receipts. See [production delivery](production-delivery.md).

## Community UI and provisioning

Collection route parsing, reserved IDs, image URL and palette validation,
minimal public metadata, host-only creation/deletion, duplicate group/role
refusal, in-progress job exclusion, stale deletion revisions, claim/source
cleanup, preservation of shared managed roles, and preservation of retired
memberships are covered in `tests/community.hoon`. The fake-only
`community_smoke.py` exercises actual group creation with a deterministic slug,
initial chat registration, non-admin role creation, public/authenticated pages,
branding save/load and non-destructive Tlon preservation after Gater deletion.
