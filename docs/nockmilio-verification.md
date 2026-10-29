# Nockmilio source checks

Checked on 2026-10-26 using the shared Infura credentials, with read-only calls. Ethereum chain ID 1 and Base chain ID 8453 both responded with finalized checkpoints. Credentials are outside this repository in `~/.config/infura/env`.

## Confirmed collection parameters

- Base contract: `0x7465e492a183f16c0805e57262898c7bec11808a`.
- First deployed bytecode: block **52,544,634**. Historical RPC checks found no code at the preceding block and code at this block.
- Deployment block hash: `0x0f8c563eb3c13ef4c9763af454e32c455ba3e62f1743c79861c28ce072292afc`.
- ERC-721 support: true. ERC-721Enumerable support: false.
- Reported supply: **1,938** at finalized block **53,122,350**, hash `0x5871efa79b4be80f4482a1f42cf78c2d448dc7ab0e67f956fb38dbca21087a9d`.
- Runtime is the standard 45-byte minimal proxy pointing to `0x71210fdf8a6b7ce2deb838332f46724b8ad93fc3`. The implementation's bytecode was identical at the collection deployment and the checked finalized block.

The [published contract source](https://basescan.org/address/0x7465E492a183F16C0805e57262898c7bec11808A#code) identifies ArchetypeErc721a and its ERC721AUpgradeable dependency. The initializer does not mint. `mintTo`, batch minting and `burnToMint` use `_safeMint`, which emits a separate `Transfer` for every minted token. Token IDs start at 1. Inherited transfers and burns emit `Transfer`; `totalSupply` subtracts burns. The reviewed contract does not override these ownership-writing paths. This supports deployment-era event discovery; it is not a general security audit or a review of every proxy collection.

## Completed live owner index

The first replay hit provider throughput limits. The worker now paces requests, honors bounded Retry-After hints, and resumes validated work after interruption. A completed replay on 2026-10-26 verified **1,938 owners** at finalized block **53,128,103**, hash `0xbc8bbca7a3004150f8f6175b6262212bfd6c19830e1361bdadd0a0ee68e889f5`. It replayed deployment-era history, checked canonical log blocks, matched totalSupply, checked every ownerOf and rechecked the checkpoint before atomically publishing the snapshot.

Several process interruptions exercised real bootstrap resumption, including saved progress at 900, 1,500 and 1,925 owner checks. No partial snapshot was exported. A subsequent fresh process advanced to block **53,128,872**, hash `0x4e12b144cb665c52ac02754bca34dd112f25bae09f9f9a8a4d4fcf50e1c56727`, retaining the same epoch and 1,938 holdings. The full-audit timestamp was preserved on this incremental run.

[Infura documents](https://docs.infura.io/get-started/pricing/) a 500-credit/second limit on its free tier; the account's actual plan was not inspected. [HTTP 429 indicates throughput limiting](https://docs.infura.io/get-started/pricing/credit-cost/), while 402 indicates daily credit exhaustion. The worker defaults to 0.6 seconds between RPC attempts and six attempts per transient request. Operators can tune pacing for their provider.

The reviewed configuration is [index.nockmilio.json](../config/index.nockmilio.json). Local scan artifacts are under ignored `output/`. These live reads sent no blockchain transactions and imported nothing into any ship. Tlon integration uses separate invented ownership on fake ships. This is verification at the recorded checkpoints, not a continuously running service or a proof of Azimuth completeness.


## Livenet comet pilot — 2026-10-28

A new full owner audit verified **1,956 tokens**. The dedicated Gater comet
accepted the real snapshot through its authenticated local Eyre API. The worker
then advanced to finalized Base block **53,219,895**, hash
`0xeab8ac30bf8bf3481564b20c71f92f8a80dd6cbea6e70d64cd6881be5fc83cea`, with the existing index epoch preserved.
The host reported healthy/fresh NFT source state and observed native Azimuth
ownership after a clean restart. Continuous polling runs every 60 seconds using
the shared Base RPC environment. Production Tlon delivery is disabled. See the
[comet pilot guide](comet-pilot.md) for access, services and limits.
