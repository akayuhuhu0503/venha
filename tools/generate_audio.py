"""Original deterministic room sounds. Python standard library only; CC0 assets."""
from pathlib import Path
import math
import random
import struct
import wave

RATE = 32000
OUT = Path(__file__).resolve().parents[1] / "assets" / "audio"
TAU = math.tau


def save(name, samples, peak=0.78):
    maximum = max(abs(x) for x in samples) or 1.0
    scale = peak * 32767 / maximum
    pcm = b"".join(struct.pack("<h", max(-32767, min(32767, int(x * scale)))) for x in samples)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(pcm)
    print(f"{name}: {len(samples) / RATE:.2f}s, {len(pcm)} PCM bytes")


def footstep(seed, wood=False):
    rng = random.Random(seed)
    duration = 0.33 if wood else 0.25
    samples, low = [], 0.0
    frequency = (118 if wood else 185) + rng.uniform(-12, 12)
    for index in range(int(RATE * duration)):
        t = index / RATE
        noise = rng.uniform(-1, 1)
        low = low * 0.88 + noise * 0.12
        heel = min(1, t * 900) * math.exp(-t * (29 if wood else 42))
        toe_t = max(0, t - 0.078)
        toe = min(1, toe_t * 700) * math.exp(-toe_t * 52)
        resonance = math.sin(TAU * frequency * t) + 0.32 * math.sin(TAU * frequency * 2.53 * t)
        body = (0.55 * resonance + low * 0.7) if wood else (0.16 * resonance + low * 2.2 + noise * 0.25)
        grit = noise * 0.13 * math.exp(-((t - 0.12) / 0.055) ** 2)
        tail = min(1, (duration - t) * 100)
        samples.append((body * heel + low * toe * 1.8 + grit) * tail)
    return samples


def switch_sound():
    rng = random.Random(750)
    samples = []
    for index in range(int(RATE * 0.10)):
        t = index / RATE
        primary = math.exp(-t * 320) * (rng.uniform(-1, 1) + math.sin(TAU * 1700 * t) * 0.3)
        secondary_t = max(0, t - 0.031)
        secondary = (0.45 * math.exp(-secondary_t * 210) * rng.uniform(-1, 1)) if t > 0.031 else 0
        samples.append((primary + secondary) * min(1, t * 4000))
    return samples


def door_sound(close=False):
    rng = random.Random(751 + int(close))
    duration = 0.65 if close else 0.95
    samples, low, phase = [], 0.0, 0.0
    for index in range(int(RATE * duration)):
        t = index / RATE
        low = 0.91 * low + rng.uniform(-1, 1) * 0.09
        envelope = math.sin(math.pi * min(1, t / duration)) ** 1.5
        phase += TAU * (240 + 45 * math.sin(TAU * t * 1.1)) / RATE
        hinge = (math.sin(phase) * 0.09 + math.sin(phase * 2) * 0.035) * envelope
        impact_t = max(0, t - (0.45 if close else 0.06))
        impact = 0.0
        if t > (0.45 if close else 0.06):
            impact = math.exp(-impact_t * 31) * (low * 2.4 + math.sin(TAU * 88 * impact_t) * 0.4)
        samples.append((hinge + low * envelope * 0.20 + impact) * min(1, t * 300) * min(1, (duration - t) * 80))
    return samples


def loop(kind):
    # Every oscillator completes an integer number of periods in four seconds.
    # The resulting sample boundaries are continuous for native WAV looping.
    duration = 4.0
    rng = random.Random({"fan": 801, "pc": 802, "aquarium": 803}[kind])
    frequencies = []
    for _ in range(30):
        frequency = rng.randrange(60, 4200) / duration
        frequencies.append((frequency, rng.uniform(0, TAU), rng.uniform(0.01, 0.04)))
    samples = []
    for index in range(int(RATE * duration)):
        t = index / RATE
        air = sum(math.sin(TAU * hz * t + phase) * gain / (1 + hz / 1100) for hz, phase, gain in frequencies)
        if kind == "fan":
            spin = 0.085 * math.sin(TAU * 50 * t) + 0.025 * math.sin(TAU * 100 * t)
            sample = spin + air * (0.68 + 0.12 * math.sin(TAU * 6 * t))
        elif kind == "pc":
            sample = air * 0.48 + 0.025 * math.sin(TAU * 120 * t) + 0.008 * math.sin(TAU * 960 * t)
        else:
            pump = 0.055 * math.sin(TAU * 50 * t)
            water = math.sin(TAU * 370 * t + 2.7 * math.sin(TAU * 3 * t)) * (0.018 + 0.016 * math.sin(TAU * 2.25 * t))
            sample = pump + water + air * 0.55
        samples.append(sample)
    return samples


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for surface, wood in [("tile", False), ("wood", True)]:
        for variant in [1, 2]:
            save(f"step_{surface}_{variant}", footstep(710 + variant + 10 * int(wood), wood))
    save("switch", switch_sound(), 0.55)
    save("door", door_sound(), 0.70)
    save("door_close", door_sound(True), 0.70)
    for kind in ["fan", "pc", "aquarium"]:
        save(kind, loop(kind), 0.45)


if __name__ == "__main__":
    main()
