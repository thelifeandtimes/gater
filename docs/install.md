# Install Gater 0.1.0

Gater runs on the ship hosting the Tlon group. Its web UI is served directly by Eyre. The desk has no JavaScript build step. Two Python workers run on the same computer as the pier: an NFT indexer for each collection and one Azimuth auditor for the host. **Installing the desk alone does not provide verified ownership updates.**

## Requirements

- A running local pier with kernel `%zuse 408`, a compatible Tlon `%groups` desk, and native `%azimuth` available. This release was tested with Vere 4.6 and Tlon APIs `%group-action-5`, `%group-foreign-2`, `%chat-dm-action-2` and the v3 group scry. Other kernel/API versions require testing before use.
- Python 3.10 or newer and `urbit` on the shell's `PATH`. The workers use Python's standard library; Node is needed only for browser-code tests.
- Run the tools as the pier's owner, with access to its `.urb/conn.sock` and local Eyre HTTP port. For a remote host, run these commands over SSH on that host.
- An Ethereum mainnet RPC endpoint for the Azimuth audit, plus an Ethereum or Base endpoint for each collection. The provider must support finalized blocks, historical logs, and the calls described in [configuration](../config/README.md).
- A public HTTPS origin for visitors to reach Eyre and complete EAuth. Loopback addresses work only on your own computer. Keep the origin stable after configuration.

Back up the pier before a first installation or upgrade, using your usual stopped-pier backup procedure. Do not run two processes against the same pier.

## 1. Get the release

On the computer running the pier:

```sh
git clone --branch v0.1.0-gplv3 https://github.com/thelifeandtimes/gater.git
cd gater
```

