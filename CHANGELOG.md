# Changelog

## 0.1.0 license supplement — 2026-10-29

- License Gater's original code, including v0.1.0, under GNU GPL version 3 only (`GPL-3.0-only`).
- Include the license, copyright notice and original third-party notices in the source package and Urbit desk.
- Refresh the v0.1.0 download and checksum from the supplemental `v0.1.0-gplv3` tag. Application code and the original `v0.1.0` tag are unchanged.

## 0.1.0 — 2026-10-28

First public release of Gater, an NFT membership manager for hosted Tlon groups.

- Configurable ERC-721 collections on Ethereum and Base, with a reviewed Nockmilio index configuration.
- Finalized NFT ownership indexing and effective Azimuth ownership verification against a pinned Urbit bootstrap and Ethereum RPC.
- Collection-specific public pages, EAuth sign-in, one NFT per linked ship, release, and owner-wallet authorization for occupied claims.
- Automatic Tlon invitations, roles, managed membership removal and optional removal DMs; per-collection manual approval and a global pause.
- Host-only community cards, group/channel and role creation, collection deletion and delivery receipts/recovery controls.
- Network theme inheritance from `%settings`, collection appearance and copy overrides, and browser-only artwork for authenticated holdings.
- Explicit named-ship installation and worker imports, including moon hosts; fake-only development tools and backward-compatible comet guards.

See [installation](docs/install.md) for the complete setup and [verification](docs/verification.md) for test evidence. This is an initial release: RPC data and the pinned bootstrap are trust dependencies, ERC-1155 and contract-wallet signatures are unsupported, and the local workers are required for live eligibility updates.
