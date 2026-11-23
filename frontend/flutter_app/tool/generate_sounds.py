"""Generate CodeBud's sound effects as small WAV files.

The sounds are synthesized here instead of downloaded, so they have no licensing
questions and can be tweaked and regenerated:

    python tool/generate_sounds.py

The files are written to assets/sounds/. Only the Python standard library is used.
"""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parent.parent / "assets" / "sounds"


def tone(freq: float, dur: float, vol: float = 0.5, shape: str = "sine", attack: float = 0.01, decay: float = 4.0):
    """A note with a quick attack and an exponential fade, so it never clicks."""
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        phase = 2 * math.pi * freq * t
        if shape == "sine":
            s = math.sin(phase)
        elif shape == "triangle":
            s = 2 / math.pi * math.asin(math.sin(phase))
        else:  # soft square: a few odd harmonics
            s = sum(math.sin(phase * k) / k for k in (1, 3, 5)) * 0.8
        env = min(1.0, t / attack) * math.exp(-decay * t / dur)
        out.append(s * env * vol)
    return out


def sweep(f0: float, f1: float, dur: float, vol: float = 0.5, decay: float = 3.0):
    n = int(RATE * dur)
    out, phase = [], 0.0
    for i in range(n):
        t = i / RATE
        f = f0 + (f1 - f0) * (i / n)
        phase += 2 * math.pi * f / RATE
        env = min(1.0, t / 0.005) * math.exp(-decay * t / dur)
        out.append(math.sin(phase) * env * vol)
    return out


def noise_burst(dur: float, vol: float = 0.4, seed: int = 1):
    rng = random.Random(seed)
    n = int(RATE * dur)
    return [rng.uniform(-1, 1) * math.exp(-30 * i / n) * vol for i in range(n)]


def silence(dur: float):
    return [0.0] * int(RATE * dur)


def mix(*tracks):
    length = max(len(t) for t in tracks)
    return [sum(t[i] for t in tracks if i < len(t)) for i in range(length)]


def seq(*parts):
    return [s for p in parts for s in p]


def write(name: str, samples):
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = min(1.0, 0.9 / peak)
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(s * scale * 32767)) for s in samples))
    print(f"wrote {name} ({len(samples) / RATE:.2f}s)")


# Musical notes (Hz)
C5, E5, G5, C6, E6, G6 = 523.25, 659.25, 783.99, 1046.5, 1318.5, 1568.0
A4, F4, D4 = 440.0, 349.23, 293.66


def main():
    # Tap: a short, bright pop when a block is added.
    write("tap.wav", tone(880, 0.07, 0.5, "triangle", decay=6))
    # Step: a soft blip each time the robot moves.
    write("step.wav", tone(660, 0.06, 0.35, "sine", decay=5))
    # Bump: a low wobble plus a thud for hitting a wall or rock.
    write("bump.wav", mix(sweep(220, 90, 0.28, 0.6, decay=4), noise_burst(0.08, 0.25)))
    # Try again: a gentle falling "hmm" when the star isn't reached. Encouraging, not harsh.
    write("try_again.wav", seq(tone(G5, 0.16, 0.4, "triangle"), tone(E5, 0.16, 0.4, "triangle"), tone(C5, 0.3, 0.4, "triangle")))
    # Success: a rising arpeggio and a sparkle, with claps underneath.
    arpeggio = seq(
        tone(C5, 0.11, 0.45, "square"),
        tone(E5, 0.11, 0.45, "square"),
        tone(G5, 0.11, 0.45, "square"),
        mix(tone(C6, 0.5, 0.5, "square", decay=3), tone(E6, 0.5, 0.25), tone(G6, 0.5, 0.15)),
    )
    claps = seq(*(seq(noise_burst(0.05, 0.35, seed=i), silence(0.11)) for i in range(5)))
    write("success.wav", mix(arpeggio, seq(silence(0.33), claps)))
    # Star: a bell-like chime played for each star in the popup.
    write("star.wav", mix(tone(E6, 0.35, 0.4, "sine", decay=5), tone(E6 * 2, 0.35, 0.15, "sine", decay=7)))


if __name__ == "__main__":
    main()
