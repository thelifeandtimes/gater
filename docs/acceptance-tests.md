# Acceptance checks

Automated suites live in `tests/`; see [development](development.md) for commands.

## Executed reducer/input cases

DM-default, invite-all and no-outreach modes; claim before membership; eligible sibling takeover; concurrent revision conflict; unrelated wallet rejection; one token per ship per collection; release authority; stale inputs; NFT and ship-owner changes; remove-role-and-membership default; optional membership retention; another collection sustaining the same role; broad-invite eligibility loss; retaining an eligible broad-invite member before claiming; and preserving ships across distinct Azimuth owner addresses.

HTTP/input cases cover host versus remote EAuth-shaped identities, rejecting anonymous comet identities, same-origin guards, host-only configuration, the live-delivery lock, arbitrary collection defaults, malformed/duplicate ownership, empty snapshots, stale RPC snapshots, checkpoint identity/regression, and uint256 imports.

## RPC reader cases

Finalized pagination; chain mismatch; unavailable/stale finality; missing contract; unsupported standard; changed block hash; ownerOf mismatch; transfer/burn replay; token ID zero and uint256 maximum; duplicate, removed, out-of-range and foreign-contract logs; missing mint history; and ERC-20-shaped events.

## Production acceptance still outstanding

- Real two-ship EAuth round trip and proxy/session behavior.
- Azimuth completeness, source-health proof and event generations.
- Live RPC integration against the configured collection/provider, verified mint coverage and large-history limits.
- Real Tlon delivery for DMs, invite/accept, claimed admission, roles, pending cancellation and kicking.
- Removal-before-grant under failed acknowledgements, restarts and delayed messages.
- Protected host/channel hosts, manual roles, moderation bans, outbox deduplication and replay.
- Cold-pier save/load and state migrations with queued network operations.

A passing reducer test does not prove a Tlon action was delivered. This build intentionally sends no Tlon actions.
