#!/usr/bin/env bash
# Shared credentials stay out of service arguments and the ship's web UI.
set +x
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
source "$HOME/.config/infura/env"
exec /usr/bin/python3 -u - <<'PY'
import json, sys
from pathlib import Path
sys.path.insert(0, 'scripts')
from index import main
deployment = json.loads(Path('output/comet.local.json').read_text())
sys.argv = ['index.py', '--config', 'config/index.nockmilio.json',
            '--state', 'output/nockmilio-index.local.json',
            '--output', 'output/nockmilio-import.local.json',
            '--rpc-env', 'BASE_RPC_URL', '--watch', '--interval', '60',
            '--pier', deployment['pier'], '--live-comet', deployment['ship']]
main()
PY
