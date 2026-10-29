#!/usr/bin/env python3
"""Guarded local control: fake ships by default, named live ships by opt-in."""
import argparse
import re
from pathlib import Path
import socket
import subprocess
import tempfile


def hoon_cord(text):
    # Hex atoms avoid quadratic parsing of very large quoted Hoon strings.
    digits = text.encode('utf-8')[::-1].hex().lstrip('0') or '0'
    first = len(digits) % 4 or 4
    groups = [digits[:first]] + [digits[i:i + 4] for i in range(first, len(digits), 4)]
    return '`@t`0x' + '.'.join(groups)


def _run_eval(flags, data):
    # Vere 4.6 can exit after writing only one pipe buffer to stdout. A regular
    # private files preserve large inputs, encoded requests and decoded responses.
    with tempfile.TemporaryFile() as source, tempfile.TemporaryFile() as output:
        source.write(data); source.seek(0)
        subprocess.run(['urbit', 'eval', flags], stdin=source, stdout=output,
                       stderr=subprocess.PIPE, check=True)
        output.seek(0)
        return output.read()


def evaluate(pier, source, dependencies=()):
    # Development tooling must never mutate or inspect a livenet pier's state.
    # Check Jael's runtime fake flag before evaluating the supplied thread.
    _evaluate(pier, '''=/  gater-m  (strand ,vase)
;<  gater-b=bowl:spider  bind:gater-m  get-bowl
~|  %gater-refuses-livenet-pier
?>  .^(? %j /(scot %p our.gater-b)/fake/(scot %da now.gater-b))
(pure:gater-m !>(%gater-fake-only))''')
    return _evaluate(pier, source, dependencies)


def evaluate_target(pier, source, dependencies=(), *, live_comet=None, live_ship=None):
    """Deployment/import entry point. Test runners keep using fake-only evaluate.

    Bind live access to one exact runtime identity. The legacy comet option
    additionally requires comet rank; --live-ship permits a moon or other ship.
    The guard and requested operation run in the same thread on that ship.
    """
    if live_comet is not None and live_ship is not None:
        raise ValueError('Choose --live-ship or --live-comet, not both')
    target = live_ship if live_ship is not None else live_comet
    if target is None:
        return evaluate(pier, source, dependencies)
    kind = 'comet' if live_comet is not None else 'ship'
    if not isinstance(target, str) or not re.fullmatch(r'~[a-z-]{1,150}', target):
        raise ValueError(f'Provide the exact ~ship identity for --live-{kind}')
    guard = f'''=/  gater-m  (strand ,vase)
;<  gater-b=bowl:spider  bind:gater-m  get-bowl
~|  %gater-live-{kind}-identity-mismatch
?>  =('{target}' (scot %p our.gater-b))
'''
    if live_comet is not None:
        guard += '''~|  %gater-live-comet-rank-required
?>  &((gte our.gater-b (bex 64)) (lth our.gater-b (bex 128)))
'''
    guard += f'''~|  %gater-live-{kind}-refuses-fake
?<  .^(? %j /(scot %p our.gater-b)/fake/(scot %da now.gater-b))
'''
    return _evaluate(pier, guard + source, dependencies)


def _evaluate(pier, source, dependencies=()):
    path = Path(pier) / '.urb/conn.sock'
    if not path.is_socket():
        raise RuntimeError(f'No running ship at {path}')
    source = '  '.join(line for line in source.splitlines() if not line.lstrip().startswith('::'))
    escaped = source.replace('\\', '\\\\').replace("'", "\\'")
    arg = f"'{escaped}'"
    if dependencies:
        arg = f"[{arg} ~[{' '.join(dependencies)}]]"
    request = f'[0 %fyrd %base %khan-eval %noun %ted-eval {arg}]\n'
    jam = _run_eval('-jn', request.encode())
    if len(jam) < 5 or jam[0] != 0 or int.from_bytes(jam[1:5], 'little') != len(jam) - 5:
        raise RuntimeError('Failed to encode a complete control request frame')
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
        client.settimeout(55)
        client.connect(str(path))
        client.sendall(jam)
        # Newt is length framed. Half-closing here makes Vere cancel a large
        # pending response; receive the complete frame before closing instead.
        response = bytearray()
        expected = None
        while expected is None or len(response) < expected:
            chunk = client.recv(1024 * 1024 if expected is None else min(1024 * 1024, expected-len(response)))
            if not chunk:
                raise RuntimeError('Incomplete control response frame')
            response.extend(chunk)
            if expected is None and len(response) >= 5:
                expected = 5 + int.from_bytes(response[1:5], 'little')
                if response[0] != 0 or expected > 64 * 1024 * 1024:
                    raise RuntimeError('Invalid control response frame')
        if len(response) != expected:
            raise RuntimeError('Unexpected control response framing')
    answer = _run_eval('-cn', bytes(response)).decode().strip()
    if not answer.startswith('[0 %avow 0 %noun '):
        leaves = re.findall(r'\[%leaf ([\d ]+)\]', answer)
        readable = [''.join(chr(int(n)) for n in leaf.split()[:-1]) for leaf in leaves]
        raise RuntimeError('\n'.join(readable) if readable else answer)
    return answer

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('pier')
    parser.add_argument('source')
    parser.add_argument('dependencies', nargs='*')
    args = parser.parse_args()
    print(evaluate(args.pier, args.source, args.dependencies))
