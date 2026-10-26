# Development guide

This preview desk cannot enable live Tlon delivery. Use disposable development piers. Vere and Python 3 are required; the page has no npm/build dependency. The tested kernel target is `%zuse 408`.

## Boot and load

From the repository root, boot a local fake ship:

```sh
urbit -F nec -c /tmp/gater-dev-nec -b 127.0.0.1 --http-port 8190 --no-dock
```

In another terminal:

```sh
python scripts/install.py /tmp/gater-dev-nec --init
```

`--init` is only for a new desk. The loader imports via Clay, suspends the development desk during replacement, and compiles the complete agent. It leaves the desk suspended if compilation fails; inspect the ship console for diagnostics. Omit `--init` for updates. It does not reset saved agent state.

In the fake ship's Dojo, run `|install our %gater` for the first install, or `|revive %gater` after an update. State v1 explicitly migrates v0: fixture associations survive; legacy non-fixture claims require reassertion because they lack transfer provenance.

Open `http://127.0.0.1:8190/gater`. This public page offers EAuth and returns visitors to `/gater/claim`. The Host configuration link uses local login and returns the host to `/gater/config`. Use the disposable ship's `+code`; never put a real ship code into tooling or Git.

Configuration HTML, scripts and APIs require an authenticated local host session. A remote authenticated ship can use the claim page but receives 403 for configuration. Member responses omit host settings and the action outbox.

## Fixture demo

These fixtures assign fake ships `~nec` and `~zod` to one dummy address with tokens 7 and 8. They are **invented data**, not Nockmilio holdings.

```sh
python scripts/poke.py /tmp/gater-dev-nec tests/fixtures/settings.json
python scripts/poke.py /tmp/gater-dev-nec tests/fixtures/collection.json
python scripts/poke.py /tmp/gater-dev-nec tests/fixtures/owners.json
python scripts/poke.py /tmp/gater-dev-nec tests/fixtures/nfts.json
```

Sign into `/gater/claim`, claim a token, then inspect Pending actions in `/gater/config`. Recognition DMs and admission/role intent appear, but nothing is sent. Observations expire after 15 minutes; reimport fixtures when needed. Importing fixture owners disables native Azimuth so it cannot silently replace the scenario.

## Index an actual ERC-721 collection

1. Review the contract. Choose ERC-721Enumerable discovery or verified deployment-era event discovery with a meaningful totalSupply. Nonstandard collections need an adapter.
2. Configure its policy in the host UI or import an edited `config/collection.example.json`.
3. Set `GATER_RPC_URL` privately to an HTTPS endpoint for the selected chain. Do not pass API keys as shell arguments or commit them.
4. Copy `config/index.example.json` to a private `*.local.json` file and replace every placeholder. This config describes the indexer separately from the agent's group policy.

```sh
python scripts/index.py --config config/nockmilio.local.json \
  --state output/nockmilio-index.local.json \
  --output output/nockmilio-import.local.json \
  --pier /tmp/gater-dev-nec
# Add --watch --interval 60 to poll continuously.
```

No verified Nockmilio bootstrap configuration is supplied yet. The example uses a dummy address/block. In `events-supply` mode, set the actual `deploymentBlock` and record source/mint review in `reviewedSource`. In `enumerable` mode those two fields may be omitted. Both modes require ERC-721 support and accurate totalSupply. ERC-2309 ranges are supported. ERC-1155 is not. `--max-tokens` changes the default 100,000-token bound.

A single-writer lock protects each state file. Completed checkpoints resume after restart; interrupted initial bootstrap starts again. Provider range errors reduce `--window` automatically. Transient requests retry; watch-mode failures back off up to five minutes, or the configured interval if longer. Every poll validates all current holders, so large collections may need a tuned interval. Python's standard library handles HTTP/JSON; no signing key is involved.

`--pier` imports both successful snapshots and source failures into the selected local host. `--output` is replaced with `source-error` on rejected scans so an old success export is not mistaken for fresh data. Without `--pier`, import the output using `scripts/poke.py`. Failed host imports retry on the next watch poll. If the worker/host is offline, agent observations eventually expire.

For checkpoint divergence or changed bytecode, investigate the provider/contract, back up state, then rerun explicitly with `--rebuild`. This starts a new epoch and requires new claims for that collection. With `--pier`, it pauses the source before rebuilding. Ordinary outages preserve the cursor and claims. `scripts/scan.py` remains a legacy diagnostic; its output lacks provenance and is no longer accepted as an RPC snapshot.

Enable native Azimuth in Host settings to subscribe to ownership events and reconcile every minute. Only actual `%own` entries qualify, not proxies. A fresh subscription baseline clears claims because continuity through a gap is unknown. Ownership sources displays off/connecting/observed/gap, plus NFT import health, coverage, checkpoint and supply. An observation does not prove chain freshness/completeness; see [architecture](architecture.md). The tool does not read or alter existing `%eth-watcher` credentials.

