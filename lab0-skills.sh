#!/bin/sh
# Install skills for Claude Code and Codex (symlinks into ~/.claude/skills and ~/.agents/skills),
# and remove the links of skills that no longer exist in the repo.
# Source files = the folder where this script lives (symlinks are resolved).
# Also links the claude.sh and chatgpt.sh launchers:
#   - BIN_DIR=/some/dir ./lab0-skills.sh   uses that directory (warns if it is not in $PATH);
#   - without BIN_DIR, the first directory of BIN_DIR_DEFAULTS that is already in $PATH is used;
#   - if none is in $PATH the launchers are skipped. The script never modifies $PATH.
set -eu

REPO="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
BIN_DIR="${BIN_DIR:-}"
BIN_DIR_DEFAULTS="$HOME/Dropbox/local-m0net/bin-osx
$HOME/.local/bin
$HOME/bin"
set -- "$HOME/.claude/skills" "$HOME/.agents/skills"   # skill dirs

# in_path DIR: succeeds if DIR is an entry of $PATH (trailing slashes ignored; $PATH is never modified)
in_path() {
  _d="${1%/}"
  _ifs="$IFS"; IFS=:
  for _p in $PATH; do
    if [ -n "$_p" ] && [ "${_p%/}" = "$_d" ]; then IFS="$_ifs"; return 0; fi
  done
  IFS="$_ifs"
  return 1
}

# pick_bin_dir: prints the first directory of BIN_DIR_DEFAULTS that is in $PATH
pick_bin_dir() {
  _ifs="$IFS"; IFS='
'
  for _c in $BIN_DIR_DEFAULTS; do
    if in_path "$_c"; then IFS="$_ifs"; printf '%s\n' "$_c"; return 0; fi
  done
  IFS="$_ifs"
  return 1
}

# link SRC DST: symlink, but never nest inside or clobber a real directory/file
link() {
  if [ -e "$2" ] && [ ! -L "$2" ]; then
    echo "✗ skip   $2 exists and is not a symlink" >&2
    return 1
  fi
  ln -sfn "$1" "$2"
}

# --- skills -------------------------------------------------------------
# Skills may live in group folders (skills/<group>/<skill>/SKILL.md); the link is named after the
# skill folder, which must equal the `name:` of its frontmatter.
mkdir -p "$@"
dups="$(find "$REPO" -name SKILL.md -not -path '*/.git/*' | while IFS= read -r f; do basename "$(dirname "$f")"; done | sort | uniq -d)"
if [ -n "$dups" ]; then
  echo "✗ duplicate skill folder names: $dups" >&2
  exit 1
fi
find "$REPO" -name SKILL.md -not -path '*/.git/*' | while IFS= read -r f; do
  dir="$(dirname "$f")"; name="$(basename "$dir")"
  fm="$(awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} /^name: /{sub(/^name: */,""); print; exit}' "$f")"
  if [ "$fm" != "$name" ]; then
    echo "✗ skip   $name: frontmatter name is '$fm'" >&2
    continue
  fi
  for t in "$@"; do
    link "$dir" "$t/$name" || true
  done
  echo "✓ skill  $name"
done

# prune: remove symlinks of skills deleted from the repo (dangling, or pointing
# into the repo at a folder that no longer has a SKILL.md)
for t in "$@"; do
  for l in "$t"/*; do
    [ -L "$l" ] || continue
    dest="$(readlink "$l")"
    stale=0
    [ -e "$l" ] || stale=1
    case "$dest" in
      "$REPO"/*) [ -f "$dest/SKILL.md" ] || stale=1 ;;
    esac
    if [ "$stale" = 1 ]; then
      rm "$l"
      echo "✗ removed $l (skill no longer in repo)"
    fi
  done
done

# --- launchers -----------------------------------------------------------
if [ -n "$BIN_DIR" ]; then
  in_path "$BIN_DIR" || echo "! $BIN_DIR is not in \$PATH (left unchanged); add it yourself to run the launchers by name" >&2
else
  BIN_DIR="$(pick_bin_dir)" || BIN_DIR=""
  if [ -z "$BIN_DIR" ]; then
    echo "· launchers skipped: no directory of BIN_DIR_DEFAULTS is in \$PATH (use BIN_DIR=/some/dir to choose one)"
    exit 0
  fi
  echo "· launchers: using $BIN_DIR (first default found in \$PATH)"
fi
mkdir -p "$BIN_DIR"
for f in claude.sh chatgpt.sh; do
  src="$REPO/$f"; dst="$BIN_DIR/$f"
  [ -f "$src" ] || { echo "✗ missing $src" >&2; continue; }
  chmod +x "$src"
  if link "$src" "$dst"; then
    echo "✓ bin    $dst -> $src"
  fi
done
