#!/bin/sh
set -eu

ROOT=${STAGE0_ROOT:-/home/siraben/blynn-bootstrap-debug/live-bootstrap-make/seed/stage0-posix}
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
OUT=${OUT:-"$HERE/build"}
SRC="$HERE/linked-list-glob-repro.c"

mkdir -p "$OUT"

"$ROOT/x86/artifact/M2" --architecture x86 \
	-f "$ROOT/M2libc/sys/types.h" \
	-f "$ROOT/M2libc/stddef.h" \
	-f "$ROOT/M2libc/x86/linux/unistd.c" \
	-f "$ROOT/M2libc/x86/linux/fcntl.c" \
	-f "$ROOT/M2libc/fcntl.c" \
	-f "$ROOT/M2libc/ctype.c" \
	-f "$ROOT/M2libc/stdlib.c" \
	-f "$ROOT/M2libc/string.c" \
	-f "$ROOT/M2libc/stdarg.h" \
	-f "$ROOT/M2libc/stdio.h" \
	-f "$ROOT/M2libc/stdio.c" \
	-f "$ROOT/M2libc/bootstrappable.c" \
	-f "$SRC" \
	--debug \
	-o "$OUT/linked-list-glob-repro.M1"

"$ROOT/x86/artifact/blood-elf-0" \
	-f "$OUT/linked-list-glob-repro.M1" \
	--little-endian \
	-o "$OUT/linked-list-glob-repro-footer.M1"

"$ROOT/x86/bin/M1" --architecture x86 \
	--little-endian \
	-f "$ROOT/M2libc/x86/x86_defs.M1" \
	-f "$ROOT/M2libc/x86/libc-full.M1" \
	-f "$OUT/linked-list-glob-repro.M1" \
	-f "$OUT/linked-list-glob-repro-footer.M1" \
	-o "$OUT/linked-list-glob-repro.hex2"

"$ROOT/x86/bin/hex2" --architecture x86 \
	--little-endian \
	--base-address 0x8048000 \
	-f "$ROOT/M2libc/x86/ELF-x86-debug.hex2" \
	-f "$OUT/linked-list-glob-repro.hex2" \
	-o "$OUT/linked-list-glob-repro"

printf '%s\n' "$OUT/linked-list-glob-repro"
