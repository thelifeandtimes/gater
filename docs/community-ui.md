# Community management

Open `/gater/config` in a host session. Collection cards show the name, ID,
contract, hosted group and invitation link. Create or edit a community in its
own editor. Saving closes the editor and confirms success. Discarding edits,
changing the group/role, deleting a collection and sending an approved action
use styled confirmation dialogs.

## Host workflow

1. Enter a collection ID, display name, network and ERC-721 contract.
2. Select a locally hosted group or create one. New groups use the collection
   ID as their slug and include `<collection-id>-chat`. Existing group/channel
   names are refused. Select an existing non-admin role or create a plain role.
3. Choose DM, invite-all or no recognition action, and whether losing/releasing
   entitlement removes membership as well as Gater-managed roles.
4. Customize the invite/claim headings, descriptions, header, avatar and footer.
   Blank claim copy inherits invite copy. X/Twitter `/photo` and `/header_photo`
   links are resolved to `pbs.twimg.com` through FxEmbed in the visitor’s browser.
   Direct HTTP(S) image URLs work without that resolver dependency.
5. Set the full semantic palette, import Omarchy appearance JSON, or copy the
   host theme. Choose heading/body/mono families, optional hosted font files,
   spacing and corners. Hosted fonts need browser CORS support; installed fonts
   and family fallbacks remain available when a file cannot load.
6. Save, then open or copy the invite link. Each collection still requires an
   ownership indexer; the UI does not create RPC workers or store credentials.

Gater's general workspace reads `%settings` desk `omarchy-urbit-theme`, bucket
`appearance`, entry `current`, schema version 1. It falls back to Talon's stable
`omarchy-urbit-theme` theme, then the dark Omart-style application defaults. Only
validated colors and the font family leave the settings adapter. Collections can
inherit that theme or override it. A remote EAuth identity does not grant access
to that ship's private settings.

The public host URL is a saved Gater setting. Its picker now includes Eyre turf
names, Eyre's EAuth origin, the browser origin, the saved value and a custom
entry. Eyre's advertised origin is not proof that the Internet can reach it.
The dedicated comet currently advertises only `http://127.0.0.1:8192`.

## Public flow

- `/gater/<id>`: branded public EAuth landing page.
- `/gater/<id>/claim`: authenticated NFT artwork cards. Select one card, then
  confirm membership; a linked card instead offers release. An occupied
  association requires the current owner wallet's authorization.
- `/gater/<id>/info`: public collection branding only.
- `/gater/artwork.js`: authenticated browser loader; no host metadata endpoint.
- `/gater/appearance`, `/gater/favicon.svg`: public visual assets.
- `/gater` and `/gater/claim`: general pages; legacy query links still work.

The larger avatar overlaps the header. The collection name appears in the page
header. The footer is collection-configurable. Hover/focus the authenticated ship
name to sign out of that browser session. EAuth logout was tested separately
from a host session; it leaves the host session signed in.

Claim revisions bind the acting ship, collection policy, selected NFT ownership,
transfer generation and relevant associations. Unchanged source heartbeats and
unrelated claims no longer invalidate a selection. Unsigned retries refresh only
when the user's relevant intent is unchanged. Wallet signatures are never
rewritten/retried against another authorization; a real change requests a new
review. The former member `reassign` action and transfer form are removed.

## Delivery and deletion

See [production delivery](production-delivery.md). Delivery defaults to automatic.
Each collection can require exact approval with **Manually approve all actions**.
The host can pause delivery globally. Current audited Azimuth and NFT ownership are required.
Receipts describe observed Tlon state or local DM submission. Rejected requests
can be retried; uncertain requests can be rechecked without blind DM duplication.

Deletion removes Gater configuration, claims, ownership
snapshots and unsent decisions. It preserves the Tlon group, roles and existing
membership. Stop its external indexer separately. Group/role changes clear that
collection's claims and preserve old Tlon access; the dialog states this.
In-flight delivery blocks policy edits/deletion. Provisioning persists progress
and reports partial failures instead of overwriting existing groups.

## Browser-only artwork

No token artwork or display metadata is fetched, cached or imported by the ship.
The authenticated holdings response supplies chain, contract, finalized index
height and only that ship’s eligible token IDs. The claim page queues those
cards as they approach the viewport, with at most two metadata requests in
progress. It never enumerates a collection for artwork.

An optional **NFT artwork URL pattern** in collection settings maps `{id}` to a
direct HTTPS image. Nockmilio uses its existing Scatter media URL pattern, so its
cards need no metadata RPC or JSON lookup. This stores one collection-level
configuration string, not a list of token URLs or NFT metadata. Browsers load
images from their source and manage their normal HTTP image cache.

Without a pattern, the browser reads ERC-721 `tokenURI` through PublicNode’s
credential-free [Ethereum](https://ethereum.publicnode.com/) or
[Base](https://base.publicnode.com/) endpoint, then fetches bounded metadata JSON.
HTTPS, IPFS, Arweave and embedded JSON metadata are supported. This requires
source CORS access and an available public RPC; otherwise cards retain their
number placeholder and membership controls. No Infura key enters the browser.
The claim document alone allows HTTPS metadata connections; request credentials
and referrers are omitted.

Successful metadata uses **sessionStorage in that browser tab**, capped at 128
entries and 256 KiB of serialized characters, expiring after one day or when the
tab closes. Only currently eligible NFTs can be read from or added to this cache.
Refresh prunes ineligible entries; changing identity or signing out clears it.
Logout cancels queued work so late responses cannot refill it. Direct image
patterns need no token metadata cache. Failures never affect eligibility.

The former bulk media worker, file cache, public metadata/image-cache endpoints
and `import-media` action are removed. The `%7` save envelope omits artwork and
discards `%4`/`%5` media during migration while preserving policy, branding, claims,
audit and delivery state. Previously recorded metadata may remain in Urbit’s
historical event log or existing backups; migration does not rewrite that history.

X header/avatar resolution is separate browser presentation via the
[FxEmbed API](https://github.com/FxEmbed/FxEmbed/blob/main/docs/src/content/docs/api/introduction.mdx).
These configured community images remain available on the public landing page;
NFT artwork loads only on the authenticated claim page.

## Membership and theme follow-up

The public entry page always starts with EAuth; there is no shortcut to the host’s claims. Each collection’s gallery starts with the authenticated ship’s linked NFT, or an empty slot prompting “Link a <collection-id> for access”. Other cards show “unlinked” or “Linked to ~ship”. Artwork remains browser-only and limited to the signed-in ship’s holdings.

New and previously untouched collection palettes follow the host’s `%settings` appearance profile. Existing custom palettes remain custom. **Page theme** explicitly selects live inheritance or a custom palette. The entire safe color palette and network font are consumed; collection typography, spacing and corners can override the inherited values. Palette color edits select custom mode. If this host has no synced profile, the dark Omart-style palette and Newsreader / IBM Plex typography are used. EAuth does not grant access to the visitor ship’s settings. Host settings reports the current theme source.

**DM after membership removal** configures the explanation. Gater prefixes the collection display name and appends its invite URL. An empty message disables notification. A removal DM is queued only after the membership removal is observed; preserving independent manual membership does not notify.
