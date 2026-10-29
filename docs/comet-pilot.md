# Local livenet comet pilot

This deployment runs a real comet with real Nockmilio ownership on Base. It is a
historical pilot guide for the development machine, not a general installer.
Use [installation](install.md) for a new host. Delivery is now automatic by default
with per-collection manual approval and a global pause. See [delivery controls and trust assumptions](production-delivery.md).

## Open it

- Public claim landing page: <http://127.0.0.1:8192/gater>
- Host login: <http://127.0.0.1:8192/~/login?redirect=/gater/config>
- Comet identity: recorded in your private deployment metadata.
- Pier: `piers/gater-comet`, inside this repository and excluded from Git.
- Deployment metadata: `output/comet.local.json`, also excluded from Git.

Get the comet's login code **in your own terminal**:

```sh
cd ~/repos/gater
python scripts/comet.py code
```

Enter it at the host login link. The command refuses pipes/log capture; do not
paste the code into chat. Host configuration is accessible only through the
comet's own authenticated session. The public page remains available without
signing in. HTTP is bound to loopback; this URL is for this computer, not a public
link to send to other people.

For a claimant, open the public page in a separate browser profile/private
window and use **Continue with EAuth** with an eligible planet or other
Azimuth-backed identity. Approve on that ship, then select a token. The comet
hosts the app but has no Azimuth owner address and cannot itself qualify for an
NFT. An occupied claim requires release from the linked ship or the
current owner's wallet signature; a sibling planet cannot take it unilaterally.
No transaction is needed to claim. Real-ship EAuth and wallet approval remain
manual pilot checks. Eyre's endpoint discovery and approval redirect are
described in the [official EAuth documentation](https://docs.urbit.org/urbit-os/kernel/eyre/eauth).

## Current collection and sources

Nockmilio uses Base contract `0x7465e492a183f16c0805e57262898c7bec11808a` and
`config/index.nockmilio.json`. The policy ID and hosted group are `nockmilio`,
the configured role is `nocker`, and recognition is `none`. Existing collection branding and claims were preserved. Losing/releasing entitlement
removes managed membership by default when delivery is approved/enabled.

The Nockmilio worker reads the shared `~/.config/infura/env` file and selects
`BASE_RPC_URL`. Credentials stay out of service arguments, browser responses
and Git. It resumes the existing verified cursor, refreshes every 60 seconds,
and audits every owner at startup when the previous audit is old, then every
six hours. A full audit may temporarily outlast the agent's freshness window;
claims pause when observations expire. Provider failures retain the local
checkpoint and mark the source failed. There is no signing key in this service.
Complete snapshots use the existing host-only Eyre API, with the local port read
from the selected pier's `.http.ports`. Each import first verifies the runtime
ship identity, obtains a host login in memory and closes that temporary session
afterward. The current API accepts snapshots up to 2 MB; larger collections need
a chunked import extension before they can be loaded.

Native Azimuth supplies the installed bootstrap and effective-L2 event history.
The audit worker verifies the complete finalized suffix against Ethereum RPC;
Gater uses its replayed finalized owners. This inherits the pinned bootstrap's
historical trust. See [ownership verification](production-delivery.md#ownership-trust-boundary).

## Operate it

Three user services are defined in `ops/` for this checkout at `~/repos/gater`:

```sh
systemctl --user status gater-comet gater-nockmilio gater-azimuth
python scripts/comet.py status
python scripts/comet.py check
```

`check` verifies anonymous/host HTTP boundaries using a temporary login in
memory, then logs out that test session. It never prints or saves the code.
The services start on user login. The comet restarts on failure with a bounded
retry limit. The worker depends on the comet and uses the same exact-identity
guard as the installer.

```sh
# Pause the worker and shut down only this comet.
systemctl --user stop gater-nockmilio gater-azimuth gater-comet

# Start this deployment again.
systemctl --user start gater-comet gater-nockmilio gater-azimuth

# Restart this comet and its active worker.
systemctl --user restart gater-comet
```

Do not run another Urbit process against this pier while its service is active.
Stop both services before copying the pier for a backup, and preserve
`output/comet.local.json` plus `output/nockmilio-index.local.json` with it.

## Deploy code changes

```sh
python scripts/install.py piers/gater-comet \
  --live-comet '~your-exact-comet-name'
```

Replace the placeholder identity with the actual comet name from your private
deployment metadata. The installer suspends the desk and compiles the replacement. Use
`|revive %gater` in this comet's Dojo after a successful update. `--init` is only
for the first creation. `scripts/poke.py` and `scripts/index.py --pier` accept
the same explicit `--live-comet` identity. Every live operation verifies exact
identity, comet rank and the runtime non-fake flag. Without the option, imports
remain fake-only. Integration smoke runners remain fake-only under all modes.

## Initial deployment observations

On 2026-10-28 the desk compiled and activated with Vere 4.6 / kernel 408. The
installer refused a mismatched target identity, and the original fake-only
control entry point refused this livenet comet. Public-page access, anonymous
configuration denial, comet host login and protected pages passed on the real
comet. A subsequent clean service restart retained the collection configuration,
restored native Azimuth observation and passed the same HTTP checks. Python
checks passed 67 scenarios. A six-case recognition regression additionally uses
150,000 ship owners and 2,000 NFTs. Recognition now builds a holder-address set
once per collection and skips recognition work entirely for `none`.

The refreshed Base index verified all 1,956 owners, and the complete snapshot was
accepted by the comet at finalized block 53,219,684. Host source health was
healthy/fresh, with native Azimuth observed and transport disabled. After a clean
restart with the imported state, the continuous worker advanced to finalized
block 53,219,895; both services remained running and the HTTP checks passed again. During
deployment, a large-payload control-path issue was isolated: Vere 4.6's encoder
truncated pipe output at 64 KB. Control tooling now uses private temporary files
and verifies complete frames; snapshot imports use authenticated HTTP so the
large JSON is not compiled as Hoon source.

During initial boot, the bundled Tlon desk updated and Vere subsequently exited
with SIGSEGV in `u3_king_commence`, following a broken worker pipe. No core dump
was retained, and the kernel log showed no matching OOM kill; the underlying
cause is undetermined. Restarting recovered the saved Gater installation. This
is recorded as a runtime incident, not a proven Gater failure or a proven fix.
