# Install Gater 0.2.1

Gater runs on the ship hosting the Tlon group. Eyre serves the UI; Gall timers and Iris maintain verified Ethereum and Base ownership. **No host environment variables, Python workers, or external background services are needed to run it.**

## Requirements

- Kernel `%zuse 408`, native `%azimuth`, and compatible Tlon `%groups`/`%channels` agents. Tested interfaces are `%group-action-5`, `%group-foreign-2`, `%chat-dm-action-2` and the v3 group scry, with Vere 4.6.
- Ethereum mainnet JSON-RPC access for effective Azimuth ownership, plus Base mainnet access for Base collections. Providers must support HTTPS, JSON-RPC batches, `finalized` blocks, historical `eth_getLogs`, `eth_getCode`, `eth_call`, and `eth_getTransactionByHash`. Gater never falls back to `latest`.
- A reachable HTTPS origin for Eyre and visitor EAuth. Loopback URLs are useful only on your own computer.

Back up your pier before upgrading using your usual stopped-pier backup procedure. Never run two runtimes against one pier.

## 1. Install the desk

If a publisher distributes `%gater`, use its actual identity in Dojo:

```hoon
|install ~publisher-ship %gater
```

Click the **Gater** tile in Landscape. It opens `/gater/config` on your ship’s web host in a new tab; sign in as the host if prompted. Gater uses direct Eyre URLs, so no glob upload or JavaScript build step is needed. Visitor invite and claim links remain separate from this host tile.

Alternatively, load the source release on the computer running your pier. This optional loader requires Python 3.10+ and `urbit` on `PATH`; these are installation tools, not Gater runtime dependencies.

```sh
git clone --branch v0.2.1 https://github.com/thelifeandtimes/gater.git
cd gater
python3 scripts/install.py /absolute/path/to/pier --init --live-ship '~your-ship'
```

Replace the path and ship identity. The loader verifies the running identity, creates the desk, imports files through Clay and compiles the agent while the desk is suspended. After `Compile complete`, run `|install our %gater` in Dojo. Without `--live-ship`, the tool accepts only disposable fake ships. For an existing desk, omit `--init`, then run `|revive %gater` after successful compilation.

