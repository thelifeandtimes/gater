# Decisions and open inputs

The required behavior is broad invitations based on common ownership, followed by an exclusive NFT-to-ship association that drives roles. The following choices make that behavior precise.

| Decision | Proposed starting point | Status |
| --- | --- | --- |
| Execution | `%gater` on the group-host ship; native RPC reads through Iris | Proposed |
| Identity | Effective Azimuth owner, including Azimuth L2 | Required by design |
| Chains | Ethereum mainnet and Base mainnet | Requested |
| Token standard | ERC-721 first; other standards need explicit adapters | Proposed |
| Initial group access | All eligible IDs can be invited; invitation grants no NFT role | Requested |
| Initial claim authority | EAuth ship control plus matching on-chain ownership | Proposed interpretation |
| Reassignment | Current claim holder can release/nominate; wallet signature can recover an occupied claim | Awaiting user preference |
| Uniqueness | One ship per NFT; one NFT per ship per collection, across the host's groups | Awaiting scope confirmation |
| Cross-host uniqueness | Not enforced; would need a shared registry/authority | Architectural limit |
| Loss of qualification | Configurable per group; initially revoke role and keep membership | Awaiting user preference |
| NFT finality | Finalized checkpoints initially; configurable after measuring latency | Proposed |
| Azimuth finality | Establish provenance in Phase 0; do not assume current scry is finalized | Integration gate |
| RPC outage | Freeze new entitlements, keep existing access, show stale state | Proposed |
| Role ownership | Dedicated Gater-managed roles; protected admin/host exceptions | Proposed |
| Initial rollout | Dry run, test cohort, then broader invitations | Proposed |

## Inputs requested from the owner

1. The official Nockmilio collection link or canonical Base contract address. Deployment block and verified ABI/source can be resolved from the confirmed address.
2. Whether ownership loss removes only the managed role or also membership, or should be selectable per group.
3. Who may replace an existing association: current linked ship/wallet owner, any eligible sibling ship, or wallet signatures for every change.

Before implementation also identify the host ship, group flag, installed Tlon version, desired role/channel permissions, and whether the proposed per-collection uniqueness scope matches the intent. These do not prevent completing the architecture.

## Scope boundaries

The MVP does not equate a smart-contract address on Base with the same address on Ethereum without verifying the intended cross-chain authority policy. Automatic address matching is simplest for ordinary key-controlled accounts. Contract wallets, custody, staking, vaults, and delegated NFT holdings need explicit adapters or enrollment rules; do not silently count them as direct ownership.

ERC-1155 balances represent quantities, so a one-token/one-ship rule needs a defined allocation unit before support. Collection migrations, wrapped assets, and a possible move to Nockchain need explicit new policies; a matching name does not migrate existing entitlements.

Role removal prevents future authorized access where Tlon enforces it. It cannot retract messages or media a member already downloaded. Claim records remain host-managed records, not an on-chain ownership change or a decentralized guarantee.

No license or remote Git hosting destination has been chosen. The local repository is sufficient for this planning stage.
