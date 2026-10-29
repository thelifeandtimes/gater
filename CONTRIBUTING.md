# Contributing and releasing

## Branches

- `master` is the default branch and the stable release line. It contains released application code and documentation for that code.
- `develop` is the integration branch for the next release. Do ongoing development here; create feature and fix branches from `develop` as needed and merge them back into `develop`.
- Promote a tested release from `develop` to `master`, then tag the release commit on `master`.

Start new work from an up-to-date `develop`. Feature and fix pull requests target `develop`; release pull requests target `master`. Corrections to documentation for the current release can be merged into `master` without a new application release. Keep those corrections in `develop` as well. Do not force-push shared branch history.

See the [development guide](docs/development.md) for disposable test piers, fixtures and test commands. Keep local piers, credentials, ownership caches and other runtime files out of Git.

## Release process

1. Finish and review the intended changes on `develop`. Update `VERSION`, the version in `desk/desk.docket-0`, `CHANGELOG.md` and installation/compatibility documentation for the release. Check that license files and third-party notices are included in both the source package and `desk/`.
2. Run the relevant Python, JavaScript, Hoon and integration checks described in the development guide. Compile the desk on a disposable fake ship and record the results and any limits in the verification notes. Check the staged files for private runtime data and credentials.
3. Merge the release-ready changes into `master`. Create an annotated `vMAJOR.MINOR.PATCH` tag at that commit. The tag identifies the exact released source.
4. Build the source archive from that tag with `git archive`, include the desk, license documents and installation guide, and generate `SHA256SUMS`. Inspect the extracted package before uploading it with the GitHub release notes.
5. Keep `develop` synchronized with `master` after the release. Further work resumes on `develop` or branches based on it.

Published version tags and download archives stay unchanged; later fixes ship in a new version. The existing `v0.1.0-gplv3` tag records the license supplement made before this workflow was adopted. Future releases use the normal version tag and include their license documents from the outset.

GitHub publication and Urbit desk distribution are separate steps. Publishing a release does not install or update a live ship. Follow the [distribution instructions](docs/install.md#6-verify-and-distribute) when an operator is ready to publish the desk; recipients configure their own RPC access on their ships.
