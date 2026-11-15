#!/bin/bash
# install-notes.sh: run on the LAPTOP. Teaches Claude about the Mini on both machines.
#   Laptop: the "mini" skill + a short section in ~/.claude/CLAUDE.md
#   Mini:   a short section in its own ~/.claude/CLAUDE.md
# Safe to run twice: sections are marked and replaced only if missing.
# Usage: bash scripts/install-notes.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$HOME/.claude/skills/mini"
cp "$HERE/files/skill/mini/SKILL.md" "$HOME/.claude/skills/mini/SKILL.md"
echo "Laptop: installed skill at ~/.claude/skills/mini/SKILL.md"

if grep -q "mini-hub:start" "$HOME/.claude/CLAUDE.md" 2>/dev/null; then
  echo "Laptop: ~/.claude/CLAUDE.md already has the Mini section (left as is)"
else
  { [ -s "$HOME/.claude/CLAUDE.md" ] && echo; cat "$HERE/files/claude-md-laptop.md"; } >> "$HOME/.claude/CLAUDE.md"
  echo "Laptop: added the Mini section to ~/.claude/CLAUDE.md"
fi

ssh -T -o BatchMode=yes -o ConnectTimeout=10 mini '
  mkdir -p "$HOME/.claude"
  if grep -q "mini-hub:start" "$HOME/.claude/CLAUDE.md" 2>/dev/null; then
    echo "Mini: ~/.claude/CLAUDE.md already has its section (left as is)"
  else
    { [ -s "$HOME/.claude/CLAUDE.md" ] && echo; cat; } >> "$HOME/.claude/CLAUDE.md"
    echo "Mini: added the standing notes to ~/.claude/CLAUDE.md"
  fi
' < "$HERE/files/claude-md-mini.md"
