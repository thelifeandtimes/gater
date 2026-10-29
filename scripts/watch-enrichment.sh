#!/usr/bin/env bash
set +x
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
source "$HOME/.config/infura/env"
case "${1:-}" in
  audit) exec /usr/bin/python3 -u scripts/audit_azimuth.py --watch ;;
  *) exit 2 ;;
esac
