# Configuration examples

`collection.example.json` illustrates the proposed configuration model. It is not consumed by a program yet and is disabled by default. Null fields must be resolved before a collection can be enabled. The collection standard still needs verification against the confirmed contract.

Policy values are provisional; see [decisions](../docs/decisions.md). Role IDs must refer to dedicated non-admin roles on a compatible group hosted by the same ship. Providers are private references resolved on the host, never credential-bearing browser configuration.

Store eventual local configuration as `*.local.json`, which Git ignores. Do not include private keys, ship login codes, or RPC credentials in committed examples.
