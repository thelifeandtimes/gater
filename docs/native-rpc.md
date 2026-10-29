# Native ownership verification

Gater 0.2 moves runtime chain access into `desk/lib/gater-rpc.hoon`, orchestrated by `%gater` through Iris and Behn. Python index/audit scripts remain reference and development tools. They are not required by installed desks.

## Credentials and access

Only the authenticated host's `/gater/config/action` accepts `rpc-settings` and `rpc-bootstrap`, using the same Origin and `X-Gater` checks as other host mutations. Remote EAuth visitors cannot read configuration or change credentials. Keys and custom endpoint URLs live in private saved Gall state. Status/scry/public JSON is built from explicit allowlists; provider response text is never displayed. Iris follows no redirects for RPC requests. Remote providers receive only normal read-only JSON-RPC requests, never wallet signatures, Urbit login codes or cookies.

Keys persist in the Urbit event log and backups. Clearing the active field cannot erase historical event data. Use a provider credential scoped to the required networks and rotate it at the provider if necessary.

## State and verification

- One serialized persistent job checks Azimuth and then each configured collection. Completed rounds pause for one minute. Iris requests have a 45-second deadline, bounded exponential retry, response-size limits and request IDs bound to the active serial. Old responses after configuration changes or reloads are ignored.
- JSON-RPC batches contain at most five reads; results may arrive in any order but must match every request ID exactly once. Duplicate, missing or foreign replies fail verification. Log windows begin at 10,000 blocks and shrink on retries. Provider quota failures are shown without response bodies or credential-bearing URLs.
- NFT bootstrapping uses ERC721Enumerable or an explicitly reviewed deployment-to-finality Transfer/ERC-2309 history plus total supply. Initial event discovery verifies code was absent before the deployment block. Subsequent rounds carry token ownership and transfer generations forward from a canonical checkpoint.
- Contract code fingerprints, network ID, finalized header age, log block hashes, supply and ownerOf results are checked. All owners are checked on bootstrap/migration and at least every six hours; changed owners are checked on each incremental round. A transfer away and back changes its generation, invalidating an earlier claim even if the final address matches.
- Azimuth begins at an explicitly pinned/approved Urbit snapshot, retains it, obtains canonical logs for both Azimuth and the Urbit rollup contract, and verifies each log block and rollup transaction hash, destination, block and input. Urbit's `naive` interpreter derives effective L1/L2 ownership. The historical bootstrap and RPC responses remain trust dependencies.
- Only a complete job with a rechecked recent finalized header can commit. A failed NFT read marks its source unhealthy; a failed Azimuth audit invalidates proof freshness. Last committed checkpoints are retained. In-progress jobs survive agent reloads. If a large bootstrap outlives its finalized target, Gater retains the verified prefix and catches up to a new finalized target before committing. Exhausted retries preserve committed state and move to the next source; incomplete jobs may need to replay from the last committed checkpoint on a later round.
- Freshness expires after fifteen minutes. Long initial scans, offline ships, provider outages or quota exhaustion can pause access changes until verification catches up. A known failure does not supply evidence to prune claims or trigger mass removals. No fallback to unfinalized `latest` data is used.

The existing policy, EAuth, wallet takeover, release and observed Tlon delivery paths consume the resulting verified state. NFT images and metadata are still loaded/cacheable only in the authenticated claimant's browser.

## Tests

`python3 scripts/check.py /tmp/gater-dev-nec --file tests/rpc.hoon` exercises credential handling, network/finality checks, batch correlation, discovery, canonical logs, rollup inputs, transfer continuity and migration. It requires a disposable fake ship with the desk loaded, not RPC credentials.

For a direct Iris integration test, configure a fake ship through its host UI, disable Tlon delivery, and use a real read-only provider key. Fake ships initially have empty `%azimuth` snapshots; load [Urbit's public bootstrap](https://bootstrap.urbit.org/mainnet.azimuth-snapshot) into the fake ship using the standard Azimuth loader and review its fingerprint in the host UI. This needs no access to a live ship. Never enable production transport or use live wallets merely to test indexing.

Protocol references: [Ethereum JSON-RPC logs](https://ethereum.org/developers/docs/apis/json-rpc/#eth_getlogs), [JSON-RPC batching](https://geth.ethereum.org/docs/interacting-with-geth/rpc/batch), and [Infura setup](https://docs.infura.io/get-started/infura/).
