#!/usr/bin/env bash
set -euo pipefail

FUZZ_CC=${FUZZ_CC:-afl-clang-fast}
FUZZ_CFLAGS=${FUZZ_CFLAGS:--D_GNU_SOURCE -std=c99 -O2 -g -fno-common}

rm -rf bin
make -j"$(nproc)" CC="$FUZZ_CC" CFLAGS="$FUZZ_CFLAGS" all