## Tests

```sh
python -m unittest discover -s tests -p 'test_*.py' -v
python scripts/check.py /tmp/gater-dev-nec
python scripts/check.py /tmp/gater-dev-nec --file tests/actions.hoon
python scripts/check.py /tmp/gater-dev-nec --file tests/sources-actions.hoon
python scripts/check.py /tmp/gater-dev-nec --file tests/wallet-actions.hoon
node --check desk/web/landing.js
node --check desk/web/claim.js
node --check desk/web/config.js
python scripts/http_smoke.py /tmp/gater-dev-nec
python scripts/source_smoke.py /tmp/gater-dev-nec
```

Compile/load the current desk first. Hoon tests execute reducers through the control socket without delivering messages. HTTP smoke checks routing, separate member/configuration surfaces, host login, claim authority, restoration and Gall save/load. Source smoke tests a real native subscription, resume, synthetic provenance-bearing imports, failure pause and transfer-generation invalidation, then restores fixtures. The HTTP tests assert the selected pier is fake before reading its code internally; they never print or persist it.

For real EAuth integration, boot another fake ship in its own terminal, then run the test from a separate terminal:

```sh
urbit -F zod -c /tmp/gater-eauth-zod -b 127.0.0.1 --http-port 8191 --no-dock
```

```sh
python scripts/eauth_smoke.py /tmp/gater-dev-nec /tmp/gater-eauth-zod
```

This uses normal HTTP login/approval/callbacks and Ames endpoint discovery. It verifies remote identity, host-only boundaries, unsigned takeover denial, linked-ship transfer, actor binding, restoration, logout and rejection. Use fixture token 8 unclaimed or claimed by the host, with no other remote claim. A newly published endpoint may need to cross the installed Eyre discovery cache's five-minute time boundary before its first lookup succeeds. A 503 at that point is not a Gater authorization failure. Server-side expiry, callback replay and public reverse proxies still need dedicated tests.

## Authorize an occupied claim

The linked ship can expand **Transfer #… to another ship**, enter the receiving Urbit ID, and approve. The recipient must be eligible and must have no other claim in that collection. The linked ship can still release an association normally; an unclaimed NFT is available to eligible ships without a wallet signature.

An eligible receiving ship can instead select **Authorize with owner wallet**, review the exact message, and use an injected Ethereum wallet's `personal_sign`, or paste a signature made over that exact message. This signs an association change only; it does not send a transaction. The verifier supports regular Ethereum key wallets, not ERC-1271 contract wallets. A wallet can sign on a separate device; the receiving ship submits the signature through its EAuth session.

Signatures expire within five minutes and become invalid after a state revision or signed field changes. Refresh to request a new message after a conflict. Keep the configured public host URL stable. A successful use increments the revision and cannot be replayed. No new state schema or claim reset is needed for this authorization upgrade.

To run the independent wallet integration test, install its test-only dependency in a temporary virtual environment (the app itself has no new Python dependency):

```sh
python -m venv /tmp/gater-wallet-tests
/tmp/gater-wallet-tests/bin/pip install -r tests/requirements-wallet.txt
/tmp/gater-wallet-tests/bin/python scripts/wallet_smoke.py /tmp/gater-dev-nec /tmp/gater-eauth-zod
```

This test uses publicly known private key 1 and invented ownership on the fake ships. Never fund that test address. It verifies denial, owner signature recovery, recipient/token/expiry binding, replay protection and linked-ship restoration, then restores the ownership fixtures and prior associations. The browser wallet extension itself is not automated by this test.

## JSON actions

`configure`, `settings`, `owners` (fixture), `nfts` (fixture), `snapshot` (indexer), `source-error`, `suppress` and `unsuppress` require the host identity and use `POST /gater/config/action`. `claim`, `release`, `reassign` and `wallet-claim` use `POST /gater/action`, taking a collection and decimal-string token/revision. `reassign` additionally takes `target`; only the linked eligible ship may call it. `wallet-claim` additionally takes `expires` and a 65-byte hex `signature`; the receiving ship is always the authenticated actor. `POST /gater/wallet-challenge` returns the exact message, expiry, revision and required owner address for an eligible signed-in recipient. It uses the same authentication and CSRF checks and does not change state. Successful requests return the appropriate host or member view; rejected requests preserve state. Both endpoints require same-origin headers. Gall JSON pokes retain host/ship authorization.

The host-only Gall scry `/x/state` returns configuration and proposed effects. These are not Tlon delivery receipts. See [verification](verification.md) and [remaining acceptance checks](acceptance-tests.md).
