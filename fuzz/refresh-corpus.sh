#!/usr/bin/env bash
set -euo pipefail

LIVE_BOOTSTRAP=${LIVE_BOOTSTRAP:-../live-bootstrap-fuzz}

rm -rf fuzz/corpus-m1 fuzz/corpus-hex2 fuzz/corpus-kaem fuzz/corpus-blood-elf
mkdir -p fuzz/corpus-m1 fuzz/corpus-hex2 fuzz/corpus-kaem fuzz/corpus-blood-elf

copy_seed() {
  local dst=$1
  local src=$2
  local hash

  [ -f "$src" ] || return 0
  [ -s "$src" ] || return 0
  hash=$(sha256sum "$src" | awk '{print $1}')
  cp "$src" "$dst/$hash"
}

find test M2libc -type f \( -name '*.M1' -o -name '*_defs.M1' \) -print |
  while IFS= read -r file; do copy_seed fuzz/corpus-m1 "$file"; done

find test M2libc elf_headers -type f \( -name '*.hex0' -o -name '*.hex1' -o -name '*.hex2' \) -print |
  while IFS= read -r file; do copy_seed fuzz/corpus-hex2 "$file"; done

find test -type f -name '*.M1' -print |
  while IFS= read -r file; do copy_seed fuzz/corpus-blood-elf "$file"; done

if [ -d "$LIVE_BOOTSTRAP" ]; then
  find "$LIVE_BOOTSTRAP" -type f \( -name '*.hex0' -o -name '*.hex1' -o -name '*.hex2' \) -print |
    while IFS= read -r file; do copy_seed fuzz/corpus-hex2 "$file"; done

  find "$LIVE_BOOTSTRAP" -type f -name '*.kaem' -print |
    while IFS= read -r file; do copy_seed fuzz/corpus-kaem "$file"; done
fi

printf 'DEFINE NOP 90\nNOP\n' > fuzz/corpus-m1/minimal-define
printf ':start\n90\n' > fuzz/corpus-hex2/minimal-label
printf 'echo hello\nset FOO bar\n' > fuzz/corpus-kaem/minimal-builtins
printf ':_start\n:start\n90\n' > fuzz/corpus-blood-elf/minimal-labels

find fuzz/corpus-m1 fuzz/corpus-hex2 fuzz/corpus-kaem fuzz/corpus-blood-elf -maxdepth 1 -type f -printf '%h\n' |
  sort | uniq -c
