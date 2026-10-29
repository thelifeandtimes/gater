# Development guide

For a live host, use the [installation guide](install.md) and [audited delivery guide](production-delivery.md). This page covers disposable development piers and the fake-only test transport. Vere and Python 3.10+ are required; the page has no npm/build dependency. The tested kernel target is `%zuse 408`.

Start unreleased work on `develop` or a branch based on it. `master` is the default release branch. See [the branch and release workflow](../CONTRIBUTING.md).

## Boot and load

From the repository root, boot a local fake ship:

```sh
urbit -F nec -c /tmp/gater-dev-nec -b 127.0.0.1 --http-port 8190 --no-dock
```

In another terminal:

```sh
python scripts/install.py /tmp/gater-dev-nec --init
```

`--init` is only for a new desk. The loader imports via Clay, suspends the development desk during replacement, and compiles the complete agent. It leaves the desk suspended if compilation fails; inspect the ship console for diagnostics. Omit `--init` for updates. It does not reset saved agent state. `--files` can limit an update to named desk-relative files while still compiling the complete agent.

In the fake ship's Dojo, run `|install our %gater` for the first install, or `|revive %gater` after an update. The current saved envelope v7 includes policy, delivery receipts, community presentation, the ownership audit and automatic/manual controls. It migrates earlier envelopes. The v0 migration remains explicit: fixture associations survive; legacy non-fixture claims require reassertion because they lack transfer provenance.

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
3. Set `GATER_RPC_URL` privately to an HTTPS endpoint for the selected chain, or load shared credentials with `source "$HOME/.config/infura/env"` and select `--rpc-env BASE_RPC_URL` or `--rpc-env ETHEREUM_RPC_URL`. Do not pass API keys as shell arguments or commit them.
4. Copy `config/index.example.json` to a private `*.local.json` file and replace every placeholder. This config describes the indexer separately from the agent's group policy.

```sh
python scripts/index.py --config config/nockmilio.local.json \
  --state output/nockmilio-index.local.json \
  --output output/nockmilio-import.local.json \
  --pier /tmp/gater-dev-nec
# Add --watch --interval 60 to poll continuously.
```

The generic example uses a dummy address/block. `config/index.nockmilio.json` supplies Nockmilio's checked deployment and reviewed mint-event source; its full live replay and incremental restart have passed (see [verification notes](nockmilio-verification.md)). In `events-supply` mode, set the actual `deploymentBlock` and record source/mint review in `reviewedSource`. In `enumerable` mode those two fields may be omitted. Both modes require ERC-721 support and accurate totalSupply. ERC-2309 ranges are supported. ERC-1155 is not. `--max-tokens` changes the default 100,000-token bound.

A single-writer lock protects each state file. Completed checkpoints and interrupted bootstrap work resume after restart. The adjacent `.work` file stores validated log windows and batches of 25 owner checks; it is never imported as a snapshot. Provider range errors reduce `--window` automatically. Transient requests retry; watch-mode failures back off up to five minutes, or the configured interval if longer. Bootstrap validates every holder. Incremental polls validate changed tokens and check supply, bytecode and checkpoint continuity; a complete owner audit runs every six hours by default. Use `--audit-interval 0` for a full audit on every poll. `--rpc-min-interval` defaults to 0.6 seconds and `--rpc-attempts` to six. Python's standard library handles HTTP/JSON; no signing key is involved.

`--pier` imports both successful snapshots and source failures into the selected local host. It defaults to fake-only; a live host requires `--live-ship '~its-exact-name'`. The legacy `--live-comet` option additionally restricts rank to comets. Mismatched identities and fake targets in either live mode are refused. `--output` is replaced with `source-error` on rejected scans so an old success export is not mistaken for fresh data. Without `--pier`, import the output using `scripts/poke.py` with the same target option. Failed host imports retry on the next watch poll. If the worker/host is offline, agent observations eventually expire.

Complete snapshots use the host-only Eyre API on the selected pier's local HTTP port. The importer verifies the fake/explicit-live-identity guard before reading the host code, keeps credentials and cookies only in memory, uses same-origin request headers and closes its temporary session. The current HTTP snapshot limit is 2 MB; the scanner's token-count limit does not override that import limit. Other small control actions continue through the guarded local socket. Vere encoding output is captured in a private temporary file and checked for a complete Newt frame, avoiding truncated pipe output.

For checkpoint divergence or changed bytecode, investigate the provider/contract, back up state, then rerun explicitly with `--rebuild`. This starts a new epoch and requires new claims for that collection. With `--pier`, it pauses the source before rebuilding. Ordinary outages preserve the cursor and claims. `scripts/scan.py` remains a legacy diagnostic; its output lacks provenance and is no longer accepted as an RPC snapshot.

Enable native Azimuth in Host settings to subscribe to ownership events and reconcile every minute. Only actual `%own` entries qualify, not proxies. A fresh subscription baseline clears claims because continuity through a gap is unknown. Ownership sources displays off/connecting/observed/gap, plus NFT import health, coverage, checkpoint and supply. An observation does not prove chain freshness/completeness; see [architecture](architecture.md). The tool does not read or alter existing `%eth-watcher` credentials.

