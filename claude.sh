#!/bin/bash

base="$HOME/Library/Application Support/Claude/claude-code"
ver=$(ls "$base" | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)
bin=$(find "$base/$ver" -path '*/MacOS/claude' -type f | head -1)
[ -x "$bin" ] || { echo "claude.sh: Claude Code not found in $base" >&2; exit 1; }
exec "$bin" "$@"
 