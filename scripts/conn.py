#!/usr/bin/env python3
"""Evaluate a thread on an explicitly selected local development pier."""
import argparse
import re
from pathlib import Path
import socket
import subprocess


def evaluate(pier, source, dependencies=()):
    path = Path(pier) / '.urb/conn.sock'
    if not path.is_socket():
        raise RuntimeError(f'No running development ship at {path}')
    source = '  '.join(line for line in source.splitlines() if not line.lstrip().startswith('::'))
    escaped = source.replace('\\', '\\\\').replace("'", "\\'")
    arg = f"'{escaped}'"
    if dependencies:
        arg = f"[{arg} ~[{' '.join(dependencies)}]]"
    request = f'[0 %fyrd %base %khan-eval %noun %ted-eval {arg}]\n'
    jam = subprocess.run(['urbit', 'eval', '-jn'], input=request.encode(), capture_output=True, check=True).stdout
    if not jam:
        raise RuntimeError('Failed to encode the control request')
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
        client.settimeout(55)
        client.connect(str(path))
        client.sendall(jam)
        client.shutdown(socket.SHUT_WR)
        chunks = []
        while True:
            chunk = client.recv(1024 * 1024)
            if not chunk:
                break
            chunks.append(chunk)
    answer = subprocess.run(['urbit', 'eval', '-cn'], input=b''.join(chunks), capture_output=True, check=True).stdout.decode().strip()
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
