"""
Synthesizes Grow a Brainrot's original sound pack (no samples, no copyright
issues): UI sounds, gameplay sounds and two music loops.

    python tools/make_audio.py          # writes assets/audio/*.wav

Then upload them (tools/upload_audio.py, or Studio's Asset Manager) and the
IDs go into src/shared/Config/Sounds.luau.
"""

import os
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
rng = np.random.default_rng(67)


# ---------------------------------------------------------------- building blocks

def t_axis(seconds, sr=SR):
    return np.arange(int(seconds * sr)) / sr


def freq_of(note):
    """MIDI note number -> Hz"""
    return 440.0 * 2 ** ((note - 69) / 12)


def osc(freq, seconds, shape="sine", sr=SR, phase=0.0):
    """freq may be a float or an array (for sweeps)."""
    n = int(seconds * sr)
    if np.ndim(freq):
        f = np.asarray(freq, dtype=float)[:n]
        if len(f) < n:  # a shorter sweep holds its last pitch
            f = np.concatenate([f, np.full(n - len(f), f[-1])])
    else:
        f = np.full(n, float(freq))
    ph = 2 * np.pi * np.cumsum(f) / sr + phase
    if shape == "sine":
        return np.sin(ph)
    if shape == "triangle":
        return 2 / np.pi * np.arcsin(np.sin(ph))
    if shape == "square":  # soft square: odd harmonics, rolled off (less harsh)
        return sum(np.sin(k * ph) / k for k in (1, 3, 5, 7, 9)) * 0.9
    if shape == "saw":
        return sum(np.sin(k * ph) / k * (-1) ** (k + 1) for k in range(1, 9)) * 0.6
    raise ValueError(shape)


def sweep(f0, f1, seconds, curve="exp", sr=SR):
    x = np.linspace(0, 1, int(seconds * sr))
    if curve == "exp":
        return f0 * (f1 / f0) ** x
    return f0 + (f1 - f0) * x


def env(n, attack=0.005, decay=0.1, sustain=0.0, release=0.05, sr=SR, hold=0.0):
    a, d, h, r = (int(x * sr) for x in (attack, decay, hold, release))
    parts = [np.linspace(0, 1, max(a, 1)), np.ones(h), np.linspace(1, sustain, max(d, 1))]
    body = np.concatenate(parts)
    rest = n - len(body) - r
    if rest > 0:
        body = np.concatenate([body, np.full(rest, sustain)])
    tail = np.linspace(body[-1] if len(body) else 0, 0, max(r, 1))
    out = np.concatenate([body, tail])
    if len(out) < n:
        out = np.concatenate([out, np.zeros(n - len(out))])
    return out[:n]


def pluck_env(n, decay=8.0, sr=SR):
    return np.exp(-decay * np.arange(n) / sr) * env(n, attack=0.002, decay=0, sustain=1, release=0.01)


def noise(seconds, sr=SR):
    return rng.uniform(-1, 1, int(seconds * sr))


def lowpass(x, cutoff, sr=SR):
    a = np.exp(-2 * np.pi * cutoff / sr)
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - a) * v + a * acc
        y[i] = acc
    return y


def highpass(x, cutoff, sr=SR):
    return x - lowpass(x, cutoff, sr)


def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = np.zeros(n)
    for t in tracks:
        out[: len(t)] += t
    return out


def at(track, start_seconds, total_seconds=None, sr=SR):
    """place a track at a time offset"""
    pad = np.zeros(int(start_seconds * sr))
    out = np.concatenate([pad, track])
    if total_seconds:
        n = int(total_seconds * sr)
        out = np.concatenate([out, np.zeros(max(0, n - len(out)))])[:n]
    return out


def reverb(x, amount=0.25, sr=SR):
    out = np.concatenate([x, np.zeros(int(0.35 * sr))])
    dry = out.copy()
    for delay, gain in ((0.031, 0.5), (0.047, 0.42), (0.071, 0.33), (0.113, 0.25), (0.163, 0.18), (0.229, 0.12)):
        d = int(delay * sr)
        out[d:] += dry[:-d] * gain * amount * 2
    return out


def tone(note, seconds, shape="triangle", decay=10.0, vol=1.0):
    n = int(seconds * SR)
    return osc(freq_of(note), seconds, shape) * pluck_env(n, decay) * vol


def finish(x, peak=0.7, fade=0.01):
    x = x - np.mean(x)
    m = np.max(np.abs(x)) or 1
    x = x / m * peak
    f = int(fade * SR)
    if f and len(x) > f:
        x[-f:] *= np.linspace(1, 0, f)
    return x


def save(name, x, sr=SR):
    os.makedirs(OUT, exist_ok=True)
    data = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(data.tobytes())
    print(f"  {name}.wav  {len(x) / sr:.2f}s")


