#!/usr/bin/env python3
"""Send an explicit JSON configuration or ownership input to a local gater."""
import argparse
import json
from pathlib import Path
from conn import evaluate

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('pier')
parser.add_argument('file', type=Path)
args = parser.parse_args()
data = json.dumps(json.loads(args.file.read_text()), separators=(',', ':'), ensure_ascii=True)
cord = data.replace('\\', '\\\\').replace("'", "\\'")
source = f'''=/  m  (strand ,vase)
;<  b=bowl:spider  bind:m  get-bowl
;<  ~  bind:m  (poke [our.b %gater] %json !>((need (de:json:html '{cord}'))))
(pure:m !>(%accepted))'''
print(evaluate(args.pier, source))
