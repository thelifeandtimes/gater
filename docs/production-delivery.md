# Audited ownership and production delivery

Delivery runs automatically by default. Each collection can opt into **Manually
approve all actions**. **Enable delivery** is the host-wide pause switch.
Invitations, role changes, release/removal and the subsequent notification are
exercised end to end between disposable fake ships.

## Ownership trust boundary

`config/azimuth-anchor.json` pins the installed Urbit bootstrap snapshot at
Ethereum block 25,421,988, its canonical block hash and the snapshot noun digest.
This inherits trust in Urbit's historical bootstrap; it is not a genesis replay
or a cryptographic proof of the bootstrap's complete historical state.

The native RPC engine checks Ethereum mainnet identity, the anchor's canonical hash, a recent finalized target, complete log-window coverage, each log block hash, and rollup transaction hash, block, destination and calldata. RPC remains the chain-data trust source. The engine rejects malformed/duplicate logs, conflicting finalized history and stale targets; it never falls back to `latest`.

The host atomically replays the verified suffix with Urbit's `naive` interpreter. Effective L2 owners are used; depositing a ship into Urbit L2 preserves its effective owner. Transfer generations invalidate claims after transfers away and back. Once audit mode is active, unaudited head observations cannot overwrite the finalized map. Proof freshness expires after fifteen minutes. NFT ownership separately requires finalized, complete discovery and ownership evidence; missing freshness pauses new actions. An outstanding result may still be observed while paused/stale.

The host UI can explicitly approve a different installed Urbit bootstrap after reviewing its height, hash and fingerprint. Existing claims must be released before changing this trust anchor. Approved snapshots are retained on the ship. See [native RPC verification](native-rpc.md) and [installation](install.md); no external worker or host environment is required.

The vendor files `desk/lib/{naive,tiny,ethereum}.hoon` are copied unchanged from
`urbit/urbit` commit `50c7f5239610fc72263df7aa99b4d171cfe9d408`, `pkg/arvo/lib/`.
Their MIT license is retained in [urbit-vendor-LICENSE.txt](urbit-vendor-LICENSE.txt).

## Approval and receipts

The production gate requires current audited ownership, real source mode,
current NFT sources, and automatic collection policy or an exact operation
approval when the collection requires one. Production has no recipient allowlist;
fake-ship transports retain an explicit target allowlist. Approval fingerprints bind action, ship, group,
roles and DM content; unrelated queue numbering changes do not alter them.

Dispatch is serialized. Tlon observation, not a poke acknowledgement, establishes
completion. Admission may be observed as a pending invitation carrying the role;
the recipient still accepts it. A DM receipt means the message is present in
local Tlon storage, not that a remote ship received/read it. Fake-ship tests also
verified remote receipt independently.

Idempotent group commands retry at most three total attempts, thirty seconds
apart, only while ownership and policy still authorize the operation. DMs are
never blindly repeated. Active work and receipts persist across Gall reload.
Negative acknowledgements expose **Retry rejected action** after revalidation;
uncertain results expose **Recheck result** and block subsequent dispatch until
resolved. Rechecking does not erase ambiguous history. Inspect Tlon if uncertainty
persists; there is deliberately no “pretend delivered” control.

Managed-role removal precedes membership removal and replacement grants in that
group. Missing, stale or protected groups do not stall independent communities. Bans,
administrators, host/channel-host seats, independent roles and manually acquired
membership are protected. Releasing an NFT while it remains eligible still
revokes the managed role and, by default, the managed membership. The collection
can retain membership instead. Manual delivery requires approval for these
removals and notification messages too. The default needs no host intervention.
An observed completion immediately advances the queue, so revoke → kick → DM
does not wait for separate polling intervals. Freshness and independent-access
protections remain in force; a pause or stale source can delay new commands.

Each collection has an editable removal DM. Its display name and public invite
URL are added automatically; blank text disables the message. Notifications
are durably queued only after observed kicks, survive reloads, and are canceled
if a new claim restores desired access before sending. Failed kicks and
preserved manual membership produce no removal DM. Existing historical kick
receipts are never replayed during migration. For multiple collections bound
to one group, any manual-approval setting holds shared group actions; a single
removal DM uses the first nonempty removal message in collection-ID order.
The configuration and chosen text are captured when the kick is observed.

## Review the membership lifecycle

1. Open `/gater/config` on the group host. Verify a current ownership audit
   and NFT checkpoint, a hosted group, its membership role, and a public URL
   reachable by visitors.
2. In the collection’s Membership flow, leave manual approval unchecked for
   automatic operation, or check it to review each exact action. Set the removal
   policy and DM copy.
3. Sign in as an eligible visitor and link an NFT. Accept the Tlon invitation;
   verify the configured role.
4. Release the link. Gater revokes its role, removes its managed membership
   according to policy, then sends the configured removal/rejoin DM. Recent
   receipts show the sequence. In manual mode approve each queued action.
5. Link an eligible NFT again to rejoin. Global delivery can be paused at any
   time without erasing receipts or confusing pending results with success.

For a target without a claim, set recognition to invite-all to propose an invite,
or DM to propose its claim link. Public claim links require a reachable public
host origin; loopback URLs are useful only on this computer. Host URL suggestions
come from Eyre, not an external reachability test.

## Migration from the original pilot

The original v0.1 development pilot used external NFT and Azimuth services. Stop those workers and disable their restart before upgrading; v0.2 performs both jobs inside the ship. Follow the [upgrade guide](install.md#5-upgrade-from-01). The ship runtime remains the only required running process.