# ---------------------------------------------------------------- UI

def ui_click():
    n = int(0.07 * SR)
    body = osc(sweep(1400, 700, 0.07), 0.07, "sine") * env(n, 0.001, 0.06, 0, 0.005)
    tick = highpass(noise(0.01), 3000) * env(int(0.01 * SR), 0.0005, 0.008, 0, 0.001) * 0.4
    return finish(mix(body, tick), 0.55)


def ui_hover():
    n = int(0.04 * SR)
    return finish(osc(2200, 0.04, "sine") * env(n, 0.002, 0.03, 0, 0.005), 0.18)


def ui_open():
    s = 0.22
    n = int(s * SR)
    whoosh = lowpass(noise(s), 2500) * env(n, 0.06, 0.15, 0, 0.01) * 0.6
    up = osc(sweep(300, 900, s), s, "triangle") * env(n, 0.01, 0.2, 0, 0.01) * 0.5
    return finish(reverb(mix(whoosh, up), 0.2), 0.5)


def ui_close():
    s = 0.2
    n = int(s * SR)
    whoosh = lowpass(noise(s), 2000) * env(n, 0.02, 0.17, 0, 0.01) * 0.6
    down = osc(sweep(800, 280, s), s, "triangle") * env(n, 0.005, 0.18, 0, 0.01) * 0.5
    return finish(reverb(mix(whoosh, down), 0.15), 0.45)


def ui_select():
    return finish(reverb(mix(tone(84, 0.12, "sine", 25), at(tone(91, 0.15, "sine", 22), 0.04)), 0.2), 0.45)


def ui_error():
    s = 0.22
    a = tone(52, s, "square", 12, 0.6)
    b = at(tone(49, s, "square", 12, 0.6), 0.09)
    return finish(lowpass(mix(a, b), 1800), 0.45)


def notify():
    return finish(reverb(mix(tone(81, 0.3, "sine", 9), at(tone(88, 0.4, "sine", 7), 0.09)), 0.3), 0.5)


def coin(start=0.0, note=96):
    a = tone(note, 0.25, "square", 18, 0.5)
    b = at(tone(note + 5, 0.35, "square", 12, 0.5), 0.06)
    return at(lowpass(mix(a, b), 6000), start)


def purchase():
    return finish(reverb(mix(coin(0, 91), at(tone(79, 0.3, "triangle", 8, 0.6), 0.0)), 0.25), 0.6)


def sell():
    return finish(reverb(mix(coin(0, 89), coin(0.07, 93)), 0.25), 0.55)


# ---------------------------------------------------------------- gameplay

def plant():
    s = 0.18
    n = int(s * SR)
    thump = osc(sweep(180, 60, s), s, "sine") * env(n, 0.002, 0.15, 0, 0.02)
    dirt = lowpass(noise(s), 1200) * env(n, 0.002, 0.08, 0, 0.02) * 0.5
    return finish(mix(thump, dirt), 0.6)


def pop_base(pitch=1.0):
    s = 0.16
    n = int(s * SR)
    bubble = osc(sweep(250 * pitch, 1100 * pitch, 0.07), s, "sine") * env(n, 0.001, 0.12, 0, 0.02)
    snap = highpass(noise(0.02), 2500) * env(int(0.02 * SR), 0.0005, 0.015, 0, 0.002) * 0.5
    return mix(bubble, snap)


def pop():
    sparkle = mix(*(at(tone(n, 0.18, "sine", 20, 0.35), 0.05 + i * 0.035) for i, n in enumerate((88, 93, 96))))
    return finish(reverb(mix(pop_base(), sparkle), 0.25), 0.65)


def pop_rare():
    arp = mix(*(at(tone(n, 0.3, "triangle", 9, 0.5), 0.06 + i * 0.06) for i, n in enumerate((72, 76, 79, 84, 88, 91))))
    shimmer = at(lowpass(highpass(noise(0.6), 4000), 9000) * env(int(0.6 * SR), 0.1, 0.5, 0, 0.01) * 0.15, 0.05)
    return finish(reverb(mix(pop_base(1.2), arp, shimmer), 0.35), 0.7)


def collect():
    coins = mix(*(coin(i * 0.045, 91 + (i % 3) * 2) for i in range(7)))
    return finish(reverb(coins, 0.25), 0.6)


def cash_small():
    return finish(reverb(coin(0, 96), 0.15), 0.45)


def reveal_tick():
    n = int(0.03 * SR)
    return finish(osc(1800, 0.03, "triangle") * env(n, 0.0005, 0.025, 0, 0.002), 0.35)


