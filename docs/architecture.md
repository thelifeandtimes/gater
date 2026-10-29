# Architecture

## Data flow

```mermaid
flowchart TD
    A[Host Azimuth bootstrap and event history] --> V[Canonical finalized audit and L2 replay]
    R[Ethereum or Base RPC] --> V
    V --> G[Gater state and policy]
    R -->|Finalized logs and ownerOf| S[Native Iris NFT indexer]
    S -->|Verified atomic snapshot| G
    B[Browser] --> E[Eyre / EAuth]
    E -->|Authenticated ship claim| G
    G --> C[Exclusive NFT-to-ship claims]
    C --> P[Proposed admissions, roles and removals]
    G --> O[Proposed DMs or broad invitations]
    P --> Q[Automatic collection policy or manual approvals]
    O --> Q
    Q --> T[Tlon commands and observed receipts]
```

Production delivery requires a current finalized ownership audit, fresh NFT
sources and automatic collection policy or exact manual operation approvals.
Observed Tlon state completes work; a poke acknowledgement alone is insufficient.
[Production delivery](production-delivery.md) details verification, retries and recovery.

## State and invariants

`desk/sur/gater.hoon` defines collections, ship owners, NFT owners and transfer generations, exclusive claims, managed seats/roles, suppression, an effect queue, source health/epochs/coverage, observation times, checkpoints, and the state revision. Gall serializes updates. The current save envelope %9 contains policy, delivery, community presentation, audit, approval and private RPC state, without artwork metadata, with migrations for older envelopes. Claim/release requests use revisions scoped to the selected ship, collection, NFT and relevant associations; unrelated updates do not cause conflicts. The explicit v0→v1 migration preserves fixture associations; legacy non-fixture claims lack provenance and require a new claim.

An asset is `[collection-id token-id]`; its configuration fixes chain and contract. Token IDs are full uint256 values serialized as decimal strings. A ship must be an Azimuth-sized identity with the same nonzero address as the token owner. A claim records its owner so a changed owner invalidates it. Ordinary claiming cannot displace another ship. The linked ship can release its NFT, after which another eligible ship can claim it. A recipient can instead authorize takeover with the current owner wallet’s signature. Self-directed claims clear that ship’s previous token in the collection atomically, preserving one-to-one mapping.

Desired roles are unioned by group/ship across collections. Only roles tracked in Gater's `applied` map are considered for revocation; only `managed` seats are eligible for removal. A broad invite without a claim can retain membership while eligible; a lost claim removes its previously managed access by default. The delivery ledger populates these maps from observed Tlon state and records the authority it actually added.

Pending queue entries are rebuilt after policy changes. Numeric IDs are not
approval identities; stable fingerprints bind the complete operation. Serialized
work, bounded retries, observed receipts and removal-before-addition ordering
live in the persisted delivery ledger. Delivery is automatic by default, with per-collection manual approval and a host-wide pause. The ledger also persists post-kick notifications; older envelopes migrate without replaying historical kicks.

## Source trust

When enabled, the native adapter subscribes to `%azimuth`'s `/event`, receives its initial `%naive-state`, and consumes `%point ... %owner ...` differences. Its installed `%zuse 408` ownership map is keyed by `[proxy address]`; only `%own` entries are eligible. The adapter also checks `/own` once per minute. Observed ownership changes prune claims immediately, so transferring a ship away and back does not resurrect its old association. A fresh subscription or mismatched periodic snapshot cannot prove continuity across the gap: it clears claims and requires reassertion. Existing Gall subscriptions are retained across compatible agent reloads.

Native state includes effective L2 ownership, but observation time does not prove chain freshness or complete PKI coverage. `/event` strips the internal processed-block wrapper. The finalized audit instead takes a pinned Urbit bootstrap and its ordered event suffix, verifies complete canonical RPC log coverage and rollup transaction inputs, and replays the native L2 transition function. The host atomically accepts completed native jobs using its retained approved bootstrap. The legacy audit importer also requires the exported history digest to match. Once enabled, audited ownership supersedes unfinalized observations; it expires after 15 minutes. The bootstrap and RPC provider remain explicit trust assumptions, described in [production delivery](production-delivery.md).

`desk/lib/gater-rpc.hoon` maintains persistent native jobs and verified checkpoints through Iris. The host configures an Infura key or custom HTTPS endpoints. ERC721Enumerable or reviewed complete deployment-era Transfer/ERC-2309 history discovers tokens. Code, supply, canonical log blocks and owners are checked at finalized checkpoints. Incremental rounds validate changed owners; all owners are rechecked every six hours. Transfer-away-and-back generations invalidate prior claims. Only completed verified jobs refresh policy state; failures pause affected access changes and preserve committed data.

Azimuth jobs retain the approved bootstrap and verified log suffix, validate canonical blocks and rollup calldata, then replay with `naive`. Both NFT and Azimuth jobs survive Gall reloads; deadlines, serialized batches and bounded retries handle provider failures. See [native RPC verification](native-rpc.md) for the complete trust boundary and limits. Legacy Python workers remain reference tools and should not run alongside native verification.

