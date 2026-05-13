#!/usr/bin/env bash
set -euo pipefail

target=${1:-}
if [ -z "$target" ]; then
  echo "usage: $0 {m1|hex2|kaem|blood-elf|cc_x86}" >&2
  exit 2
fi

if ! command -v afl-fuzz >/dev/null; then
  echo "afl-fuzz not found; run inside nix develop or install AFL++" >&2
  exit 2
fi

if [ "$target" != "cc_x86" ] && { [ ! -x bin/M1 ] || [ ! -x bin/hex2 ] || [ ! -x bin/blood-elf ] || [ ! -x bin/kaem ]; }; then
  ./fuzz/build-afl.sh
fi

if [ "$target" = "cc_x86" ] && [ ! -x fuzz/cc_x86/bin/cc_x86 ]; then
  ./fuzz/build-cc-x86.sh
fi

if [ ! -d fuzz/corpus-m1 ] || [ ! -d fuzz/corpus-hex2 ] || [ ! -d fuzz/corpus-kaem ] || [ ! -d fuzz/corpus-blood-elf ] || [ ! -d fuzz/corpus-cc-x86 ]; then
  ./fuzz/refresh-corpus.sh
fi

: "${DURATION:=600}"
: "${AFL_FLAGS:=}"
export AFL_SKIP_CPUFREQ="${AFL_SKIP_CPUFREQ:-1}"
export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES="${AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES:-1}"
: "${CC_X86_AFL_MODE:=-n}"

resume_seed=""
default_timeout=100
case "$target" in
  m1)
    corpus=${CORPUS:-fuzz/corpus-m1}
    out=${OUTDIR:-fuzz/findings-m1}
    default_timeout=250
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
  cc_x86)
    corpus=${CORPUS:-fuzz/corpus-cc-x86}
    out=${OUTDIR:-fuzz/findings-cc-x86}
    default_timeout=250
    cmd=(fuzz/cc_x86/bin/cc_x86 @@ /dev/null)
    ;;
  *)
    echo "unknown fuzz target: $target" >&2
    exit 2
    ;;
esac

: "${TIMEOUT:=$default_timeout}"

if [ -d "$out/default/queue" ]; then
  resume_seed=$(find "$out/default/queue" -maxdepth 1 -type f -name 'id:*' -print -quit 2>/dev/null || true)
fi
if [ -n "$resume_seed" ]; then
  export AFL_AUTORESUME="${AFL_AUTORESUME:-1}"
fi

mkdir -p "$out"
read -r -a afl_flags <<< "$AFL_FLAGS"
if [ "$target" = "cc_x86" ] && [ -n "$CC_X86_AFL_MODE" ]; then
  read -r -a cc_x86_afl_mode <<< "$CC_X86_AFL_MODE"
  afl_flags=("${cc_x86_afl_mode[@]}" "${afl_flags[@]}")
fi
exec afl-fuzz "${afl_flags[@]}" -i "$corpus" -o "$out" -t "$TIMEOUT" -m none -V "$DURATION" -- "${cmd[@]}"
