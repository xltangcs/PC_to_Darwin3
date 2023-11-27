import socket
import numpy as np

addr = ('192.168.0.10', 9996)

def send(d):
    writer = socket.socket()
    writer.connect(addr)
    db = np.array(d, dtype=np.uint32).tobytes()
    writer.send(db)
    writer.close()


def make_head(dir, tik, rst, type, n):
    return [type * 16 + rst * 8 + tik * 4 + dir, n]

flits = []

flits += make_head(3, 0, 0, 2, 2)

flits += [
    0x00028480,
    0x00004000
]

print([hex(p) for p in flits])

send(flits)