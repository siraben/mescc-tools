#!/usr/bin/env bash
set -euo pipefail

LIVE_BOOTSTRAP=${LIVE_BOOTSTRAP:-../live-bootstrap}
CC_X86_S=${CC_X86_S:-$LIVE_BOOTSTRAP/seed/stage0-posix/x86/GAS/cc_x86.S}

if [ ! -f "$CC_X86_S" ]; then
  echo "cc_x86 GAS source not found: $CC_X86_S" >&2
  echo "set LIVE_BOOTSTRAP or CC_X86_S to the stage0-posix tree" >&2
  exit 2
fi

mkdir -p fuzz/cc_x86/bin fuzz/cc_x86/build
as --32 "$CC_X86_S" -o fuzz/cc_x86/build/cc_x86.o
ld -melf_i386 fuzz/cc_x86/build/cc_x86.o -o fuzz/cc_x86/bin/cc_x86
