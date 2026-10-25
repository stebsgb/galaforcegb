"""Measure each SFX and each tune in isolation: RMS, peak and length (emulated audio)."""
import sys, numpy as np, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import make, load_syms
rom = sys.argv[1] if len(sys.argv) > 1 else "galaforce.gb"
S = load_syms(rom)

def rec(pb, frames):
    out = []
    for _ in range(frames):
        pb.tick(1, False, True)
        a = np.array(pb.sound.ndarray, dtype=np.float32)
        out.append(a.mean(axis=1) if a.ndim > 1 else a)
    return np.concatenate(out)

def stats(a, base):
    a = a - base
    return float(np.sqrt((a ** 2).mean())), float(np.abs(a).max())

def fresh(silence=True):
    pb = make(rom, sound=True)
    for _ in range(5): pb.tick(1, False, True)
    pb.memory[S["aPlay"]] = 0
    for _ in range(200): pb.tick(1, False, True)
    return pb

pb = fresh()
base = float(rec(pb, 10).mean())
print('silence rms', float(np.sqrt(((rec(pb, 10) - base) ** 2).mean())))
for n in ("FIRE", "BOOM", "PDEATH", "ONEUP", "HIT", "LAST"):
    pb = fresh()
    ad = S["Sfx_" + n]
    pb.memory[S["aSfxPtr"]] = ad & 255; pb.memory[S["aSfxPtr"] + 1] = ad >> 8
    pb.memory[S["aSfxCt"]] = 0; pb.memory[S["aSfxOn"]] = 1
    a = rec(pb, 120)
    n_on = 120
    # active length: frames until aSfxOn clears is not recorded; estimate by energy
    sr = pb.sound.sample_rate
    env = np.abs(a - base)
    idx = np.where(env > 3)[0]
    ln = (idx[-1] / sr) if len(idx) else 0
    r, p = stats(a[: int(ln * sr) + 1], base)
    print(f"SFX {n:7s} rms {r:6.1f} peak {p:6.1f} len {ln:4.2f}s")
for t, name in enumerate(["START", "BETW", "LOST", "OVER", "ZONE", "DEMO"]):
    pb = fresh()
    # restart tune t via the table: copy 14 bytes and arm the counters
    tt = S["TuneTable"] + 16 * t
    for i in range(14): pb.memory[S["aPtr"] + i] = pb.memory[tt + i]
    for i in range(3): pb.memory[S["aCnt"] + i] = 1
    pb.memory[S["aPlay"]] = 1
    a = rec(pb, 60 * 20)
    sr = pb.sound.sample_rate
    idx = np.where(np.abs(a - base) > 3)[0]
    ln = idx[-1] / sr if len(idx) else 0
    r, p = stats(a[: int(ln * sr) + 1], base)
    print(f"TUNE {name:6s} rms {r:6.1f} peak {p:6.1f} len {ln:5.2f}s")

if len(sys.argv) > 2:
    for n in sys.argv[2:]:
        pb = fresh(); sr = pb.sound.sample_rate
        ad = S["Sfx_" + n]
        pb.memory[S["aSfxPtr"]] = ad & 255; pb.memory[S["aSfxPtr"] + 1] = ad >> 8
        pb.memory[S["aSfxCt"]] = 0; pb.memory[S["aSfxOn"]] = 1
        a = rec(pb, 60); a = a - a.mean(); spf = len(a) // 60; w = spf * 3; sr = spf * 59.7
        res = []
        for i in range(0, 54 * spf, w):
            seg = a[i:i + w]
            res.append((round(float(np.sqrt((seg ** 2).mean()))), int((np.argmax(np.abs(np.fft.rfft(seg * np.hanning(len(seg))))[2:]) + 2) * sr / len(seg))))
        print(n, res)
