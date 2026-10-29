# Gater 0.2.0

`%gater` is an Urbit Gall agent and Eyre claim page for NFT-based Tlon group access. It runs on the group host. Collections are configuration, not hard-coded application logic.

**Native RPC release.** Gater provides branded collection pages, NFT artwork cards, EAuth claims and a host-only community editor. Delivery runs automatically once ownership is verified. Each collection can opt into manual approval; a host-wide pause remains available. Confirmed membership removals can send a configurable DM with the rejoin link. See the [release notes](CHANGELOG.md), [community UI](docs/community-ui.md) and [delivery walkthrough](docs/production-delivery.md).

## Install

Install on the ship hosting your Tlon group. If a publisher distributes the desk, run this in Dojo, replacing `~publisher-ship` with its actual identity:

```hoon
|install ~publisher-ship %gater
```

Then open **`/gater/config`** on your ship’s web host:

1. Under **RPC & ownership**, enter an Infura API key with Ethereum mainnet and Base enabled. Alternatively, enter separate HTTPS JSON-RPC endpoints. Ethereum is needed for Azimuth even when your NFTs are on Base.
2. Save RPC settings. Gater stores the credentials on your ship and starts checking finalized chain state through Iris. No environment variables, Python workers, or background services are required.
3. Create a gated community, choose its contract, group and role, and configure token discovery. ERC721Enumerable collections use enumeration; other supported ERC-721 contracts need reviewed mint/transfer/burn history and a deployment block. Nockmilio’s reviewed settings are filled automatically.
4. Wait for ownership verification to finish, then share the collection’s invite URL. The configuration page shows progress, errors and delivery receipts.

Credentials are write-only in the UI. Blank fields keep saved values; explicit removal checkboxes clear the active credentials. They remain part of the pier’s historical event log and backups. Use HTTPS when configuring a remote ship. Never enter a wallet private key.

To install from source instead:

```sh
git clone --branch v0.2.0 https://github.com/thelifeandtimes/gater.git
cd gater
python3 scripts/install.py /absolute/path/to/pier --init --live-ship '~your-ship'
```

After a successful compile, run `|install our %gater` in Dojo. Python is only needed for this optional source-loader, not for running Gater. This release targets kernel `%zuse 408` and compatible Tlon APIs. See the [installation and upgrade guide](docs/install.md), including how to retire v0.1’s external workers.

## Development and releases

`master` is the default branch for released code. `develop` contains work for the next release; create feature and fix branches from `develop` and merge them back there. Releases are promoted to `master` and tagged. See [CONTRIBUTING.md](CONTRIBUTING.md) for the branch and release workflow.

## Behavior

1. Match an Urbit ID's effective Azimuth owner to NFT ownership on Ethereum (`1`) or Base (`8453`).
2. On recognition, propose a DM containing the claim-page link by default. A collection can instead invite all eligible ships or do nothing.
3. A ship signs into the host's Eyre page using EAuth and claims a specific NFT. Existing membership is not required.
4. One NFT supports one ship; one ship may claim one NFT per collection on this host. Replacing an occupied claim requires release by the linked ship or a signature from the current NFT owner wallet. Shared ownership alone is insufficient.
5. The claim drives the managed role and admission. Losing the last entitlement removes the role **and membership by default**; retaining membership is configurable. Other valid claims supporting the same role/group are considered before removal.

An address with three planets and one NFT can therefore produce three introductory DMs, but only one active association. No wallet transaction or NFT transfer is involved.

The public entry page is `/gater`. EAuth returns the visitor to `/gater/claim`, where their ship can manage its associations. Host configuration is a separate page at `/gater/config`; the agent requires an authenticated local host session for its HTML, script, and APIs. Claim responses contain no host settings or action outbox.

## What is here

- `desk/`: migrated persistent Gall state, policy reducers, host configuration and source health, native `%azimuth` ownership subscription, EAuth authorization, and the claim UI.
- `desk/lib/gater-rpc.hoon`: native Iris JSON-RPC polling, resumable checkpoints, ERC-721 discovery and canonical Azimuth log/input verification.
- `scripts/index.py` and `scripts/audit_azimuth.py`: legacy development/reference tools, no longer required for operation.
- `desk/web/artwork.js`: browser-only artwork for authenticated holdings; no ship-side artwork cache.
- `tests/`: Hoon/Python scenarios and local HTTP, source-lifecycle and two-ship EAuth integration tests. See the [verification record](docs/verification.md).
- [Development guide](docs/development.md): disposable fake ships, demo fixtures, RPC input, and tests.
- [Implementation plan](docs/implementation-plan.md), [architecture](docs/architecture.md), [decisions](docs/decisions.md), [integration evidence](docs/integrations.md), and [acceptance checks](docs/acceptance-tests.md).

[Nockmilio's Scatter page](https://www.scatter.art/c/nockmilio) links to the Base contract [`0x7465E492a183F16C0805e57262898c7bec11808A`](https://basescan.org/address/0x7465E492a183F16C0805e57262898c7bec11808A#code). Its deployment and mint-event source have been checked; the v0.1 verification run checked all 1,938 owners at its recorded checkpoint, and an incremental restart advanced the finalized checkpoint. [Verification notes](docs/nockmilio-verification.md) and a [reviewed bootstrap configuration](config/index.nockmilio.json) record the evidence and remaining check.

Use a disposable test pier first. RPC credentials stay in private Gall state after submission; saved values are never returned to the browser or included in claim URLs or source control. No Infura key is needed to run the fixture demo.

Ownership verification trusts RPC responses and the explicitly pinned Urbit bootstrap. This release supports reviewed ERC-721 collections, not ERC-1155 or ERC-1271 contract-wallet signatures. Read the [trust boundary and recovery behavior](docs/production-delivery.md) before enabling a community. Third-party code and its licenses are listed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## License

Gater's original code, including v0.1.0, is licensed under **GNU GPL version 3 only** (`GPL-3.0-only`). See [LICENSE](LICENSE) and [COPYRIGHT](COPYRIGHT). Vendored code retains its original notices and licenses. The `v0.1.0-gplv3` tag and refreshed v0.1.0 download add license documentation to the original release; application code is unchanged. License documents are also included in `desk/` for Urbit distribution.