def reveal_land():
    s = 0.35
    n = int(s * SR)
    hit = osc(sweep(220, 70, 0.2), s, "sine") * env(n, 0.001, 0.25, 0, 0.05)
    chord = mix(*(tone(nn, s, "triangle", 7, 0.35) for nn in (72, 76, 79)))
    return finish(reverb(mix(hit, chord), 0.25), 0.65)


def reveal_rare():
    # little fanfare: da-da-da-DAAA
    notes = [(72, 0.0, 0.12), (76, 0.1, 0.12), (79, 0.2, 0.12), (84, 0.3, 0.7)]
    lead = mix(*(at(tone(n, d, "square", 4 if d > 0.5 else 14, 0.5), s) for n, s, d in notes))
    pad = at(mix(*(tone(n, 0.8, "triangle", 3, 0.3) for n in (60, 64, 67))), 0.3)
    return finish(reverb(lowpass(mix(lead, pad), 7000), 0.35), 0.7)


def mutation_hit():
    s = 0.7
    n = int(s * SR)
    sweep_up = osc(sweep(400, 2400, 0.4), s, "sine") * env(n, 0.01, 0.6, 0, 0.05) * 0.4
    sparkle = mix(*(at(tone(nn, 0.25, "sine", 15, 0.3), 0.1 + i * 0.05) for i, nn in enumerate((96, 100, 103, 108))))
    return finish(reverb(mix(sweep_up, sparkle), 0.4), 0.65)


def unlock():
    arp = mix(*(at(tone(n, 0.25, "triangle", 10, 0.5), i * 0.07) for i, n in enumerate((67, 71, 74, 79, 83))))
    return finish(reverb(arp, 0.3), 0.6)


def luck_event():
    s = 1.4
    n = int(s * SR)
    riser = osc(sweep(200, 1600, s), s, "saw") * env(n, 0.8, 0.5, 0, 0.1) * 0.25
    riser = lowpass(riser, 3000)
    chimes = mix(*(at(tone(nn, 0.4, "sine", 6, 0.4), 0.9 + i * 0.07) for i, nn in enumerate((84, 88, 91, 96))))
    return finish(reverb(mix(riser, chimes), 0.4), 0.65)


def restock():
    bell = mix(tone(88, 0.8, "sine", 4, 0.6), tone(100, 0.6, "sine", 6, 0.25), at(tone(93, 0.8, "sine", 4, 0.5), 0.15))
    return finish(reverb(bell, 0.35), 0.55)


def announce():
    notes = [(79, 0.0), (84, 0.12), (88, 0.24)]
    brass = mix(*(at(lowpass(tone(n, 0.5, "saw", 5, 0.5), 2500), s) for n, s in notes))
    return finish(reverb(brass, 0.35), 0.6)


def night_start():
    s = 2.0
    n = int(s * SR)
    drone = mix(osc(freq_of(45), s, "saw") * 0.3, osc(freq_of(52), s, "triangle") * 0.3) * env(n, 0.6, 1.2, 0, 0.2)
    drone = lowpass(drone, 900)
    bell = at(tone(69, 1.2, "sine", 3, 0.4), 0.3)
    return finish(reverb(mix(drone, bell), 0.5), 0.6)


def day_start():
    arp = mix(*(at(tone(n, 0.5, "triangle", 5, 0.45), i * 0.09) for i, n in enumerate((72, 76, 79, 84, 88))))
    return finish(reverb(arp, 0.4), 0.55)


def bonk():
    s = 0.22
    n = int(s * SR)
    boing = osc(sweep(700, 180, s), s, "square") * env(n, 0.001, 0.2, 0, 0.02) * 0.5
    knock = lowpass(noise(0.05), 1500) * env(int(0.05 * SR), 0.0005, 0.04, 0, 0.005)
    return finish(lowpass(mix(boing, knock), 3500), 0.6)


def zap():
    s = 0.12
    n = int(s * SR)
    return finish(osc(sweep(2400, 500, s), s, "square") * env(n, 0.001, 0.1, 0, 0.01), 0.3)


def monster_die():
    s = 0.45
    n = int(s * SR)
    down = osc(sweep(900, 120, s), s, "triangle") * env(n, 0.002, 0.4, 0, 0.04) * 0.6
    poof = lowpass(noise(s), 2500) * env(n, 0.002, 0.25, 0, 0.05) * 0.5
    return finish(reverb(mix(pop_base(0.8), down, poof), 0.25), 0.6)


def shards():
    glass = mix(*(at(tone(n, 0.5, "sine", 6, 0.4), i * 0.05) for i, n in enumerate((96, 103, 100, 108))))
    return finish(reverb(glass, 0.45), 0.5)


def stomp():
    s = 0.9
    n = int(s * SR)
    boom = osc(sweep(90, 35, 0.6), s, "sine") * env(n, 0.002, 0.8, 0, 0.05)
    rumble = lowpass(noise(s), 300) * env(n, 0.002, 0.7, 0, 0.1) * 0.8
    return finish(mix(boom, rumble), 0.8)


