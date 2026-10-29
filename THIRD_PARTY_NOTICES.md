# Third-party code

The standard Urbit mark files under `desk/mar/` derive from Urbit; see [Urbit MIT license](licenses/urbit-MIT.txt). The text and text-diff marks were copied from the local Urbit checkout at `50c7f5239610fc72263df7aa99b4d171cfe9d408`.

`desk/mar/docket-0.hoon`, `desk/lib/docket.hoon` and `desk/sur/docket.hoon` are copied unchanged from that same `urbit/urbit` commit, `pkg/landscape/`. They retain the [Urbit MIT license](licenses/urbit-MIT.txt).

`desk/lib/ethereum.hoon`, `desk/lib/naive.hoon` and `desk/lib/tiny.hoon` are copied unchanged from `urbit/urbit` commit `50c7f5239610fc72263df7aa99b4d171cfe9d408`, `pkg/arvo/lib/`. Their original MIT notice is also preserved in [docs/urbit-vendor-LICENSE.txt](docs/urbit-vendor-LICENSE.txt).

`desk/lib/default-agent.hoon`, `skeleton.hoon`, `server.hoon`, and the other standard marks were copied from the owner's local `omachan/desk` scaffolding. That repository carries Fang's MIT notice, reproduced in [licenses/fang-MIT.txt](licenses/fang-MIT.txt). They are standard agent/HTTP/mark support code, not Gater's policy implementation.

Gater's original code, including v0.1.0, is licensed under GNU GPL version 3 only (`GPL-3.0-only`); see [LICENSE](LICENSE) and [COPYRIGHT](COPYRIGHT). The vendored sources retain the notices and licenses listed above. Copies of the full third-party notices are included in `desk/third-party-notices.txt` for Urbit distribution.
