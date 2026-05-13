#!/bin/sh
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN=$("$HERE/build-stage0.sh")
TMPDIR=$(mktemp -d)

: > "$TMPDIR/entry"

set +e
"$BIN" "$TMPDIR"
BAD_STATUS=$?
set -e

printf 'bad_status=%s\n' "$BAD_STATUS"
if [ 139 != "$BAD_STATUS" ]
then
	printf 'expected bad path to exit 139\n' >&2
	exit 1
fi

"$BIN" "$TMPDIR" good
