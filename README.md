# Gater

`%gater` is a planned Urbit desk and Gall agent for managing NFT-based invitations and roles in Tlon Messenger groups. The group host runs the agent and serves a claim page through Eyre.

**Status:** design and implementation plan. This repository does not yet contain a runnable desk. No live invitations, role changes, or chain transactions have been performed.

The intended flow is:

1. Resolve Urbit IDs to their effective Azimuth owner, including Azimuth L2.
2. Track selected NFT collections on Ethereum mainnet or Base.
3. Invite every eligible ID whose owner address also holds a selected NFT.
4. Let a member sign into the host's claim page with EAuth and associate one held NFT with their ship.
5. Grant the configured role to the associated ship and reconcile it when ownership or the association changes.

For example, an address owning three planets and one Nockmilio can receive three invitations, but that NFT can support only one active ship association. Moving the association removes the old ship's managed role before granting it to the new ship.

The proposed uniqueness scope is **one NFT per ship per collection, across all groups managed by this host**, and one ship per NFT. Independent hosts cannot enforce a shared global mapping without an additional shared authority. These scope choices remain open for confirmation.

Start with the [implementation plan](docs/implementation-plan.md). The supporting documents cover:

- [Architecture and behavior](docs/architecture.md)
- [Verified interfaces and integration risks](docs/integrations.md)
- [Decisions and outstanding inputs](docs/decisions.md)
- [Acceptance scenarios](docs/acceptance-tests.md)
- [Illustrative collection configuration](config/collection.example.json)

The recommended implementation keeps state, authentication, and policy on the host ship. It uses the ship's `%azimuth` data where sufficiently complete and current, and makes NFT JSON-RPC reads through Iris. Reusing `%eth-watcher` is an option to validate, not an assumption about Base support or finality.

An Infura key is not needed to finish the design. Implementation will need a Base RPC endpoint and access to an appropriate Ethereum ownership source. Credentials belong in private host configuration, not this repository or the browser.