RPC responses are trusted data sources, not cryptographic proofs. An untrustworthy provider can omit a complete transfer-away-and-back sequence; proxy implementation upgrades may leave proxy bytecode unchanged. Production use still requires contract-specific coverage review.

## HTTP boundary

The host serves three separate pages and two API surfaces:

| Route | Access and purpose |
| --- | --- |
| `/gater`, `/gater/landing.js`, `/gater/style.css` | Public landing page, EAuth form and shared stylesheet |
| `/gater/claim`, `/gater/claim.js` | Verified ship session; secondary claim page after login |
| `GET /gater/me`, `POST /gater/action` | Verified ship session; holdings, claims and authorized reassignment |
| `POST /gater/wallet-challenge` | Verified eligible receiving ship; exact wallet authorization message, no state mutation |
| `/gater/config`, `/gater/config.js` | Authenticated local host only; configuration page |
| `GET /gater/config/state`, `POST /gater/config/action` | Authenticated local host only; settings, collection policies, ownership input and proposed actions |

The public page initiates `/~/login` EAuth with `/gater/claim` as the return path. A validated collection hint survives that transition. A signed-out visit to `/gater/claim` redirects to the public page; protected member APIs return 401, and host-only routes return 403 to everyone except the authenticated host. Complete paths are allowlisted; unknown paths, alternate extensions and the obsolete `/gater/app.js` return 404. The configuration HTML and script are never served to remote members. Member API responses omit host configuration and the outbox even when the host uses the claim page.

Eyre delivers the remote authenticated ship as `src.bowl`; its `authenticated` flag is true only for local host sessions. Anonymous Eyre identities are comet-sized, which protected member routes reject. Host routes require both the host source ship and the authenticated flag. This distinction is covered by unit tests and a real EAuth handshake between local fake ships. Expiry and deployment reverse-proxy behavior remain separate acceptance checks.

Remote ships claim/release as themselves. A linked ship can release its own association; the HTTP transfer action is removed. Wallet-authorized takeover always targets the authenticated receiving ship. The member endpoint refuses host actions even from the host; the configuration endpoint refuses all claim/reassignment actions. Group/role/configuration and ownership input require the host identity. POSTs require a same-origin Origin/Host pair and `X-Gater: 1`. Responses are uncached; each page has a restrictive content security policy and inserts text with DOM `textContent`. Wallet private keys remain in the wallet; the page receives only the selected address and signature. Saved RPC credentials never return in UI responses. The host submits new credentials through password fields; private Gall state and pier history retain them.

## Reassignment signatures

The current linked ship releases its claim before another eligible ship claims it. The old transfer form and HTTP `reassign` action are removed. The receiving ship can instead use `wallet-claim`, with its EAuth identity fixed by Eyre, and an EIP-191 `personal_sign` signature from the current NFT owner. Ordinary `claim` refuses an occupied NFT even when the claimant is the host.

The server reconstructs the exact message; it never trusts client-supplied message text, owner or destination fields. The message binds protocol version, host ship, configured public URL, chain, contract, collection, token, current owner, previous/receiving ships, revision, transfer generation and expiry. The claim-scoped revision binds the current association and is single-use: successful assignment increments it, and replay fails. Expiry is at most five minutes. Source freshness, eligibility and suppression are rechecked at commit. An actual ownership, policy or association change invalidates a pending signature; an unchanged index heartbeat does not.

The Gall verifier uses the kernel's Keccak and secp256k1 primitives, validates 65-byte signatures, permits recovery IDs 0/1 or 27/28, enforces low-s and scalar ranges, and catches invalid recovery. Verification needs no RPC. This first verifier supports regular Ethereum key wallets. ERC-1271 contract wallets need a separate chain-aware adapter; they are not accepted merely because a supplied signer claims to represent them. See [EIP-191](https://eips.ethereum.org/EIPS/eip-191) and [EIP-1271](https://eips.ethereum.org/EIPS/eip-1271).

## Tlon delivery

The same pinned `%group-action-5` and `%chat-dm-action-2` adapter runs in the fake
integration tests and behind the production authorization gate. The host observes
versioned group state and local DM records, persists active work, retries bounded
idempotent group commands, and provides rejection recovery and uncertainty checks.
Manual roles, pre-existing memberships, bans, admins and host/channel-host seats
remain protected. See [production delivery](production-delivery.md).

## Public presentation

Artwork loads only in the signed-in claimant’s browser, for tokens from the
current authenticated holdings response. Collection-level image URL patterns
avoid metadata requests; otherwise a bounded browser loader uses public RPC and
CORS-enabled token metadata. No artwork import or cache exists in Gall. The
host settings adapter publishes only validated appearance colors and font data.
See [community UI](community-ui.md) for browser caching, migration/history limits,
themes, custom fonts and EAuth session logout.
