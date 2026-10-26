#!/usr/bin/env python3
import argparse
import datetime
from pathlib import Path
from conn import evaluate
p = argparse.ArgumentParser()
p.add_argument('pier')
p.add_argument('--ship', default='nec')
p.add_argument('--file', default='tests/policy.hoon')
a = p.parse_args()
now = datetime.datetime.now(datetime.timezone.utc)
when = now.strftime('~%Y.%m.%d..%H.%M.%S') + f'..{int(now.microsecond * 65536 / 1000000):04x}'
libs = [('sur','gater'),('lib','gater-policy')]
if a.file.endswith('actions.hoon'):
    libs += [('lib', 'gater-actions'), ('lib', 'gater-http'), ('lib', 'gater-sources')]
if a.file.endswith('wallet-actions.hoon'):
    libs += [('lib', 'gater-wallet')]
deps = [f"['~{a.ship}' %gater '{when}' %{kind} %{name} %hoon ~]" for kind,name in libs]
source = Path(a.file).read_text()
print(evaluate(a.pier,source,deps))
