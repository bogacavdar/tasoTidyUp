"""Taso Dükkânı arka plan müziği: sakin, döngüye giren lo-fi dükkân parçası.

Tamamen kodla sentezlenir (FM elektrik piyano, bas, marimba ezgisi, fırça davul,
hafif plak cızırtısı, basit yankı). Çıktı: assets/audio/muzik.ogg (ffmpeg + libvorbis).
Kullanım: python3 tools/gen_music.py
"""
import os
import subprocess
import wave

import numpy as np
from scipy.signal import fftconvolve, butter, sosfilt

SR = 32000
BPM = 76
BEAT = 60.0 / BPM
BAR = BEAT * 4
CYCLES = 4
# D majör, akorlar 2'şer ölçü: Dmaj7 - Bm7 - Gmaj7 - A6sus
CHORDS = [
    [50, 54, 57, 61, 64],  # Dmaj9 (D F# A C# E)
    [47, 50, 54, 57, 61],  # Bm9
    [43, 47, 50, 54, 57],  # Gmaj7(9)
    [45, 49, 52, 54, 59],  # A6/9
]
ROOTS = [38, 35, 31, 33]
PENTA = [62, 64, 66, 69, 71, 74, 76, 78, 81]

LENGTH = BAR * 2 * len(CHORDS) * CYCLES
N = int(LENGTH * SR)
TAIL = int(4.0 * SR)
rng = np.random.default_rng(7)


def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


def add(buf, start_s, sig, pan=0.0):
    i = int(start_s * SR)
    j = min(i + len(sig), buf.shape[0])
    if i >= buf.shape[0]:
        return
    l = np.sqrt(0.5 * (1 - pan))
    r = np.sqrt(0.5 * (1 + pan))
    buf[i:j, 0] += sig[: j - i] * l
    buf[i:j, 1] += sig[: j - i] * r


def ep_note(m, dur, vel):
    """FM elektrik piyano (Rhodes benzeri)."""
    t = np.arange(int((dur + 1.5) * SR)) / SR
    f = hz(m)
    idx = 1.6 * np.exp(-t * 3.0) * vel
    mod = np.sin(2 * np.pi * f * t) * idx
    car = np.sin(2 * np.pi * f * t + mod)
    tine = 0.15 * np.sin(2 * np.pi * f * 7.0 * t) * np.exp(-t * 18)
    env = np.minimum(1, t * 200) * np.exp(-t * 1.1)
    rel = np.clip((dur + 1.5 - t) / 1.5, 0, 1)
    trem = 1 + 0.08 * np.sin(2 * np.pi * 4.5 * t)
    return (car + tine) * env * rel * trem * vel


def bass_note(m, dur, vel):
    t = np.arange(int((dur + 0.3) * SR)) / SR
    f = hz(m)
    s = np.sin(2 * np.pi * f * t) + 0.25 * np.sin(4 * np.pi * f * t) + 0.08 * np.sin(6 * np.pi * f * t)
    env = np.minimum(1, t * 120) * np.exp(-t * 1.6) * np.clip((dur + 0.3 - t) / 0.3, 0, 1)
    return s * env * vel


def marimba(m, vel):
    t = np.arange(int(1.6 * SR)) / SR
    f = hz(m)
    s = np.sin(2 * np.pi * f * t) * np.exp(-t * 4.5) + 0.35 * np.sin(2 * np.pi * f * 4.0 * t) * np.exp(-t * 16)
    return s * np.minimum(1, t * 400) * vel


def noise_hit(dur, decay, lo, hi, vel):
    n = rng.standard_normal(int(dur * SR))
    sos = butter(2, [lo, hi], btype="band", fs=SR, output="sos")
    n = sosfilt(sos, n)
    t = np.arange(len(n)) / SR
    return n * np.exp(-t * decay) * vel


def kick(vel):
    t = np.arange(int(0.35 * SR)) / SR
    f = 55 + 60 * np.exp(-t * 30)
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * np.exp(-t * 9) * vel


