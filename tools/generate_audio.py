#!/usr/bin/env python3
"""Generate original, loopable fantasy game music for KonoSuba: Another World.
Only Python's standard library is required. These are original compositions,
not arrangements or copies of any existing anime/game soundtrack.
"""
import math
import os
import random
import wave
from array import array

SAMPLE_RATE = 22050
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets")
TAU = math.tau

def midi_hz(note):
    return 440.0 * (2.0 ** ((note - 69) / 12.0))

def add_note(left, right, start, duration, midi, voice, volume, pan=0.0, vibrato=0.0):
    first = max(0, int(start * SAMPLE_RATE))
    count = min(int(duration * SAMPLE_RATE), len(left) - first)
    if count <= 0:
        return
    freq = midi_hz(midi)
    attack = min(0.035, duration * 0.24)
    release = min(0.16, duration * 0.30)
    pan = max(-1.0, min(1.0, pan))
    gain_l = math.sqrt((1.0 - pan) * 0.5)
    gain_r = math.sqrt((1.0 + pan) * 0.5)
    for j in range(count):
        t = j / SAMPLE_RATE
        env = min(1.0, t / max(attack, 0.001))
        if t > duration - release:
            env *= max(0.0, (duration - t) / max(release, 0.001))
        phase = TAU * freq * t
        if vibrato:
            phase += vibrato * math.sin(TAU * 5.1 * t)
        if voice == "pluck":
            env *= math.exp(-4.2 * t / max(duration, 0.05))
            sample = math.sin(phase) + 0.32 * math.sin(phase * 2.0) + 0.12 * math.sin(phase * 3.0)
        elif voice == "bell":
            env *= math.exp(-3.6 * t / max(duration, 0.05))
            sample = math.sin(phase) + 0.42 * math.sin(phase * 2.71) + 0.18 * math.sin(phase * 4.13)
        elif voice == "flute":
            sample = math.sin(phase) + 0.12 * math.sin(phase * 2.0) + 0.035 * math.sin(phase * 3.0)
        elif voice == "brass":
            sample = math.sin(phase) + 0.30 * math.sin(phase * 2.0) + 0.12 * math.sin(phase * 3.0)
        elif voice == "pad":
            sample = math.sin(phase) + 0.18 * math.sin(phase * 0.5) + 0.08 * math.sin(phase * 2.0)
            env *= 0.78
        elif voice == "bass":
            sample = math.sin(phase) + 0.16 * math.sin(phase * 2.0)
        else:
            sample = math.sin(phase)
        value = sample * env * volume
        idx = first + j
        left[idx] += value * gain_l
        right[idx] += value * gain_r

def add_kick(left, right, start, volume=0.22):
    first = int(start * SAMPLE_RATE)
    count = min(int(0.22 * SAMPLE_RATE), len(left) - first)
    for j in range(max(0, count)):
        t = j / SAMPLE_RATE
        freq = 42.0 + 92.0 * math.exp(-t * 19.0)
        value = math.sin(TAU * freq * t) * math.exp(-t * 17.0) * volume
        left[first + j] += value * 0.72
        right[first + j] += value * 0.72

def add_snare(left, right, start, rng, volume=0.12):
    first = int(start * SAMPLE_RATE)
    count = min(int(0.17 * SAMPLE_RATE), len(left) - first)
    for j in range(max(0, count)):
        t = j / SAMPLE_RATE
        noise = rng.uniform(-1.0, 1.0) * math.exp(-t * 25.0)
        tone = math.sin(TAU * 185.0 * t) * math.exp(-t * 20.0) * 0.25
        value = (noise * 0.72 + tone) * volume
        left[first + j] += value * 0.58
        right[first + j] += value * 0.58

def add_hat(left, right, start, rng, volume=0.035):
    first = int(start * SAMPLE_RATE)
    count = min(int(0.055 * SAMPLE_RATE), len(left) - first)
    for j in range(max(0, count)):
        t = j / SAMPLE_RATE
        value = rng.uniform(-1.0, 1.0) * math.exp(-t * 65.0) * volume
        left[first + j] += value * 0.45
        right[first + j] += value * 0.45

