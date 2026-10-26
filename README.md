# Gater

`%gater` is an Urbit Gall agent and Eyre claim page for NFT-based Tlon group access. It runs on the group host. Collections are configuration, not hard-coded application logic.

**Status: source and authentication integration preview.** Claims and configuration persist on the ship; the policy engine produces proposed actions. **It does not yet send DMs/invitations or change Tlon roles/membership.** A persistent external indexer and real two-ship EAuth tests are implemented. Live collection verification and Azimuth processed-chain provenance remain prerequisites for the production delivery adapter.

## Behavior

1. Match an Urbit ID's effective Azimuth owner to NFT ownership on Ethereum (`1`) or Base (`8453`).
2. On recognition, propose a DM containing the claim-page link by default. A collection can instead invite all eligible ships or do nothing.
3. A ship signs into the host's Eyre page using EAuth and claims a specific NFT. Existing membership is not required.
4. One NFT supports one ship; one ship may claim one NFT per collection on this host. Replacing an occupied claim requires approval from the linked ship or a signature from the current NFT owner wallet. Shared ownership alone is insufficient.
5. The claim drives the managed role and admission. Losing the last entitlement removes the role **and membership by default**; retaining membership is configurable. Other valid claims supporting the same role/group are considered before removal.

An address with three planets and one NFT can therefore produce three introductory DMs, but only one active association. No wallet transaction or NFT transfer is involved.

The public entry page is `/gater`. EAuth returns the visitor to `/gater/claim`, where their ship can manage its associations. Host configuration is a separate page at `/gater/config`; the agent requires an authenticated local host session for its HTML, script, and APIs. Claim responses contain no host settings or action outbox.

## What is here

- `desk/`: migrated persistent Gall state, policy reducers, host configuration and source health, native `%azimuth` ownership subscription, EAuth authorization, and the claim UI.
- `scripts/index.py`: supported read-only external ERC-721 indexer. Persists finalized checkpoints and transfer generations, verifies discovery coverage, retries provider failures, and imports source health into the host. Supports enumeration and reviewed Transfer/ERC-2309 histories; unusual collections need adapters.
- `tests/`: Hoon/Python scenarios and local HTTP, source-lifecycle and two-ship EAuth integration tests. See the [verification record](docs/verification.md).
- [Development guide](docs/development.md): installation, demo fixtures, RPC input, and tests.
- [Implementation plan](docs/implementation-plan.md), [architecture](docs/architecture.md), [decisions](docs/decisions.md), [integration evidence](docs/integrations.md), and [acceptance checks](docs/acceptance-tests.md).

[Nockmilio's Scatter page](https://www.scatter.art/c/nockmilio) links to the Base contract [`0x7465E492a183F16C0805e57262898c7bec11808A`](https://basescan.org/address/0x7465E492a183F16C0805e57262898c7bec11808A#code). Its deployment block and mint/discovery behavior still need verification before a complete production index. [Configuration examples](config/README.md) include this address.

Use a disposable test pier first. RPC credentials stay in environment variables; they are never included in the browser, claim URLs, or committed configuration. No Infura key is needed to run the fixture demo.