The [GitHub release](https://github.com/thelifeandtimes/gater/releases/tag/v0.2.1) also includes a source archive and `SHA256SUMS`:

```sh
sha256sum --check SHA256SUMS
tar -xzf gater-0.2.1.tar.gz
```

## 2. Save RPC access on the ship

Under **RPC & ownership**, paste an Infura API key with Ethereum mainnet and Base enabled. Gater derives both endpoints on the ship. If using another provider, expand **Custom endpoints** and enter its full HTTPS URLs, including any provider credential in those URLs. A custom endpoint overrides Infura for that network; clearing it restores the Infura fallback.

Ethereum is required even for a Base-only NFT community because Urbit ownership lives on Ethereum/Azimuth. Configure only Ethereum if all your collections are on Ethereum.

Click **Save RPC settings**. Blank fields retain existing credentials; the explicit removal checkboxes clear them. Saved keys and URLs never return in configuration JSON or password fields. The page reports configured networks, scan progress and sanitized errors. Credentials are private Gall state, not collection branding or public artwork settings. They are also recorded in the pier’s event history and backups: removing an active key does not erase historical copies. Rotate compromised credentials at the provider. Use HTTPS for remote configuration, and never enter a wallet private key.

No shell exports or services are involved. The ship polls while it is running, retains checkpoints and in-progress work across reloads, and catches up after downtime. Initial history replay can take considerably longer than subsequent incremental checks. Provider quotas still apply; API usage is billed to the host’s provider account.

## 3. Review the Azimuth bootstrap

Gater starts from a trusted Urbit bootstrap snapshot and verifies the complete finalized Ethereum log suffix, including Urbit L2 transaction inputs. It does not reconstruct or cryptographically prove all pre-bootstrap history.

The release includes a reviewed anchor at Ethereum block **25,421,988**. If your ship has that snapshot, it is retained automatically when verification starts. If your ship has a different snapshot, **Azimuth bootstrap trust** shows its block, canonical hash and noun fingerprint. Review the snapshot source and explicitly choose **Trust this ship’s bootstrap** only if you trust your Urbit installation’s historical state. Gater then independently checks the anchor’s canonical block and all subsequent events. Existing NFT claims must be released before changing an anchor; the UI never silently replaces it. The accepted snapshot is retained so a later `%azimuth` snapshot update does not change Gater’s trust boundary.

A missing or empty bootstrap is not accepted. Wait for native Urbit ownership sync. A fake development ship starts with an empty bootstrap; see the [native RPC guide](native-rpc.md) for test setup.

## 4. Configure a community

Choose **Create a Gated Community +**:

1. Enter a stable collection ID, display name, network and ERC-721 contract.
2. Configure **Ownership indexing**. Use enumeration for an ERC721Enumerable contract. Otherwise select reviewed event history, enter the deployment block, and document the reviewed mint/transfer/burn event coverage. Event mode requires complete Transfer/ERC-2309 history and a working `totalSupply()`. Contracts with unusual or incomplete event semantics need an adapter; ERC-1155 is unsupported. Coverage settings are fixed after the first verified checkpoint.
3. Select a hosted group and membership role, or create them. A new group uses the collection ID and gets `<collection-id>-chat`.
4. Choose recognition behavior: send a DM with the claim link, invite eligible ships, or do nothing. Configure loss of eligibility, optional removal DM and manual approval if desired.
5. Customize the collection pages. Artwork loads only for the authenticated claimant in their browser; Gater stores no artwork or metadata on the ship.
6. Set a reachable public origin under Host settings, without a `/gater` suffix.

Nockmilio’s Base contract is `0x7465e492a183f16c0805e57262898c7bec11808a`. The editor recognizes it and fills the reviewed event-history configuration, starting at deployment block `52544634`.

Choose manual approval or pause delivery **before** configuring real ownership if you want to inspect the first actions. Once verification is healthy, delivery is automatic by default. Share `/gater/<collection-id>`; visitors EAuth and select an NFT at `/gater/<collection-id>/claim`.

## 5. Upgrade from 0.1

1. Pause delivery if you want to review the transition. Stop the v0.1 NFT and Azimuth worker processes/services and disable their automatic restart. Do not run legacy importers alongside native verification.
2. Update the desk through your publisher, or load v0.2.1 source without `--init` and then `|revive %gater`.
3. Save RPC credentials in the host UI. Environment variables from the old worker host are not imported automatically.
4. Review ownership coverage in each community. The Nockmilio preset is automatic; other event-based collections need their reviewed deployment configuration entered in the editor.
5. Wait for native NFT and Azimuth verification. Existing collections, claims, themes, delivery settings and receipts migrate. A compatible verified NFT cursor and its transfer generations are carried forward, then all owners are rechecked. Changed code, conflicting finalized history or coverage changes stop verification rather than silently resetting claims.
6. Resume delivery after checking source status and receipts.

Keep old worker cache files only as optional operator backups. They are no longer used by the desk. Upgrading is a forward state migration; restore a complete pre-upgrade backup if rolling back to v0.1.

### Upgrade from 0.2.0

Update through your publisher, or check out `v0.2.1`, rerun the source loader without `--init`, and run `|revive %gater`. The new Landscape tile appears automatically; refresh Landscape if it was already open. RPC credentials, collections and claims are unchanged by this patch.

## 6. Verify and distribute

Check that the configuration page reports current Azimuth verification and a current finalized checkpoint for each collection. Test EAuth, claim, invitation acceptance, and release with a consenting participant. Review delivery receipts. A release revokes managed roles and, by default, managed membership; independent roles/membership protections still apply.

After loading v0.2.1 or later, revive the desk and publish it through Treaty in Dojo:

```hoon
|revive %gater
:treaty|publish %gater
```

If using a filesystem mount, run `|commit %gater` first. The source loader already commits through Clay, so it does not need a separate `|commit`.

Treaty reads `/desk/docket-0` to advertise the app in Landscape and makes the desk publicly readable. Gater includes this file and its mark/library dependencies starting in v0.2.1. If publication fails with a trace ending in `/desk/docket-0`, run `+tree /=gater=` and check that `/desk/docket-0`, `/mar/docket-0/hoon`, `/lib/docket/hoon` and `/sur/docket/hoon` are present. Reload the complete v0.2.1 desk if they are missing. A running agent in `+vats` does not establish that Docket metadata is installed. See the [Urbit publishing guide](https://docs.urbit.org/build-on-urbit/userspace/dist/software-distribution#publish).

`|public %gater` alone permits direct desk installation but does not add a Treaty catalog listing. Recipients can find the published app under your ship in Landscape, or run `|install ~your-publisher-ship %gater`, then configure their own RPC credentials in their own host UI. Credentials are Gall state and are not distributed with Clay desk source.

Keep `desk/license.txt`, `desk/copyright.txt` and `desk/third-party-notices.txt` in the published desk. GitHub release publication does not itself update a livenet ship.