PROGRESSION = [
    (55, [55, 59, 62, 67]),  # G
    (50, [50, 54, 57, 62]),  # D
    (52, [52, 55, 59, 64]),  # Em
    (48, [48, 52, 55, 60]),  # C
]
MELODY = [
    [19, 21, 24, 26, 24, 21, 19, 16],
    [24, 26, 28, 31, 28, 26, 24, 21],
    [21, 24, 26, 28, 31, 28, 26, 24],
    [16, 19, 21, 24, 26, 24, 21, 19],
]

def render_track(filename, bpm, bars, lead, mood, seed):
    beat = 60.0 / bpm
    duration = bars * 4 * beat
    total = int(duration * SAMPLE_RATE)
    left = array("f", [0.0]) * total
    right = array("f", [0.0]) * total
    rng = random.Random(seed)
    for bar in range(bars):
        start = bar * 4 * beat
        root, chord = PROGRESSION[bar % len(PROGRESSION)]
        pattern = MELODY[(bar + (1 if mood == "bright" else 0)) % len(MELODY)]
        # Warm sustained chord bed.
        pad_voice = "pad"
        pad_vol = 0.045 if mood in ("soft", "magic") else 0.035
        for n, note in enumerate(chord[1:]):
            add_note(left, right, start, 3.85 * beat, note + 12, pad_voice, pad_vol, (-0.45 + n * 0.42), 0.018)
        # Bass on the first and third beat.
        for beat_index in (0, 2):
            add_note(left, right, start + beat_index * beat, 1.65 * beat, root - 12, "bass", 0.15 if mood != "battle" else 0.19, -0.12)
        # Arpeggiated strings/plucks.
        arp = [chord[0] + 12, chord[2] + 12, chord[1] + 12, chord[3] + 12,
               chord[0] + 12, chord[2] + 12, chord[1] + 12, chord[3] + 12]
        for step, note in enumerate(arp):
            if mood == "soft" and step % 2:
                continue
            t = start + step * (beat * 0.5)
            add_note(left, right, t, beat * 0.42, note, "pluck", 0.075 if mood != "battle" else 0.06, -0.32 if step % 2 else 0.32)
        # Main melody.
        step_len = beat * (1.0 if mood == "soft" else 0.5)
        for step, degree in enumerate(pattern):
            if mood == "soft" and step % 2:
                continue
            note = root + degree + 12
            t = start + step * step_len
            voice = lead
            vol = 0.105 if lead in ("flute", "bell") else 0.085
            if mood == "battle":
                vol = 0.10
            if mood == "magic":
                vol = 0.12
            add_note(left, right, t, step_len * 0.88, note, voice, vol, 0.16 if step % 2 else -0.16, 0.045 if lead == "flute" else 0.0)
        # Percussion gives the battle/town tracks a gentle pulse.
        if mood in ("bright", "battle"):
            for beat_index in range(4):
                t = start + beat_index * beat
                if beat_index in (0, 2):
                    add_kick(left, right, t, 0.18 if mood == "bright" else 0.24)
                else:
                    add_snare(left, right, t, rng, 0.075 if mood == "bright" else 0.12)
                add_hat(left, right, t + beat * 0.5, rng, 0.025 if mood == "bright" else 0.04)
        elif mood == "magic":
            add_kick(left, right, start, 0.08)
            for beat_index in range(4):
                add_hat(left, right, start + beat_index * beat, rng, 0.022)
    # A short stereo echo adds space without relying on copyrighted samples.
    delay = int(0.115 * SAMPLE_RATE)
    for i in range(delay, total):
        left[i] += left[i - delay] * 0.10
        right[i] += right[i - delay] * 0.13
    peak = max(max(abs(v) for v in left), max(abs(v) for v in right), 0.001)
    gain = 0.82 / peak
    pcm = array("h")
    for l, r in zip(left, right):
        pcm.append(max(-32767, min(32767, int(l * gain * 32767))))
        pcm.append(max(-32767, min(32767, int(r * gain * 32767))))
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, filename)
    with wave.open(path, "wb") as output:
        output.setnchannels(2)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        output.writeframes(pcm.tobytes())
    print(f"Generated {filename}: {duration:.1f}s, {os.path.getsize(path) / (1024 * 1024):.1f} MiB")

def main():
    render_track("axel_theme.wav", 118, 32, "flute", "bright", 101)
    render_track("story_theme.wav", 92, 32, "flute", "soft", 202)
    render_track("battle_theme.wav", 138, 32, "brass", "battle", 303)
    render_track("summon_theme.wav", 120, 16, "bell", "magic", 404)

if __name__ == "__main__":
    main()
