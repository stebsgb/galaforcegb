RGBASM ?= rgbasm
RGBLINK ?= rgblink
RGBFIX ?= rgbfix
PY ?= .venv/bin/python
OUT = galaforce.gb
VERSION = 1.0.1-SNAPSHOT
VOUT = galaforce-$(VERSION).gb
SRCS = $(wildcard src/*.asm)
GEN = build/data.inc build/gfx.inc build/music.inc

all: $(OUT) $(VOUT)

$(VOUT): $(OUT)
	cp $(OUT) $(VOUT)

build:
	mkdir -p build

build/data.inc: tools/gen_data.py tools/bbc.py | build
	$(PY) tools/gen_data.py
build/gfx.inc: tools/gen_art.py tools/bbc.py tools/font5x7.py | build
	$(PY) tools/gen_art.py
build/music.inc: tools/gen_music.py | build
	$(PY) tools/gen_music.py

build/main.o: $(SRCS) $(GEN) | build
	$(RGBASM) -I src/ -I build/ -o $@ src/main.asm

$(OUT): build/main.o
	$(RGBLINK) -p 0xFF -m build/galaforce.map -n galaforce.sym -o $@ $<
	$(RGBFIX) -v -p 0xFF -t "GALAFORCE" -l 0x00 -m 0x03 -r 2 $@

god: $(SRCS) $(GEN) | build
	$(RGBASM) -DGOD -I src/ -I build/ -o build/god.o src/main.asm
	$(RGBLINK) -p 0xFF -n galaforce_god.sym -o galaforce_god.gb build/god.o
	$(RGBFIX) -v -p 0xFF -t "GALAFORCE" -l 0x00 -m 0x03 -r 2 galaforce_god.gb

# SNAPSHOT REMOVED: The default build now produces a non-snapshot version
# Development snapshot build is still available via 'make snapshot-build' if needed.

snapshot-build: $(SRCS) $(GEN) | build
	$(RGBASM) -I src/ -I build/ -o build/snapshot.o src/main.asm
	$(RGBLINK) -p 0xFF -n galaforce_snapshot.sym -o galaforce-$(VERSION)-SNAPSHOT.gb build/snapshot.o
	$(RGBFIX) -v -p 0xFF -t "GALAFORCE" -l 0x00 -m 0x03 -r 2 galaforce-$(VERSION)-SNAPSHOT.gb

clean:
	rm -rf build galaforce.gb galaforce-*.gb galaforce.sym galaforce_snapshot.sym

boss: $(SRCS) $(GEN) | build
	$(RGBASM) -DBOSSTEST -I src/ -I build/ -o build/boss.o src/main.asm
	$(RGBLINK) -p 0xFF -n galaforce_boss.sym -o galaforce_boss.gb build/boss.o
	$(RGBFIX) -v -p 0xFF -t "GALAFORCE" -l 0x00 -m 0x03 -r 2 galaforce_boss.gb

.PHONY: all clean god boss snapshot-build
