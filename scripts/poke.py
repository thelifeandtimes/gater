#!/usr/bin/env python3
"""Send an explicit JSON configuration or ownership input to a local gater."""
import argparse
import json
from pathlib import Path
from conn import evaluate_target, hoon_cord

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('pier')
parser.add_argument('file', type=Path)
target = parser.add_mutually_exclusive_group()
target.add_argument('--live-ship', help='Opt in to this exact livenet ship identity; defaults to fake-only')
target.add_argument('--live-comet', help='Opt in to this exact livenet comet identity; defaults to fake-only')
args = parser.parse_args()
payload = json.loads(args.file.read_text())
if payload.get('action') == 'snapshot':
    from index import import_payload
    import_payload(args.pier, payload, live_comet=args.live_comet, live_ship=args.live_ship)
    print('Snapshot accepted by the selected host.')
    raise SystemExit(0)
data = json.dumps(payload, separators=(',', ':'), ensure_ascii=True)
cord = hoon_cord(data)
source = f'''=/  m  (strand ,vase)
;<  b=bowl:spider  bind:m  get-bowl
;<  ~  bind:m  (poke [our.b %gater] %json !>((need (de:json:html {cord}))))
(pure:m !>(%accepted))'''
print(evaluate_target(args.pier, source, live_comet=args.live_comet, live_ship=args.live_ship))
