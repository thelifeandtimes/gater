# Acceptance scenarios

These are required future tests, not tests already implemented or run. Use synthetic wallets, test ships, and sanitized RPC fixtures first; reserve live tests for the bounded pilot.

| Scenario | Expected result |
| --- | --- |
| One address, three planets, one NFT | Three eligible invitations; at most one active association and one NFT entitlement |
| One address, two NFTs, two planets | Each planet can claim a different token |
| One planet claims a second token in the same collection | Explicit atomic replacement or conflict; never two simultaneous associations |
| Same token ID on two chains/contracts | Distinct assets; no collisions |
| Same collection used by two local groups | The association is shared; both groups derive roles from the same ship |
| Different collections grant the same role | Losing one qualifying claim does not remove a still-supported role |
| L1 and Azimuth L2 points | Both resolve their effective owners; L1 escrow/sentinel ownership does not qualify an L2 point |
| Proxy or approved NFT operator matches | No eligibility unless it is the actual owner |
| Moon/comet login | Clear unsupported identity response; no inherited parent ownership |
| Contract owner at the same address on both chains | Requires the explicit contract-wallet policy; no silent cross-chain authority assumption |
| Two concurrent claim requests | One succeeds; the other gets a conflict with current revision |
| Retried claim after lost HTTP response | Returns the existing outcome; no duplicate claim or side effect |
| Competing sibling ship requests remap | Follows the selected authority policy; no silent overwrite |
| Role revoke fails during remap | Destination role remains pending; old-role failure is visible |
| Crash after revoke, before destination grant | Durable transition resumes and converges without duplicate entitlement |
| Delayed response for an older policy/claim | Rejected by revision/source generation checks |
| NFT transfer or burn | Invalidate affected claim, revoke unsupported managed role, apply membership policy |
| Azimuth owner changes | Old claim and application authorization invalidated; new owner must claim afresh |
| Token or point moves away and back | Ownership generation prevents automatic revival |
| Both point and NFT move together | Prior claim is invalidated despite restored address equality |
| Point breach/continuity change | Invalidate sensitive authorization and require the chosen recovery flow |
| Reorganization invalidates observed ownership | Rebuild canonical state; compensate applied effects; no grants from discarded observations |
| RPC outage or incomplete bootstrap | Show unknown/stale; freeze new grants; do not treat as zero balance |
| Empty log interval | Cursor still advances atomically with validated scan progress |
| Duplicate/out-of-order logs | Deterministic index after sorting and deduplication |
| Constructor mint/non-enumerable collection | Explicit discovery strategy; never silently omit holders |
| Anonymous request with claimed ship in body | Denied; body never establishes actor identity |
| Foreign member requests host admin operation | Denied on HTTP and direct Gall paths |
| CSRF, replayed signature, or wrong target/domain | Denied without modifying claims or roles |
| EAuth session predates ownership transfer | Cannot authorize a new sensitive change without the required fresh proof |
| User leaves, declines, or administrator bans | No repeated automated invitations; preserve suppression |
| Pending invitation loses eligibility | Revoke Gater-owned admission; test that stale tokens cannot restore that admission |
| Membership gating on a public group or bypass token | Setup rejects strict gating until admission policy is corrected |
| Manual unrelated role or invitation exists | Preserve it |
| Managed member is a protected admin/channel host | Surface exception; do not report successful removal |
| Group/role deleted or Tlon version incompatible | Pause affected integration and report the cause |
| Agent restart, desk upgrade, state restore | Retain uniqueness indexes, audit, cursors, suppression, and pending effects |

At the integration boundary, verify actual group membership, roles, and channel access. A successful poke or rendered success message is insufficient. Measure discovery lag, revocation lag, bootstrap duration, RPC request volume, and event-log/state growth during the pilot.
