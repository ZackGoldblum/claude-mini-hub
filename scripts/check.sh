#!/bin/bash
# check.sh: read-only status check. Run it on the LAPTOP. It changes nothing.
# Prints one line per requirement: "ok" or "TODO", then a count.
# Usage: bash scripts/check.sh

MINI_PATH='export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"'
todo=0
ok()   { printf "  ok    %s\n" "$1"; }
miss() { printf "  TODO  %s\n        -> %s\n" "$1" "$2"; todo=$((todo + 1)); }

find_tailscale() {
  if command -v tailscale >/dev/null 2>&1; then echo tailscale; return; fi
  for p in /Applications/Tailscale.app/Contents/MacOS/Tailscale; do
    [ -x "$p" ] && { echo "$p"; return; }
  done
}

echo
echo "This laptop"
TS="$(find_tailscale)"
if [ -z "$TS" ]; then
  miss "Tailscale is installed" "playbook step 1"
elif ! "$TS" status >/dev/null 2>&1; then
  miss "Tailscale is signed in and connected" "open Tailscale from the menu bar and sign in (step 1)"
else
  ok "Tailscale is connected"
  others="$("$TS" status 2>/dev/null | awk 'NR>1 && $1 ~ /^100\./ {print $2 " (" $1 ")"}' | tr '\n' ' ')"
  if [ -n "$others" ]; then ok "Other devices on your network: $others"
  else miss "The Mini appears on your Tailscale network" "install Tailscale on the Mini with the same account (step 1)"; fi
fi

if [ -f "$HOME/.ssh/id_mini" ]; then ok "SSH key exists (~/.ssh/id_mini)"
else miss "SSH key exists (~/.ssh/id_mini)" "step 3"; fi

if grep -qE '^Host[[:space:]]+mini([[:space:]]|$)' "$HOME/.ssh/config" 2>/dev/null; then
  ok "SSH shortcut 'mini' is defined (~/.ssh/config)"
  have_alias=1
else
  miss "SSH shortcut 'mini' is defined (~/.ssh/config)" "step 3"
  have_alias=0
fi

if [ -f "$HOME/.claude/skills/mini/SKILL.md" ]; then ok "Claude skill 'mini' is installed"
else miss "Claude skill 'mini' is installed" "step 6"; fi

if grep -q "mini-hub:start" "$HOME/.claude/CLAUDE.md" 2>/dev/null; then ok "Claude's standing notes mention the Mini (~/.claude/CLAUDE.md)"
else miss "Claude's standing notes mention the Mini (~/.claude/CLAUDE.md)" "step 6"; fi

echo
echo "The Mini"
if [ "$have_alias" -ne 1 ]; then
  miss "Laptop can reach the Mini" "finish the laptop steps first"
elif ! ssh -T -o BatchMode=yes -o ConnectTimeout=8 mini true 2>/dev/null; then
  miss "Laptop can log in to the Mini without a password" "step 3 (ssh-copy-id), and check Remote Login is on (step 2)"
else
  ok "Laptop can log in to the Mini without a password"
  report="$(ssh -T -o BatchMode=yes -o ConnectTimeout=8 mini "$MINI_PATH"'
    echo "host=$(scutil --get ComputerName 2>/dev/null)"
    command -v claude >/dev/null && echo claude=1 || echo claude=0
    if command -v claude >/dev/null && claude auth status >/dev/null 2>&1; then echo login=1; else echo login=0; fi
    command -v tmux >/dev/null && echo tmux=1 || echo tmux=0
    [ -x "$HOME/.local/bin/dev" ] && [ -x "$HOME/.local/bin/start-task" ] && echo tools=1 || echo tools=0
    ls "$HOME/Desktop" >/dev/null 2>&1 && echo desk=1 || echo desk=0
    [ -d "$HOME/Desktop/Claude Code Projects" ] && echo devdir=1 || echo devdir=0
    echo "sleep=$(pmset -g 2>/dev/null | awk "\$1==\"sleep\" {print \$2}")"
    grep -q "mini-hub:start" "$HOME/.claude/CLAUDE.md" 2>/dev/null && echo notes=1 || echo notes=0
  ' 2>/dev/null)"
  get() { echo "$report" | awk -F= -v k="$1" '$1==k {print $2}'; }
  ok "Connected to: $(get host)"
  [ "$(get claude)" = 1 ] && ok "Claude Code is installed" || miss "Claude Code is installed" "step 4"
  [ "$(get login)" = 1 ]  && ok "Claude Code is signed in (works over SSH)" || miss "Claude Code is signed in (works over SSH)" "step 5"
  [ "$(get tmux)" = 1 ]   && ok "tmux is installed" || miss "tmux is installed" "step 4 (Homebrew, then tmux)"
  [ "$(get tools)" = 1 ]  && ok "Helper commands 'dev' and 'start-task' are installed" || miss "Helper commands 'dev' and 'start-task' are installed" "step 4"
  [ "$(get desk)" = 1 ]   && ok "Remote sessions can use the Mini's Desktop" || miss "Remote sessions can use the Mini's Desktop" "Remote Login > (i) > Allow full disk access for remote users (step 2)"
  [ "$(get devdir)" = 1 ] && ok "Projects folder 'Claude Code Projects' exists on the Mini's Desktop" || miss "Projects folder 'Claude Code Projects' exists on the Mini's Desktop" "step 4"
  [ "$(get sleep)" = 0 ]  && ok "The Mini never sleeps" || miss "The Mini never sleeps" "System Settings > Energy on the Mini (step 2)"
  [ "$(get notes)" = 1 ]  && ok "The Mini's Claude has its standing notes" || miss "The Mini's Claude has its standing notes" "step 6"
fi

echo
if [ "$todo" -eq 0 ]; then echo "All set. Nothing left to do."
else echo "$todo item(s) left."; fi
exit "$todo"