def main():
    buf = np.zeros((N + TAIL, 2))
    # sabit ezgi motifleri: her döngüde biraz değişir
    motifs = []
    for k in range(4):
        steps = sorted(rng.choice(np.arange(16), size=rng.integers(3, 6), replace=False))
        notes = [int(rng.integers(0, len(PENTA))) for _ in steps]
        motifs.append(list(zip(steps, notes)))

    for cyc in range(CYCLES):
        for ci, chord in enumerate(CHORDS):
            bar0 = (cyc * len(CHORDS) + ci) * 2 * BAR
            for b in range(2):
                t0 = bar0 + b * BAR
                # EP: 1. vuruş ve 3. vuruşun arkası (hafif swing)
                for beat_off, vel in [(0.0, 0.32), (2.55, 0.2)]:
                    for k, m in enumerate(chord):
                        add(buf, t0 + beat_off * BEAT + k * 0.012, ep_note(m, BEAT * 1.6, vel * (0.85 if k else 1.0)), pan=(k - 2) * 0.18)
                # bas
                root = ROOTS[ci]
                add(buf, t0, bass_note(root, BEAT * 1.8, 0.55))
                add(buf, t0 + 2.5 * BEAT, bass_note(root + (7 if b else 12), BEAT * 1.2, 0.4))
                # davul: 2. döngüden itibaren
                if cyc >= 1:
                    add(buf, t0, kick(0.35))
                    add(buf, t0 + 2.5 * BEAT, kick(0.22))
                    for e in range(8):
                        sw = 0.08 if e % 2 else 0.0
                        v = 0.05 if e % 2 else 0.035
                        add(buf, t0 + (e * 0.5 + sw) * BEAT, noise_hit(0.12, 40, 5000, 11000, v), pan=0.3)
                    add(buf, t0 + 1 * BEAT, noise_hit(0.25, 14, 900, 5000, 0.1), pan=-0.1)
                    add(buf, t0 + 3 * BEAT, noise_hit(0.25, 14, 900, 5000, 0.1), pan=-0.1)
                # ezgi: 2. ve 4. döngüde, her ölçüde değil
                if cyc in (1, 3) and (b == 0 or ci % 2 == 1):
                    mot = motifs[(ci + cyc) % 4]
                    for step, ni in mot:
                        m = PENTA[(ni + (cyc // 2)) % len(PENTA)]
                        add(buf, t0 + step * 0.25 * BEAT, marimba(m, 0.22), pan=0.35 * np.sin(step))

    # yankı (stereo, iki farklı sönümlü gürültü IR)
    ir_len = int(2.2 * SR)
    t = np.arange(ir_len) / SR
    wet = np.zeros_like(buf)
    for ch in range(2):
        ir = rng.standard_normal(ir_len) * np.exp(-t * 2.8)
        ir[: int(0.015 * SR)] = 0
        ir /= np.sqrt(np.sum(ir ** 2))
        wet[:, ch] = fftconvolve(buf[:, ch], ir)[: buf.shape[0]]
    mix = buf + 0.32 * wet

    # sonsuz döngü: taşan kuyruğu başa ekle
    out = mix[:N].copy()
    out[:TAIL] += mix[N:N + TAIL]

    # yumuşak alçak geçiren ve plak cızırtısı
    sos = butter(2, 7000, btype="low", fs=SR, output="sos")
    out = sosfilt(sos, out, axis=0)
    crackle = np.zeros(N)
    pos = rng.integers(0, N, size=int(LENGTH * 6))
    crackle[pos] = rng.standard_normal(len(pos)) * 0.04
    hiss = sosfilt(butter(2, [2000, 8000], btype="band", fs=SR, output="sos"), rng.standard_normal(N)) * 0.004
    out[:, 0] += crackle + hiss
    out[:, 1] += np.roll(crackle, 37) + hiss

    out = np.tanh(out / np.max(np.abs(out)) * 1.2) * 0.75
    pcm = (out * 32767).astype(np.int16)
    os.makedirs("assets/audio", exist_ok=True)
    tmp = "/tmp/muzik.wav"
    with wave.open(tmp, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", "3", "assets/audio/muzik.ogg"], check=True)
    print("assets/audio/muzik.ogg", round(LENGTH, 1), "sn")


if __name__ == "__main__":
    main()