Alternatively, extract `gater-0.1.0.tar.gz` from the [GitHub release](https://github.com/thelifeandtimes/gater/releases/tag/v0.1.0). It includes the desk, workers and this guide. Download the accompanying `SHA256SUMS` into the same directory, then verify and extract:

```sh
sha256sum --check SHA256SUMS
tar -xzf gater-0.1.0.tar.gz
cd gater-0.1.0
```

The `v0.1.0-gplv3` tag and refreshed archive include the GPLv3 license documents selected after the initial publication. Application code is identical to the original `v0.1.0` tag. Keep `desk/license.txt`, `desk/copyright.txt` and `desk/third-party-notices.txt` with the desk when distributing it.

## 2. Load and start the desk

For the initial publisher installation on `~dister-dozzod-sarlev`, replace the pier path below with its actual absolute path. The pier must already be running.

```sh
GATER_PIER=/absolute/path/to/dister-dozzod-sarlev
GATER_SHIP='~dister-dozzod-sarlev'
python3 scripts/install.py "$GATER_PIER" --init --live-ship "$GATER_SHIP"
```

The installer checks the exact running identity and refuses a fake ship in live mode. It creates `%gater`, imports `desk/` through Clay, suspends the desk while loading, and compiles the agent. It does not start or replace the pier. `--init` refuses an existing desk; omit it for an update. Without a live-target option the installer accepts only fake ships. The older `--live-comet` option remains restricted to comets.

After `Compile complete`, run this in that ship's Dojo:

```hoon
|install our %gater
```

For later updates, rerun the installer **without `--init`**, then run `|revive %gater`. Saved collections, claims and delivery receipts migrate with the agent. If loading or compilation fails, leave the desk suspended and inspect the console before continuing.

Open `https://YOUR-SHIP-HOST/gater/config` and log in through Eyre as the host. The public `/gater` and collection pages are separate from host configuration. This release uses direct Eyre URLs rather than a Landscape app tile.

## 3. Configure a community

In **Create a Gated Community +**:

1. Choose a stable collection ID, chain and ERC-721 contract. For Nockmilio, use ID `nockmilio`, Base, and `0x7465e492a183f16c0805e57262898c7bec11808a`.
2. Select a group hosted by this ship and its managed membership role, or create them in the editor. New groups use the collection ID and include `<collection-id>-chat`.
3. Select recognition behavior: a DM with the claim link, invitations to all eligible ships, or no recognition action. Configure the removal policy and optional removal/rejoin DM.
4. Set page branding and copy. Artwork loads only in the signed-in claimant's browser for their holdings; Gater does not keep a ship-side artwork cache.
5. In Host settings, set the public origin and enable native Azimuth ownership. Use the actual reachable HTTPS origin, with no `/gater` suffix.

Delivery is automatic by default once all checks are healthy. **Manually approve all actions** holds that collection's actions for review, and **Enable delivery** can pause the whole host. Configure these before starting the workers if you want to review the first actions. Recognition can address every eligible ship, so choose its behavior before supplying live ownership.

Share `/gater/nockmilio` (or `/gater/<collection-id>`). Visitors authenticate with their own ship and select a held NFT at `/gater/<collection-id>/claim`.

## 4. Provide private RPC credentials

If the computer already has your shared Infura environment, load it in each worker terminal:

```sh
set +x
source "$HOME/.config/infura/env"
```

The worker commands below expect `ETHEREUM_RPC_URL` and `BASE_RPC_URL`. If the file exports only `INFURA_API_KEY`, derive those URLs in the shell without printing them:

```sh
export ETHEREUM_RPC_URL="https://mainnet.infura.io/v3/${INFURA_API_KEY:?Load your private Infura key first}"
export BASE_RPC_URL="https://base-mainnet.infura.io/v3/${INFURA_API_KEY}"
```

Any compatible provider can supply these environment variables. Keep the file outside the checkout with permissions `600`. Do not put credentials in Git, command arguments, public artwork RPC settings, or the collection's public URLs. The host importer obtains a temporary local Eyre session in memory and logs it out after each import; you do not give it a saved `+code` or cookie.

## 5. Run both workers

From the release directory, start Nockmilio's Base indexer in one terminal:

```sh
python3 scripts/index.py \
  --config config/index.nockmilio.json \
  --state output/nockmilio-index.local.json \
  --rpc-env BASE_RPC_URL \
  --pier /absolute/path/to/dister-dozzod-sarlev \
  --live-ship '~dister-dozzod-sarlev' \
  --watch
```

In another terminal, load the same private environment and start the Ethereum audit:

```sh
python3 scripts/audit_azimuth.py \
  --pier /absolute/path/to/dister-dozzod-sarlev \
  --live-ship '~dister-dozzod-sarlev' \
  --rpc-env ETHEREUM_RPC_URL \
  --anchor config/azimuth-anchor.json \
  --cache output/azimuth-audit.local.json \
  --watch
```

The first runs fetch historical data and may take time and provider credits. Subsequent runs reuse saved checkpoints. Keep `output/` private and preserve it across worker restarts. Only one indexer may own a state file; run only one auditor for a given host/cache. In deployment, run these same commands under your process supervisor, as the pier owner, with the release directory as their working directory and the private environment loaded. The files in `ops/` are examples for the original local comet pilot, not services to install unchanged for your moon.

Check the host page for **both** a fresh ownership audit and a healthy NFT source before testing claims. Stale or unavailable evidence pauses new delivery. The audit is pinned to the bootstrap in `config/azimuth-anchor.json`; if the ship has a different bootstrap, verification refuses to proceed. Review that bootstrap and its canonical block/digest before changing the pin—do not disable the check to force delivery. See [ownership trust and delivery recovery](production-delivery.md).

For another collection, create matching host settings and an indexer configuration, then run another indexer with its own state file. The indexer `collection`, `chain` and `contract` must match the host. `config/index.example.json` contains placeholders; choose ERC-721Enumerable discovery or a reviewed deployment/event history with accurate `totalSupply`. Arbitrary ERC-721 contracts may need an adapter; ERC-1155 is not supported. The current snapshot import limit is 2 MB.

## 6. Verify and distribute

Before distributing, use a visitor's EAuth session to link an eligible NFT, accept the invitation, check the role, release the link, and check removal plus the configured DM. Delivery receipts show observed Tlon results; a queued action is not a receipt. Independent/manual access and protected roles can prevent removal as described in [delivery](production-delivery.md).

To make the loaded desk readable by the network, run on the publisher:

```hoon
|public %gater
```

Once you have published it and the moon is reachable, another group host can install it with:

```hoon
|install ~dister-dozzod-sarlev %gater
```

That command is for the future network distribution; publishing the GitHub release does not install or publish the desk on your moon. Each receiving host still needs its own community configuration and workers from this release. Ordinary visitors claiming membership need neither the desk nor the workers. Urbit tracks subsequent desk updates from the publisher; keep worker versions aligned with the distributed desk. See Urbit's [software distribution reference](https://docs.urbit.org/build-on-urbit/userspace/dist).
