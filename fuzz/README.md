# mescc-tools fuzzing

This worktree fuzzes the bootstrap-stage input formats directly:

- `m1`: M1 macro assembly (`.M1` and architecture definition files).
- `hex2`: hex0/hex1/hex2-style hex/linker input.
- `blood-elf`: M1 assembly labels used to produce debug footer metadata.
- `kaem`: kaem scripts, using `--fuzz` so parsed commands are not executed.

Start from the Nix shell:

```sh
nix develop
./fuzz/build-afl.sh
./fuzz/refresh-corpus.sh
DURATION=600 ./fuzz/run.sh m1
DURATION=600 ./fuzz/run.sh hex2
DURATION=600 ./fuzz/run.sh blood-elf
DURATION=600 ./fuzz/run.sh kaem
```

The `hex2` target is the one to use for hex0-style assembly material. The
corpus refresh script imports `.hex0`, `.hex1`, and `.hex2` files from
mescc-tools tests and from `../live-bootstrap-fuzz` when that worktree exists.

Useful overrides:

```sh
CORPUS=fuzz/corpus-hex2 OUTDIR=fuzz/findings-hex2 TIMEOUT=50 DURATION=3600 ./fuzz/run.sh hex2
AFL_FLAGS="-z -G 1024" DURATION=3600 ./fuzz/run.sh m1
```
