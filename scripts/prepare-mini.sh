#!/bin/bash
# prepare-mini.sh: run on the LAPTOP once "ssh mini" works without a password.
# Sets up the Mini over SSH. Needs no administrator password. Safe to run twice.
# Usage: bash scripts/prepare-mini.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SSH="ssh -T -o BatchMode=yes -o ConnectTimeout=10 mini"

echo "1/3  Folders, PATH, and Claude Code on the Mini"
$SSH 'bash -s' <<'REMOTE'
set -e
mkdir -p "$HOME/ClaudeCodeProjects" "$HOME/.local/bin"

# Commands sent over SSH do not read ~/.zshrc, so they would not find
# claude, tmux or brew. ~/.zshenv is read every time, so the PATH goes there.
if ! grep -q "mini-hub PATH" "$HOME/.zshenv" 2>/dev/null; then
  cat >> "$HOME/.zshenv" <<'EOF'

# mini-hub PATH: make claude, tmux and brew visible to commands sent over SSH
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
case ":$PATH:" in *":/opt/homebrew/bin:"*) ;; *) export PATH="/opt/homebrew/bin:$PATH" ;; esac
EOF
  echo "     added PATH lines to ~/.zshenv"
fi

export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
if command -v claude >/dev/null; then
  echo "     Claude Code already installed: $(claude --version)"
else
  echo "     installing Claude Code (Anthropic's installer)..."
  curl -fsSL https://claude.ai/install.sh | bash >/dev/null
  echo "     installed: $("$HOME/.local/bin/claude" --version)"
fi
REMOTE

echo "2/3  Helper commands and tmux settings"
scp -q "$HERE/files/dev" "$HERE/files/start-task" mini:.local/bin/
$SSH 'chmod +x ~/.local/bin/dev ~/.local/bin/start-task'
if $SSH 'test -f ~/.tmux.conf'; then
  echo "     ~/.tmux.conf already exists on the Mini (left as is)"
else
  scp -q "$HERE/files/tmux.conf" mini:.tmux.conf
  echo "     copied tmux settings"
fi
echo "     copied: dev, start-task"

echo "3/3  tmux"
if $SSH 'export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"; command -v tmux >/dev/null'; then
  echo "     tmux is installed"
elif $SSH 'export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"; command -v brew >/dev/null'; then
  echo "     Homebrew found; installing tmux..."
  $SSH 'export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"; brew install tmux >/dev/null 2>&1'
  echo "     tmux installed"
else
  echo "     tmux is missing and so is Homebrew (the installer for tools like tmux)."
  echo "     Homebrew needs the Mini's password, so YOU run this in a second Terminal window:"
  echo
  echo '         ssh mini'
  echo '         /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  echo
  echo "     It takes 5 to 15 minutes. Then run this script again."
fi