def wander_spawn():
    s = 0.6
    n = int(s * SR)
    whistle = osc(sweep(600, 1500, 0.3), s, "sine") * env(n, 0.02, 0.5, 0, 0.05) * 0.5
    return finish(reverb(mix(whistle, at(tone(88, 0.3, "triangle", 8, 0.5), 0.3)), 0.35), 0.55)


# ---------------------------------------------------------------- music

def drum_kick(sr=SR):
    s = 0.25
    return osc(sweep(140, 45, 0.12), s, "sine") * env(int(s * sr), 0.001, 0.22, 0, 0.02)


def drum_hat():
    return highpass(noise(0.05), 7000) * env(int(0.05 * SR), 0.0005, 0.04, 0, 0.005) * 0.3


def drum_snare():
    s = 0.15
    return mix(highpass(noise(s), 1500) * env(int(s * SR), 0.001, 0.12, 0, 0.02) * 0.5, tone(57, s, "triangle", 25, 0.3))


def music(bpm, progression, scale, lead_shape, bass_shape, swing=0.0, drums=True, bars_per_chord=1, lead_density=0.6, seed=1):
    beat = 60 / bpm
    bars = len(progression) * bars_per_chord
    total = bars * 4 * beat
    out = np.zeros(int(total * SR) + SR)
    local = np.random.default_rng(seed)
    for bar in range(bars):
        root = progression[bar // bars_per_chord]
        bar_t = bar * 4 * beat
        # bass: root on beats 1 & 3, fifth on the "and" of 2
        for b, offset in ((0, 0), (2, 0), (1.5, 7)):
            note = root - 24 + offset
            seg = tone(note, beat * 0.9, bass_shape, 6, 0.5)
            s = int((bar_t + b * beat) * SR)
            out[s:s + len(seg)] += seg
        # pad chord (root, third, fifth)
        third = 3 if (root % 12) in (9, 2, 4) and scale == "minor" else 4
        chord = mix(*(osc(freq_of(root + i - 12), 4 * beat, "triangle") for i in (0, third, 7))) * env(int(4 * beat * SR), 0.3, 3, 0.3, 0.4) * 0.12
        s = int(bar_t * SR)
        out[s:s + len(chord)] += chord
        # lead: pentatonic arpeggio over the chord
        penta = [0, 2, 4, 7, 9] if scale == "major" else [0, 3, 5, 7, 10]
        for step in range(8):
            if local.random() < lead_density:
                interval = penta[local.integers(0, len(penta))] + (12 if local.random() < 0.3 else 0)
                note = root + interval
                t = bar_t + step * beat / 2 + (swing * beat / 2 if step % 2 else 0)
                seg = tone(note, beat * 0.45, lead_shape, 12, 0.32)
                s = int(t * SR)
                out[s:s + len(seg)] += seg
        if drums:
            for b in range(4):
                for hit, when in ((drum_kick(), b == 0 or b == 2), (drum_snare(), b == 1 or b == 3)):
                    if when:
                        s = int((bar_t + b * beat) * SR)
                        out[s:s + len(hit)] += hit * 0.55
                for half in (0, 0.5):
                    s = int((bar_t + (b + half) * beat) * SR)
                    h = drum_hat()
                    out[s:s + len(h)] += h
    out = out[: int(total * SR)]
    return finish(reverb(out, 0.2)[: int(total * SR)], 0.6, fade=0.0)


def music_day():
    # sunny, bouncy: I - V - vi - IV in C
    return music(118, [72, 67, 69, 65] * 2, "major", "square", "triangle", swing=0.15, bars_per_chord=2, seed=3)


def music_night():
    # sneaky and spooky-but-cute: i - VI - VII - i in A minor, slower, sparser
    return music(92, [69, 65, 67, 69] * 2, "minor", "triangle", "sine", swing=0.0, bars_per_chord=2, lead_density=0.35, seed=7)


SOUNDS = [
    ui_click, ui_hover, ui_open, ui_close, ui_select, ui_error, notify, purchase, sell,
    plant, pop, pop_rare, collect, cash_small, reveal_tick, reveal_land, reveal_rare,
    mutation_hit, unlock, luck_event, restock, announce, night_start, day_start,
    bonk, zap, monster_die, shards, stomp, wander_spawn,
]

if __name__ == "__main__":
    print("Sound effects:")
    for fn in SOUNDS:
        save(fn.__name__, fn())
    print("Music (22 kHz to keep files small):")
    global_sr = SR
    for fn in (music_day, music_night):
        x = fn()
        save(fn.__name__, x[::2], sr=SR // 2)
    print("Done ->", os.path.abspath(OUT))
