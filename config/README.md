# Configuration

`collection.example.json` is now an actual `configure` action accepted by the app. Replace the group and role IDs before importing it. The contract was obtained from the ERC721 link on [Nockmilio's Scatter page](https://www.scatter.art/c/nockmilio); the deployment block and log-discovery behavior remain unverified.

The same form accepts other ERC-721 contracts on Ethereum (`"1"`) or Base (`"8453"`). Recognition is `dm` (default), `invite`, or `none`. `message` is plain text; the host URL plus `/gater?collection=<id>` is appended. `removeMembership` defaults to true. A collection's chain/contract/group/role identity cannot be changed in place in this alpha. Collections managing one group must agree on membership loss.

Configuration and imports are available only to the host. `live: true` is explicitly rejected. Put RPC URLs in a private environment variable. Store any private local JSON as `*.local.json` (ignored by Git). Never put a key or ship code in the browser or committed examples.
