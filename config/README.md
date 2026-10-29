# Legacy development configurations

Gater 0.2 configures RPC credentials, discovery and bootstrap trust in the host UI. These JSON files remain reference inputs for the legacy Python development tools; installed desks do not read them. See [current installation](../docs/install.md).

# Configuration

`collection.example.json` is an actual `configure` action accepted by the app. Replace the group and role IDs before importing it. The contract was obtained from the ERC721 link on [Nockmilio's Scatter page](https://www.scatter.art/c/nockmilio). [Nockmilio source checks](../docs/nockmilio-verification.md) record its verified deployment, reviewed mint events and completed ownership replay.

The same form accepts other ERC-721 contracts on Ethereum (`"1"`) or Base (`"8453"`). Recognition is `dm` (default), `invite`, or `none`. `message` is plain text; the host URL plus `/gater/<id>` is appended. `removeMembership` defaults to true. The collection editor confirms changes to its chain/contract/group/role binding before clearing claims; existing Tlon access is preserved rather than silently transferred to the new binding. Collections managing one group must agree on membership loss.

Configuration and imports are available only to the host. `live: true` is a rejected legacy setting; production delivery uses the separate host delivery controls and ownership audit. Put RPC URLs in a private environment variable. Store any private local JSON as `*.local.json` (ignored by Git). Never embed a key or ship code in Gater's frontend or committed examples; enter your host code only at Eyre's normal login page.

`index.example.json` configures the separate `scripts/index.py` worker. Its address and deployment block are **dummy values, not verified Nockmilio parameters**. Match `collection`, `chain` and `contract` to the agent configuration. Choose `enumerable` for ERC-721Enumerable, or `events-supply` with a verified `deploymentBlock` and a `reviewedSource` record explaining mint/event coverage. Both require accurate totalSupply. See the [development guide](../docs/development.md) for polling, state persistence and explicit rebuilds.

`index.nockmilio.json` contains the actual Base contract, deployment block and source-review record. A complete replay verified 1,938 owners on 2026-10-26 and an incremental restart advanced its checkpoint. The [comet pilot](../docs/comet-pilot.md) uses this configuration with continuous updates. Configuration alone is not a current ownership snapshot; inspect the worker and host source health.
