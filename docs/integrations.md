# Interfaces and evidence

Reviewed on 2026-10-25. Source inspection establishes available designs; live compatibility with the eventual host ship remains a Phase 0 task.

## Azimuth ownership

The local Urbit source checkout is at `50c7f5239610fc72263df7aa99b4d171cfe9d408` (2026-10-14). Relevant files:

- [`app/azimuth.hoon`](https://github.com/urbit/urbit/blob/50c7f5239610fc72263df7aa99b4d171cfe9d408/pkg/arvo/app/azimuth.hoon): owner index, point scries, and update subscriptions.
- [`lib/naive.hoon`](https://github.com/urbit/urbit/blob/50c7f5239610fc72263df7aa99b4d171cfe9d408/pkg/arvo/lib/naive.hoon): effective point state including owner address/nonce and rollup processing.
- [`app/eth-watcher.hoon`](https://github.com/urbit/urbit/blob/50c7f5239610fc72263df7aa99b4d171cfe9d408/pkg/arvo/app/eth-watcher.hoon) and [`ted/eth-watcher.hoon`](https://github.com/urbit/urbit/blob/50c7f5239610fc72263df7aa99b4d171cfe9d408/pkg/arvo/ted/eth-watcher.hoon): log collection and source progress.

In the inspected `%azimuth` agent:

| Interface | Meaning and caveat |
| --- | --- |
| `%x /own` scry | Address-to-ships ownership index; verify it covers all relevant points |
| `%x /point/~ship` scry | Effective point state, including L2; not a finalized historical query |
| `%x /nas` scry | Naive PKI state; useful for adapter inspection/snapshots |
| `/event` subscription | Initial `%naive-state`, then `%naive-diffs`; ownership-aware feed |
| `/` or ship watch paths | Jael-oriented `%azimuth-udiffs`; do not substitute these for ownership updates |

`/event` differences do not themselves expose the full block provenance wrapper used internally. `%eth-watcher`'s `%x /block/<watch-path>` reports its next block to check, not automatically an atomic guarantee that `%azimuth` has processed that same boundary. Snapshot/event race handling, filtered PKI state, resets, and freshness need tests.

The integration should subscribe, receive a snapshot, apply subsequent updates, and periodically reconcile against the ownership index. If the installed agent does not support a complete ownership view, expose that fact and use a separate source; do not silently reconfigure Jael or the ship's main PKI watcher.

Reading only Azimuth's Ethereum storage is insufficient for the requested effective L2 ownership. Urbit's [Azimuth repository](https://github.com/urbit/azimuth) describes the L1 contracts; the ship-side replay supplies the additional state.

## Ethereum and Base reads

The MVP needs read-only JSON-RPC access: chain ID, block headers, logs, bytecode/interface checks, and `eth_call` for `ownerOf`/`balanceOf` as appropriate. Bound log ranges and shrink them on provider limits; order events by block, transaction index, and log index, and deduplicate by canonical block hash and log identity. Commit cursor and state together. Check stored hashes after reconnection and rebuild from a known checkpoint on divergence. [Ethereum JSON-RPC reference](https://ethereum.org/developers/docs/apis/json-rpc/).

ERC-721 enumeration is optional; token IDs need not be sequential. A general adapter cannot assume `tokenOfOwnerByIndex`, and plain RPC does not offer a universal NFT-holder listing. Normally discover tokens from deployment-era Transfer logs and verify owners at a pinned block. Constructor-time minting can lack Transfer events; ERC-2309 ranges and unusual contracts need explicit handling. Require a declared discovery method and reject incomplete bootstrap rather than calling an empty index complete. [ERC-721 specification](https://eips.ethereum.org/EIPS/eip-721).

The inspected `%eth-watcher` supports separate watch configurations and exposes `%history`, `%logs`, and `%disavow` shapes. However, its current thread uses range-based fetching, has the near-head reorg loop commented out, and uses a block-distance margin. Its interface alone does **not** establish Base-aware finality or complete reorg handling.

The first pass uses `scripts/scan.py` beside the ship and host-only snapshot import. The target architecture remains a small Gater-specific bounded RPC polling module through Iris with explicit checkpoints and finality. Reuse existing HTTP/ABI libraries. Only reuse `%eth-watcher` itself after demonstrating the required behavior on the pinned version; never replace the host's existing Azimuth watch configuration.

Existing RPC configuration may be reusable. `%eth-watcher` exposes `%x /dogs/configs`, which can include credential-bearing URLs. A host-only setup action may resolve a selected configuration internally and display only a redacted provider label. An Ethereum endpoint cannot be used as a Base endpoint just by changing a chain number. Verify `eth_chainId` and required methods for each endpoint. No private configuration was read during planning.

## Tlon groups

The local Tlon checkout is at `e599fabcf4f715cfda67f73439c2e0871189bee1` (2026-09-29). Inspect the installed desk before choosing compatible marks and types; older examples use `fleet`/`sects`, while this source uses `seats`/`roles`.

Sources: [`sur/groups.hoon`](https://github.com/tloncorp/tlon-apps/blob/e599fabcf4f715cfda67f73439c2e0871189bee1/desk/sur/groups.hoon), [`app/groups.hoon`](https://github.com/tloncorp/tlon-apps/blob/e599fabcf4f715cfda67f73439c2e0871189bee1/desk/app/groups.hoon), and [backend explanation](https://github.com/tloncorp/tlon-apps/blob/e599fabcf4f715cfda67f73439c2e0871189bee1/docs/backend/desk/app/groups.md).

The inspected agent accepts `%group-action-5`, with a local-ship authorization check and versioned group action types. The following are action shapes to verify in the spike, not copy-and-paste Dojo commands:

```text
invite:          group(flag, entry(pending(ships, add(empty_role_set))))
revoke pending:  group(flag, entry(pending(ships, del)))
grant role:      group(flag, seat(ships, add-roles(role_ids)))
revoke role:     group(flag, seat(ships, del-roles(role_ids)))
remove member:   group(flag, seat(ships, del))
```

Adding pending ships sends invitations and can preassign roles. Gater uses an empty set for initial invites. A pending addition can also approve an existing join request. Use this admission mechanism instead of the manual seat-add escape hatch.

Pending deletion calls invitation revocation in the inspected source. Verify token invalidation and actual join behavior after revocation, including older clients. Seat deletion protects the host and channel hosts. Group subscriptions/scries provide observed state for reconciliation; pin their exact versions alongside action marks.

Keep all Tlon translation in one adapter. Do not let a foreign EAuth user send arbitrary group actions through Gater's host authority. Resolve allowed group, collection, ship, and role from host policy.

## Eyre and EAuth

Source inspection of `sys/vane/eyre.hoon` shows `authenticated` is true only for `%ours`. `%real` EAuth identity becomes `src.bowl`; anonymous `%fake` identities are comet-sized. Gater allows Azimuth-sized remote identities and requires the authenticated flag for host identity. Do not require that flag from every EAuth user. The alpha tests this distinction, but a two-ship handshake remains an integration gate.

EAuth supplies the remote ship identity to the agent. A host-served member UI can initiate login using `/~/login` and return to `/gater`. Serve it independently of the ordinary `%docket` front end. Test remote endpoint discovery, reverse-proxy behavior, expiry, logout, and unauthorized requests on the deployed kernel. [Official EAuth documentation](https://docs.urbit.org/urbit-os/kernel/eyre/eauth).

## Nockmilio

[Scatter's collection page](https://www.scatter.art/c/nockmilio) identifies Nockmilio as an ERC-721 collection on Base. The collection page’s ERC721 link points to Base contract `0x7465E492a183F16C0805e57262898c7bec11808A` ([explorer](https://basescan.org/address/0x7465E492a183F16C0805e57262898c7bec11808A#code)). Deployment block and discovery behavior still need verification. The example now includes the address; it never treats the slug as an asset identifier.
