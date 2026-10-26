# Decisions

Updated 2026-10-26: the owner explicitly replaced sibling takeover with the stricter authorization rule.

| Topic | Decision |
| --- | --- |
| Name | Desk and Gall agent `%gater`; `%hater` in the follow-up is treated as a typo |
| Default recognition action | DM each eligible associated ship with configurable text and a claim link |
| Other recognition actions | Invite all eligible ships to the configured group, or do nothing |
| Claim timing | Claim before joining; the claim should trigger admission and the managed role |
| Replacement | Only the currently linked eligible ship, or the current NFT owner wallet with a signature, may authorize reassignment |
| Eligibility loss | Remove managed role and membership by default; configurable membership retention |
| Scope | One NFT per ship per collection, one ship per NFT, on this host |
| Identity | Effective Azimuth owner, including Azimuth L2; not management/spawn proxy |
| Collection identity | Chain ID plus contract address; short config ID is an alias |
| Initial standard | ERC-721; Ethereum mainnet and Base mainnet |
| Authorization | EAuth and common ownership for claims; occupied claims additionally require linked-ship approval or wallet signature |
| Source outage | Freeze grants and destructive reconciliation; preserve last known state, indicate staleness |
| Source rebuild or continuity gap | Require new claims when ownership continuity cannot be established; ordinary RPC failures preserve claims |
| NFT ingestion | Supported external indexer with explicit finalized checkpoints and discovery coverage; native Iris remains optional |
| Role ownership | Dedicated non-admin roles; never treat all roles on a member as Gater-owned |
| First-pass execution | Persistent on-ship claims and action preview; live delivery unavailable |

Recognition does not itself reserve an NFT. `none` suppresses outreach, not claims or entitlement reconciliation. A replacement revokes the old association's access unless another valid entitlement supports it. Multiple collections managing one group must agree on its membership-loss setting.

The current implementation has one group/role destination per collection configuration. One collection feeding multiple groups is a planned schema extension. Independent hosts do not share a global mapping. Unsigned sibling takeover is rejected, including requests from the host acting as a claimant. The linked ship can transfer to an eligible ship with no other claim in that collection. Alternatively, the receiving ship signs in with EAuth and submits the current owner wallet’s signature over a five-minute, revision-bound message. Regular Ethereum key wallets are supported; ERC-1271 contract wallets require a future adapter. Existing associations remain intact when upgrading.

## Inputs needed for a live pilot

No further product decisions are needed to continue development. Before deployment, supply the host ship/public HTTPS URL, actual hosted group name and dedicated role ID, installed Tlon revision, and an RPC endpoint for each NFT chain. Resolve Nockmilio's deployment block and event behavior. Put credentials into private configuration, not chat or Git.

## Boundaries

Address equality is a useful first rule for ordinary key-controlled accounts. The same smart-contract address on two chains need not imply the same controlling person. Vaults, staking, custody, delegation, wrapped NFTs, and ERC-1155 quantities need explicit adapters/policies. Removal cannot retract messages already downloaded. License and remote Git hosting for Gater's original code remain owner decisions; vendored code notices are included.
