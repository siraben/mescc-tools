# tiny-make linked-list glob repro

This isolates the crash seen in an M2-built `tiny-make` when glob expansion
used a linked-list accumulator for `struct Word`.

Build with the same stage0 path used for kaem:

```
./repro/tiny-make-linked-list/build-stage0.sh
```

Run the crashing path:

```
tmp=$(mktemp -d)
: > "$tmp/entry"
./repro/tiny-make-linked-list/build/linked-list-glob-repro "$tmp"
```

Run the corrected path in the same M2-built binary:

```
./repro/tiny-make-linked-list/build/linked-list-glob-repro "$tmp" good
```

Or run the full build-and-check sequence:

```
./repro/tiny-make-linked-list/run-stage0.sh
```

The bad path crashes after `getdents` returns a real directory entry because it
stores through `(*tail)->next` while `*tail` is still `NULL`. The good path uses
the same `getdents` layout and `struct Word` layout, but initializes the empty
list before linking through the tail pointer.
