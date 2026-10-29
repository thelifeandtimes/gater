#!/usr/bin/env python3
"""Load repo files into a fake pier or an explicitly named live ship via Clay.

Uses Clay patches, so imports do not depend on filesystem watcher timing.
The first invocation needs --init to create a new desk. Stop the development
agent before loading schema changes. Live ships require --live-ship ~identity.
The legacy --live-comet option additionally restricts the target to comet rank.
"""
import argparse
from pathlib import Path
import time
import re
from conn import evaluate_target

parser = argparse.ArgumentParser()
parser.add_argument('pier', type=Path)
parser.add_argument('--init', action='store_true')
parser.add_argument('--desk', default='gater', help='Desk name (default: gater)')
target = parser.add_mutually_exclusive_group()
target.add_argument('--live-ship', help='Opt in to this exact livenet ship identity; defaults to fake-only')
target.add_argument('--live-comet', help='Opt in to this exact livenet comet identity; planets and other ships are refused')
parser.add_argument('--files', nargs='+', help='Import only these desk-relative files, then compile the complete agent')
args = parser.parse_args()
if not re.fullmatch('[a-z][a-z0-9-]*', args.desk):
    parser.error('Invalid desk name')
root = Path(__file__).resolve().parents[1] / 'desk'
selected = list(root.rglob('*'))
if args.files:
    if args.init:
        parser.error('--files cannot be combined with --init')
    selected = [(root / name).resolve() for name in args.files]
    if any(not file.is_relative_to(root) or not file.is_file() for file in selected):
        parser.error('Every selected file must exist inside desk/')


def load_source(source):
    try:
        return evaluate_target(args.pier, source.replace('%gater', '%' + args.desk), live_comet=args.live_comet, live_ship=args.live_ship)
    except RuntimeError as error:
        if 'desk-already-exists-omit-init' in str(error):
            raise SystemExit('Desk already exists. Omit --init; saved state was not changed.') from None
        if 'desk-not-found-use-init' in str(error):
            raise SystemExit('Desk not found. Use --init to create it on the selected pier.') from None
        raise


if args.init:
    src = '''=/  m  (strand ,vase)
;<  b=bowl:spider  bind:m  get-bowl
~|  %desk-already-exists-omit-init
?<  (~(has in .^((set desk) %cd /(scot %p our.b)//(scot %da now.b))) %gater)
=/  paths=(list path)  ~[/mar/noun/hoon /mar/hoon/hoon /mar/txt/hoon /mar/txt-diff/hoon /mar/mime/hoon /mar/kelvin/hoon /sys/kelvin]
=/  files=(map path page:clay)
  %-  malt
  %+  turn  paths
  |=  p=path
  [p (rear p) .^(* %cx (weld /(scot %p our.b)/base/(scot %da now.b) p))]
;<  ~  bind:m  (poke [our.b %hood] %helm-pass !>((new-desk:cloy %gater ~ files)))
(pure:m !>(%created))'''
    print(load_source(src))
    time.sleep(1)
print(load_source('''=/  m  (strand ,vase)
;<  b=bowl:spider  bind:m  get-bowl
~|  %desk-not-found-use-init
?>  (~(has in .^((set desk) %cd /(scot %p our.b)//(scot %da now.b))) %gater)
;<  ~  bind:m  (poke [our.b %hood] %kiln-suspend !>(%gater))
(pure:m !>(%suspended))'''))
time.sleep(1)
changes = []
def import_order(file):
    relative = file.relative_to(root)
    # Clay validates each page against its mark, even on a suspended desk.
    priority = {'mar': 0, 'sur': 1, 'lib': 2, 'app': 3}.get(relative.parts[0], 4)
    return priority, str(relative)


for file in sorted(selected, key=import_order):
    if not file.is_file():
        continue
    path = '/' + str(file.relative_to(root)).replace('.', '/')
    mark = file.suffix[1:]
    if mark == 'kelvin':
        value = file.read_text().strip()
    elif mark == 'bill':
        value = '~[' + ' '.join(re.findall(r'%[a-z][a-z0-9-]*', file.read_text())) + ']'
    else:
        number = format(int.from_bytes(file.read_bytes(), 'little'), 'x')
        first = len(number) % 4 or 4
        chunks = [number[:first]] + [number[i:i+4] for i in range(first, len(number), 4)]
        value = '`@t`0x' + '.'.join(chunks)
    changes.append(f'[{path} %mut %{mark} !>({value})]')
for change in changes:
    source = '''=/  m  (strand ,vase)
;<  b=bowl:spider  bind:m  get-bowl
=/  changes=soba:clay  ~[CHANGES]
;<  ~  bind:m  (poke [our.b %hood] %helm-pass !>([%c %info %gater %& changes]))
(pure:m !>(%committed))'''.replace('CHANGES', change)
    load_source(source)
print(f'Imported {len(changes)} files into %{args.desk}.')
time.sleep(1)
print(load_source('''=/  m  (strand ,vase)
;<  b=bowl:spider  bind:m  get-bowl
;<  built=vase  bind:m  (build-file-hard [our.b %gater da+now.b] /app/gater/hoon)
(pure:m !>(%compiled))'''))
print(f'Compile complete. Use |install our %{args.desk} (first install) or |revive %{args.desk} in the selected ship.')