## Tests

```sh
python -m unittest discover -s tests -p 'test_*.py' -v
node tests/artwork.cjs
node tests/community.cjs
python scripts/check.py /tmp/gater-dev-nec
python scripts/check.py /tmp/gater-dev-nec --file tests/actions.hoon
python scripts/check.py /tmp/gater-dev-nec --file tests/sources-actions.hoon
python scripts/check.py /tmp/gater-dev-nec --file tests/wallet-actions.hoon
python scripts/check.py /tmp/gater-dev-nec --file tests/recognition-scale.hoon
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

This uses normal HTTP login/approval/callbacks and Ames endpoint discovery. It verifies remote identity, host-only boundaries, unsigned takeover denial, release/reclaim, actor binding, restoration, logout and rejection. Use fixture token 8 unclaimed or claimed by the host, with no other remote claim. A newly published endpoint may need to cross the installed Eyre discovery cache's five-minute time boundary before its first lookup succeeds. A 503 at that point is not a Gater authorization failure. Server-side expiry, callback replay and public reverse proxies still need dedicated tests.

## Authorize an occupied claim

The linked ship can release its association. Another eligible ship with no existing claim in that collection can then select the NFT and confirm membership. There is no transfer-to-another-ship form. An unclaimed NFT is available to eligible ships without a wallet signature.

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

`configure`, `settings`, `owners` (fixture), `nfts` (fixture), `snapshot` (indexer), `source-error`, `suppress` and `unsuppress` require the host identity and use `POST /gater/config/action`. `claim`, `release` and `wallet-claim` use `POST /gater/action`, taking a collection and decimal-string token/revision. The member `reassign` action is removed; release and claim instead. `wallet-claim` additionally takes `expires` and a 65-byte hex `signature`; the receiving ship is always the authenticated actor. `POST /gater/wallet-challenge` returns the exact message, expiry, revision and required owner address for an eligible signed-in recipient. It uses the same authentication and CSRF checks and does not change state. Successful requests return the appropriate host or member view; rejected requests preserve state. Both endpoints require same-origin headers. Gall JSON pokes retain host/ship authorization.

The host-only Gall scry `/x/state` returns configuration and proposed effects. Test tools check the runtime Jael fake flag before every evaluation and refuse livenet piers. Only deployment/import tools have explicit live-target options. Exact-identity and non-fake checks execute in the same thread as the operation; the legacy comet option additionally checks rank. These are not Tlon delivery receipts. See [verification](verification.md) and [remaining acceptance checks](acceptance-tests.md).

## Fake-only Tlon transport

Use disposable `~nec` and `~zod` with a complete Tlon desk assembled from `tlon-apps` commit `e599fabcf4f715cfda67f73439c2e0871189bee1` (kernel 408). This adapter uses `%group-action-5`, `%group-foreign-2`, `%chat-dm-action-2` and the versioned v3 group scry. Assemble the complete desk with that repository's `scripts/assemble-desk.sh`; commit and build it on each fake ship before testing. No existing livenet ship is needed.

```sh
python scripts/check.py /tmp/gater-dev-nec --file tests/tlon.hoon
python scripts/check.py /tmp/gater-dev-nec --file tests/delivery.hoon
python scripts/tlon_smoke.py /tmp/gater-dev-nec /tmp/gater-eauth-zod
```

The smoke runner enables transport through a host-only Gall JSON `test-transport` action with an explicit fake recipient list. It cannot be enabled through the HTTP configuration API and independently requires the runtime fake flag. The runner sends actual test DMs and invitations between these fake ships using invented ownership, checks role assignment and removal, invite-all/pending cancellation and preservation of later manual roles, and disables transport in its cleanup. Test groups and messages remain for inspection. Run on disposable fixture piers; it changes their fixture ownership and retires each test collection afterward.

The `/x/delivery` JSON scry exposes test receipts separately from policy previews. A DM receipt means a local Tlon message was observed; the integration test separately checks remote receipt. Group receipts require observed state. A negative acknowledgement is retained and can be explicitly cleared by the fake-only test control; uncertain or merely acknowledged operations cannot be cleared by that command or blindly retried. The ledger survives Gall save/load. This is an engineering test mode, not a production rollout switch.

The card-based host editor and collection-specific pages are described in
[community management](community-ui.md). Run the additional pure and integration
checks on a disposable fake host with Tlon installed:

```sh
python scripts/check.py /tmp/gater-dev-nec --file tests/community.hoon
python scripts/community_smoke.py /tmp/gater-dev-nec
```

The latter creates a private test group, initial chat and role, then removes its
Gater collection while preserving those Tlon objects as evidence. It never
sends recognition DMs/invitations or enables membership delivery.

## Current production pilot

The earlier fixture-preview sections describe development without a finalized audit.
See [production delivery](production-delivery.md) for the audited live mode and
[community UI](community-ui.md) for current routes, appearance and artwork.
