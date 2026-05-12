#!/usr/bin/env bash
set -euo pipefail

target=${1:-}
if [ -z "$target" ]; then
  echo "usage: $0 {m1|hex2|kaem|blood-elf}" >&2
  exit 2
fi

if ! command -v afl-fuzz >/dev/null; then
  echo "afl-fuzz not found; run inside nix develop or install AFL++" >&2
  exit 2
fi

if [ ! -x bin/M1 ] || [ ! -x bin/hex2 ] || [ ! -x bin/blood-elf ] || [ ! -x bin/kaem ]; then
  ./fuzz/build-afl.sh
fi

if [ ! -d fuzz/corpus-m1 ] || [ ! -d fuzz/corpus-hex2 ] || [ ! -d fuzz/corpus-kaem ] || [ ! -d fuzz/corpus-blood-elf ]; then
  ./fuzz/refresh-corpus.sh
fi

: "${DURATION:=600}"
: "${TIMEOUT:=100}"
: "${AFL_FLAGS:=}"
export AFL_SKIP_CPUFREQ="${AFL_SKIP_CPUFREQ:-1}"
export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES="${AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES:-1}"

resume_seed=""
case "$target" in
  m1)
    corpus=${CORPUS:-fuzz/corpus-m1}
    out=${OUTDIR:-fuzz/findings-m1}
    cmd=(bin/M1 --little-endian --architecture x86 -f @@ -o /dev/null)
    ;;
  hex2)
    corpus=${CORPUS:-fuzz/corpus-hex2}
    out=${OUTDIR:-fuzz/findings-hex2}
    cmd=(bin/hex2 --little-endian --architecture x86 --base-address 0x08048000 --non-executable -f @@ -o /dev/null)
    ;;
  kaem)
    corpus=${CORPUS:-fuzz/corpus-kaem}
    out=${OUTDIR:-fuzz/findings-kaem}
    cmd=(bin/kaem --fuzz --non-strict --file @@)
    ;;
  blood-elf)
    corpus=${CORPUS:-fuzz/corpus-blood-elf}
    out=${OUTDIR:-fuzz/findings-blood-elf}
    cmd=(bin/blood-elf --little-endian --entry _start -f @@ -o /dev/null)
    ;;
  *)
    echo "unknown fuzz target: $target" >&2
    exit 2
    ;;
esac

if [ -d "$out/default/queue" ]; then
  resume_seed=$(find "$out/default/queue" -maxdepth 1 -type f -name 'id:*' -print -quit 2>/dev/null || true)
fi
if [ -n "$resume_seed" ]; then
  export AFL_AUTORESUME="${AFL_AUTORESUME:-1}"
fi

mkdir -p "$out"
read -r -a afl_flags <<< "$AFL_FLAGS"
exec afl-fuzz "${afl_flags[@]}" -i "$corpus" -o "$out" -t "$TIMEOUT" -m none -V "$DURATION" -- "${cmd[@]}"
