#!/bin/bash

bin="/Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex"
[ -x "$bin" ] || { echo "chatgpt.sh: Codex not found at $bin" >&2; exit 1; }
exec "$bin" "$@"
