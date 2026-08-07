#!/usr/bin/env python3
"""Cliente RCON para servidores GoldSrc (CS 1.6, TFC, ...) via UDP.

Uso:
    python3 rcon.py <host> <port> <senha> <comando>

Exemplo:
    python3 rcon.py 127.0.0.1 27015 admin123 'changelevel de_dust2_fundo'
    python3 rcon.py 127.0.0.1 27015 admin123 'yb add t'
    python3 rcon.py 127.0.0.1 27015 admin123 'yb kickall'
"""
import socket
import sys
import re


def rcon(host, port, password, command, timeout=5):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.settimeout(timeout)
    try:
        s.sendto(b"\xff\xff\xff\xffgetchallenge\n", (host, port))
        data, _ = s.recvfrom(4096)
        m = re.search(rb"A\d+\s+(\d+)", data)
        if not m:
            return "challenge nao recebido"
        payload = f"rcon {m.group(1).decode()} {password} {command}\n".encode()
        s.sendto(b"\xff\xff\xff\xff" + payload, (host, port))
        resp, _ = s.recvfrom(4096)
        if resp[:5] == b"\xff\xff\xff\xffl":
            return resp[5:].decode(errors="replace")
        return resp.decode(errors="replace")
    finally:
        s.close()


if __name__ == "__main__":
    if len(sys.argv) != 5:
        print(__doc__)
        sys.exit(1)
    host, port, pw, cmd = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4]
    print(rcon(host, port, pw, cmd))