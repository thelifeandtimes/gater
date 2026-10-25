# Development guide

This is a preview desk for disposable development piers. It cannot enable live Tlon delivery. Vere and Python 3 are the only tooling requirements; the page has no npm/build dependency. The current kernel target is `%zuse 408`.

## Boot and load

From the repository root, create a local fake ship (do not run these against a real pier):

```sh
urbit -F nec -c /tmp/gater-dev-nec -b 127.0.0.1 --http-port 8190 --no-dock
```

Use a second terminal:

```sh
python scripts/install.py /tmp/gater-dev-nec --init
```

`--init` is only for a new desk. The loader imports via Clay, suspends the development desk while replacing files, and compiles the complete agent. It leaves the desk suspended if compilation fails; inspect the ship console for the source diagnostic. For later updates omit `--init`. It does not delete files from the pier or reset saved agent state.

In the fake ship's Dojo, start it:

```hoon
|install our %gater
```

For later compatible reloads use `|revive %gater`. Alpha state-schema changes require an explicit migration; do not assume an old schema can load into a new build. The installer never wipes state automatically.

Open `http://127.0.0.1:8190/gater`. The page offers EAuth to visitors and a local host-login link. Use the disposable ship's `+code` for local host login. Do not paste a real ship code into tooling or Git.

## Fixture demo

These fixtures assign two fake ships, `~nec` and `~zod`, to one dummy address with tokens 7 and 8. They are **invented test data**, not Nockmilio ownership.

```sh
python scripts/poke.py /tmp/gater-dev-nec tests/fixtures/settings.json
python scripts/poke.py /tmp/gater-dev-nec tests/fixtures/collection.json
python scripts/poke.py /tmp/gater-dev-nec tests/fixtures/owners.json
python scripts/poke.py /tmp/gater-dev-nec tests/fixtures/nfts.json
```

Sign in as the fake host, refresh, claim a token, and inspect Pending actions. You should see recognition DMs and admission/role intent. No actual DM or Tlon action is sent. Fixture observations expire after 15 minutes; reimport the fixtures when needed. Supplying fixture owners disables native Azimuth polling so it cannot silently replace the scenario.

Sibling replacement, sale/removal, retention and aggregated roles are exercised by the Hoon suite. Remote user input can only name a collection/token/revision; the authenticated source ship is supplied by Gall/Eyre.

## Read an actual ERC-721 collection

1. Inspect the contract to establish deployment block and mint-event coverage.
2. Configure the collection in the host UI or import an edited copy of `config/collection.example.json`.
3. Set `GATER_RPC_URL` privately to an HTTPS Ethereum or Base endpoint. Do not pass the key as a shell argument or save it in this repository.
4. Scan with the verified start block:

```sh
python scripts/scan.py --chain 8453 \
  --contract 0x7465E492a183F16C0805e57262898c7bec11808A \
  --collection nockmilio --from-block VERIFIED_DEPLOYMENT_BLOCK \
  --output output/nockmilio.local.json
python scripts/poke.py /tmp/gater-dev-nec output/nockmilio.local.json
```

Replace `VERIFIED_DEPLOYMENT_BLOCK` with a number. `0` reads all history but may be prohibitively slow. Each run is a full replay and writes output only after verification. Reduce `--window` if the provider refuses a log range. The reader uses only standard-library HTTP/JSON; no signing key is involved.

In Host settings, enable the host ship's `%azimuth` source to refresh its effective owner index every minute. That observation is not a proof of freshness/completeness. See [architecture](architecture.md) for the source limitations and the live-delivery gate. The tool does not read or alter an existing `%eth-watcher` API-key configuration.

## Test

```sh
python -m unittest discover -s tests -p 'test_*.py' -v
python scripts/check.py /tmp/gater-dev-nec
python scripts/check.py /tmp/gater-dev-nec --file tests/actions.hoon
node --check desk/web/app.js
python scripts/http_smoke.py /tmp/gater-dev-nec
```

The Hoon tests run through the test pier's control socket against the loaded desk. They execute reducers and request guards without delivering messages. Compile with `scripts/install.py` first so tests use the current files.

The HTTP smoke test requires the running fixture demo. It signs into the local disposable ship, checks authorization and claims, restores the previous association, and suspends/revives Gater to verify Gall save/load. It reads that test pier's login code internally without printing or saving it.

## JSON actions

`configure`, `settings`, `owners` (test snapshot), `nfts` (test snapshot), `snapshot` (RPC reader output), `suppress` and `unsuppress` require the host identity. `claim` and `release` take `collection`, decimal-string `token`, and decimal-string `revision`. Successful HTTP actions return the actor's new view; errors preserve the previous state. The HTTP POST endpoint additionally requires same-origin headers.

The host-only Gall scry is `/x/state`. It returns JSON with the current revision, collections, actor-visible holdings and proposed effects. It is not a Tlon delivery receipt.
