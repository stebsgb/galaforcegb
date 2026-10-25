"""Record emulator audio for a scripted run and report loudness / dominant pitch per 0.25 s window."""
import sys, numpy as np
from pyboy import PyBoy
rom, frames = sys.argv[1], int(sys.argv[2])
pb = PyBoy(rom, window="null", sound_emulated=True)
chunks = []
for f in range(frames):
    if f == 120: pb.button("start")
    if f > 700 and f % 20 == 0: pb.button("a")
    pb.tick(1, False, True)
    chunks.append(np.array(pb.sound.ndarray, dtype=np.float32).mean(axis=1) if pb.sound.ndarray.ndim > 1 else np.array(pb.sound.ndarray, dtype=np.float32))
sr = pb.sound.sample_rate
a = np.concatenate(chunks); a = a - a.mean()
w = sr // 4
for i in range(0, len(a) - w, w):
    seg = a[i:i + w]
    rms = float(np.sqrt((seg ** 2).mean()))
    sp = np.abs(np.fft.rfft(seg * np.hanning(len(seg))))
    fr = np.argmax(sp[5:]) + 5
    print(f"{i / sr:5.2f}s rms {rms:7.1f} peak {fr * sr / len(seg):7.1f} Hz")
